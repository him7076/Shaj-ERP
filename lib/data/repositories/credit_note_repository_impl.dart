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
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;
      final String prefix = month >= 4 ? 'CN-$year-${year + 1}/' : 'CN-${year - 1}-$year/';

      final count = await collection.filter().creditNoteNumberStartsWith(prefix).count();
      final numStr = (count + 1).toString().padLeft(4, '0');
      return '$prefix$numStr';
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
        // 1. Put Credit Note
        final noteId = await collection.put(note);
        note.id = noteId;

        // 2. Adjust Party Outstanding Balance (reduces what the customer owes us)
        final party = kIsWeb
            ? (note.partyId != null ? await isar.collection<Party>().get(note.partyId!) : null)
            : note.party.value;
        if (party != null && isNew) {
          final amt = note.grandTotal ?? 0.0;
          party.outstandingBalance = (party.outstandingBalance ?? 0.0) - amt;
          await isar.collection<Party>().put(party);
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

          await isar.creditNoteItems.put(item);
          if (!kIsWeb) {
            item.creditNote.value = note;
            await item.creditNote.save();
          }

          // Restore stock (Sales Return = items come back in stock)
          final dbItem = kIsWeb
              ? (item.itemId != null ? await isar.items.get(item.itemId!) : null)
              : item.item.value;
          if (dbItem != null) {
            final double available = dbItem.currentStock ?? 0.0;
            final double returned = item.quantity ?? 0.0;
            dbItem.currentStock = available + returned;

            // Log stock movement
            final log = '[${DateTime.now().toIso8601String().substring(0, 19)}] RETURNED IN: +$returned | Bal: ${dbItem.currentStock} | Credit Note #${note.creditNoteNumber}';
            dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
            await isar.items.put(dbItem);
          }
        }

        if (!kIsWeb) {
          await note.creditNoteItems.save();
        }

        // 4. Save a summary transaction log so it shows up in global transaction registries and ledger reports
        if (isNew) {
          final txn = Transaction()
            ..uuid = _generateUuid()
            ..transactionNumber = note.creditNoteNumber
            ..transactionDate = note.creditNoteDate ?? DateTime.now()
            ..partyUuid = party?.uuid
            ..partyName = note.partyName
            ..transactionType = 'Credit Note'
            ..amount = note.grandTotal
            ..paymentMode = 'Credit'
            ..remarks = 'Sales Return: Credit Note #${note.creditNoteNumber}. ${note.remarks ?? ""}'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now()
            ..isDeleted = false
            ..isSynced = false
            ..version = 1;
          
          if (party != null && !kIsWeb) {
            txn.party.value = party;
          }
          await isar.transactions.put(txn);
          if (party != null && !kIsWeb) {
            await txn.party.save();
          }

          // Sync log for Transaction
          final txnQueue = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = 'Transaction'
            ..entityId = txn.id
            ..entityUuid = txn.uuid
            ..operation = 'Insert'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(txnQueue);
        }

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

      logger.info('Credit Note #${note.creditNoteNumber} saved successfully.');
    } catch (e) {
      throw DatabaseException('Failed to save credit note: $e');
    }
  }

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
  }
}
