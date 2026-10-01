import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/credit_note_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class CreditNoteRepositoryImpl extends BaseIsarRepository<CreditNote> implements CreditNoteRepository {
  CreditNoteRepositoryImpl(Isar isar) : super(isar, 'CreditNote');

  @override
  IsarCollection<CreditNote> get collection => isar.collection<CreditNote>();

  @override
  Future<String> generateNextCreditNoteNumber() async {
    try {
      final allItems = await collection.filter().isDeletedEqualTo(false).findAll();
      int maxNum = 0;
      for (var item in allItems) {
        if (item.creditNoteNumber != null ) {
          final matches = RegExp(r'\d+').allMatches(item.creditNoteNumber!);
          if (matches.isNotEmpty) {
            final parsed = int.tryParse(matches.last.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final suffix = (maxNum + 1).toString().padLeft(2, '0');
      return 'CN-$suffix';
    } catch (e) {
      throw DatabaseException('Failed to generate credit note number: $e');
    }
  }

  @override
  Future<void> saveCreditNote(CreditNote note, List<CreditNoteItem> items) async {
    try {
      final isNew = note.id == Isar.autoIncrement;
      note.uuid ??= _generateUuid();
      note.createdAt = isNew ? DateTime.now() : note.createdAt;
      note.updatedAt = DateTime.now();
      note.isDeleted = false;
      note.isSynced = false;
      note.version = isNew ? 1 : note.version + 1;

      await isar.writeTxn(() async {
        CreditNote? oldNote;
        if (!isNew) {
          oldNote = await collection.get(note.id);
        }

        // 1. Put Credit Note
        final noteId = await collection.put(note);
        note.id = noteId;

        // 2. Adjust Party Outstanding Balance (reduces what the customer owes us)
        final oldPartyId = oldNote?.partyId;
        final oldParty = kIsWeb
            ? (oldPartyId != null ? await isar.collection<Party>().get(oldPartyId) : null)
            : oldNote?.party.value;
            
        final newParty = kIsWeb
            ? (note.partyId != null ? await isar.collection<Party>().get(note.partyId!) : null)
            : note.party.value;

        if (oldParty != null && !isNew) {
          final oldAmt = oldNote?.grandTotal ?? 0.0;
          oldParty.outstandingBalance = (oldParty.outstandingBalance ?? 0.0) + oldAmt; // revert
          await isar.collection<Party>().put(oldParty);
        }

        if (newParty != null) {
          final amt = note.grandTotal ?? 0.0;
          newParty.outstandingBalance = (newParty.outstandingBalance ?? 0.0) - amt;
          await isar.collection<Party>().put(newParty);
        }

        // 3. Put Items & Restore Inventory Levels (returned items increase stock)
        for (var item in items) {
          item.uuid ??= _generateUuid();
          item.createdAt = isNew ? DateTime.now() : item.createdAt;
          item.updatedAt = DateTime.now();
          item.isDeleted = false;
          item.isSynced = false;
          item.version = isNew ? 1 : item.version + 1;
          item.parentCreditNoteId = note.id;

          if (!kIsWeb) {
            item.creditNote.value = note;
          }
          await isar.creditNoteItems.put(item);

          // Restore stock (Sales Return = items come back in stock)
          final dbItem = kIsWeb
              ? (item.itemId != null ? await isar.items.get(item.itemId!) : null)
              : item.item.value;
          if (dbItem != null) {
            final double available = dbItem.currentStock ?? 0.0;
            final double returned = item.quantity ?? 0.0;
            dbItem.currentStock = available + returned;

            // Log stock movement
            final log = '[\${DateTime.now().toIso8601String().substring(0, 19)}] RETURNED IN: +\$returned | Bal: \${dbItem.currentStock} | Credit Note #\${note.creditNoteNumber}';
            dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '\$log\n\${dbItem.notes}';
            await isar.items.put(dbItem);
          }
        }

        // 4. Save a summary transaction log so it shows up in global transaction registries and ledger reports
        Transaction? txn;
        if (!isNew) {
          txn = await isar.transactions.filter().linkedBillUuidEqualTo(note.uuid).findFirst();
        }
        
        if (txn == null) {
          txn = Transaction()
            ..uuid = _generateUuid()
            ..transactionType = 'Credit Note'
            ..createdAt = DateTime.now()
            ..version = 1;
        } else {
          txn.version = (txn.version ?? 1) + 1;
        }

        txn.transactionNumber = note.creditNoteNumber;
        txn.transactionDate = note.creditNoteDate ?? DateTime.now();
        txn.partyUuid = newParty?.uuid ?? note.partyUuid;
        txn.partyName = note.partyName;
        txn.amount = note.grandTotal;
        txn.paymentMode = 'Credit';
        txn.remarks = 'Sales Return: Credit Note #\${note.creditNoteNumber}. \${note.remarks ?? ""}';
        txn.linkedBillUuid = note.uuid;
        txn.updatedAt = DateTime.now();
        txn.isDeleted = false;
        txn.isSynced = false;
        
        if (newParty != null && !kIsWeb) {
          txn.party.value = newParty;
        }
        final txnId = await isar.transactions.put(txn);

        // Sync log for Transaction
        final txnQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Transaction'
          ..entityId = txnId
          ..entityUuid = txn.uuid
          ..operation = txn.id == Isar.autoIncrement ? 'Insert' : 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(txnQueue);

        // 5. Sync queue logs for CreditNote
        final cnQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'CreditNote'
          ..entityId = noteId
          ..entityUuid = note.uuid
          ..operation = isNew ? 'Insert' : 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(cnQueue);

        // 6. Sync queue logs for CreditNoteItems
        for (var item in items) {
          final itemQueue = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = 'CreditNoteItem'
            ..entityId = item.id
            ..entityUuid = item.uuid
            ..operation = isNew ? 'Insert' : 'Update'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(itemQueue);
        }
      });

      logger.info('Credit Note #\${note.creditNoteNumber} saved successfully.');
    } catch (e) {
      throw DatabaseException('Failed to save credit note: \$e');
    }
  }

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '\${DateTime.now().millisecondsSinceEpoch}-\${parts.join("-")}';
  }
}
