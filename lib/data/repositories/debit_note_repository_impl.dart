import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/debit_note_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class DebitNoteRepositoryImpl extends BaseIsarRepository<DebitNote> implements DebitNoteRepository {
  DebitNoteRepositoryImpl(Isar isar) : super(isar, 'DebitNote');

  @override
  IsarCollection<DebitNote> get collection => isar.collection<DebitNote>();

  @override
  Future<String> generateNextDebitNoteNumber() async {
    try {
      final allItems = await collection.filter().isDeletedEqualTo(false).findAll();
      int maxNum = 0;
      for (var item in allItems) {
        if (item.debitNoteNumber != null ) {
          final matches = RegExp(r'\d+').allMatches(item.debitNoteNumber!);
          if (matches.isNotEmpty) {
            final parsed = int.tryParse(matches.last.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final suffix = (maxNum + 1).toString().padLeft(2, '0');
      return 'DN-$suffix';
    } catch (e) {
      throw DatabaseException('Failed to generate debit note number: $e');
    }
  }

  @override
  Future<void> saveDebitNote(DebitNote note, List<DebitNoteItem> items) async {
    try {
      final isNew = note.id == Isar.autoIncrement;
      note.uuid ??= _generateUuid();
      note.createdAt = isNew ? DateTime.now() : note.createdAt;
      note.updatedAt = DateTime.now();
      note.isDeleted = false;
      note.isSynced = false;
      note.version = isNew ? 1 : note.version + 1;

      await isar.writeTxn(() async {
        DebitNote? oldNote;
        if (!isNew) {
          oldNote = await collection.get(note.id);
        }

        // 1. Put Debit Note
        final noteId = await collection.put(note);
        note.id = noteId;

        // 2. Adjust Party Outstanding Balance (increases what the customer owes us)
        final oldPartyId = oldNote?.partyId;
        final oldParty = kIsWeb
            ? (oldPartyId != null ? await isar.collection<Party>().get(oldPartyId) : null)
            : oldNote?.party.value;
            
        final newParty = kIsWeb
            ? (note.partyId != null ? await isar.collection<Party>().get(note.partyId!) : null)
            : note.party.value;

        if (oldParty != null && !isNew) {
          final oldAmt = oldNote?.grandTotal ?? 0.0;
          oldParty.outstandingBalance = (oldParty.outstandingBalance ?? 0.0) - oldAmt; // revert
          await isar.collection<Party>().put(oldParty);
        }

        if (newParty != null) {
          final amt = note.grandTotal ?? 0.0;
          newParty.outstandingBalance = (newParty.outstandingBalance ?? 0.0) + amt;
          await isar.collection<Party>().put(newParty);
        }

        // 3. Put Items & Adjust Inventory Levels (returned items leave stock)
        for (var item in items) {
          item.uuid ??= _generateUuid();
          item.createdAt = isNew ? DateTime.now() : item.createdAt;
          item.updatedAt = DateTime.now();
          item.isDeleted = false;
          item.isSynced = false;
          item.version = isNew ? 1 : item.version + 1;
          item.parentDebitNoteId = note.id;

          if (!kIsWeb) {
            item.debitNote.value = note;
          }
          await isar.debitNoteItems.put(item);

          // Deduct stock (Purchase Return = items are shipped out)
          final dbItem = kIsWeb
              ? (item.itemId != null ? await isar.items.get(item.itemId!) : null)
              : item.item.value;
          if (dbItem != null) {
            final double available = dbItem.currentStock ?? 0.0;
            final double returned = item.quantity ?? 0.0;
            dbItem.currentStock = available - returned;

            // Log stock movement
            final log = '[\${DateTime.now().toIso8601String().substring(0, 19)}] RETURNED OUT: -\$returned | Bal: \${dbItem.currentStock} | Debit Note #\${note.debitNoteNumber}';
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
            ..transactionType = 'Debit Note'
            ..createdAt = DateTime.now()
            ..version = 1;
        } else {
          txn.version = (txn.version ?? 1) + 1;
        }

        txn.transactionNumber = note.debitNoteNumber;
        txn.transactionDate = note.debitNoteDate ?? DateTime.now();
        txn.partyUuid = newParty?.uuid ?? note.party.value?.uuid;
        txn.partyName = note.partyName;
        txn.amount = note.grandTotal;
        txn.paymentMode = 'Credit';
        txn.remarks = 'Purchase Return: Debit Note #\${note.debitNoteNumber}. \${note.remarks ?? ""}';
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

        // 5. Sync queue logs for DebitNote
        final dnQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'DebitNote'
          ..entityId = noteId
          ..entityUuid = note.uuid
          ..operation = isNew ? 'Insert' : 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(dnQueue);

        // 6. Sync queue logs for DebitNoteItems
        for (var item in items) {
          final itemQueue = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = 'DebitNoteItem'
            ..entityId = item.id
            ..entityUuid = item.uuid
            ..operation = isNew ? 'Insert' : 'Update'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(itemQueue);
        }
      });

      logger.info('Debit Note #\${note.debitNoteNumber} saved successfully.');
    } catch (e) {
      throw DatabaseException('Failed to save debit note: \$e');
    }
  }

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '\${DateTime.now().millisecondsSinceEpoch}-\${parts.join("-")}';
  }
}
