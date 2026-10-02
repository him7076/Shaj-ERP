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
      final allItems = await collection.where().findAll();
      int maxNum = 0;
      for (var item in allItems) {
        if (item.debitNoteNumber != null && item.debitNoteNumber!.isNotEmpty) {
          final matches = RegExp(r'\d+').allMatches(item.debitNoteNumber!);
          if (matches.isNotEmpty) {
            final parsed = int.tryParse(matches.last.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      var nextNum = maxNum + 1;
      var candidate = 'DN-${nextNum.toString().padLeft(2, '0')}';

      final existingNumbers = allItems.map((e) => e.debitNoteNumber).toSet();
      while (existingNumbers.contains(candidate)) {
        nextNum++;
        candidate = 'DN-${nextNum.toString().padLeft(2, '0')}';
      }
      return candidate;
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
        } else {
          // Check for unique index collisions on debitNoteNumber and uuid during insert
          if (note.debitNoteNumber == null || note.debitNoteNumber!.isEmpty) {
            note.debitNoteNumber = await generateNextDebitNoteNumber();
          } else {
            final existingWithNo = await collection.filter().debitNoteNumberEqualTo(note.debitNoteNumber!).findFirst();
            if (existingWithNo != null) {
              note.debitNoteNumber = await generateNextDebitNoteNumber();
            }
          }

          final existingWithUuid = await collection.filter().uuidEqualTo(note.uuid!).findFirst();
          if (existingWithUuid != null) {
            note.uuid = _generateUuid();
          }
        }

        // 1. Put Debit Note
        final noteId = await collection.put(note);
        note.id = noteId;

        // 2. Adjust Party Outstanding Balance (increases what the customer owes us)
        Party? oldParty;
        if (oldNote != null && oldNote.partyId != null && oldNote.partyId! > 0) {
          try { oldParty = await isar.partys.get(oldNote.partyId!); } catch (_) {}
        }
        if (oldParty == null && oldNote != null && oldNote.partyName != null && oldNote.partyName!.isNotEmpty) {
          try { oldParty = await isar.partys.filter().partyNameEqualTo(oldNote.partyName!).findFirst(); } catch (_) {}
        }

        Party? newParty;
        if (note.partyId != null && note.partyId! > 0) {
          try { newParty = await isar.partys.get(note.partyId!); } catch (_) {}
        }
        if (newParty == null && note.partyName != null && note.partyName!.isNotEmpty) {
          try { newParty = await isar.partys.filter().partyNameEqualTo(note.partyName!).findFirst(); } catch (_) {}
        }

        if (oldParty != null && !isNew) {
          final oldAmt = oldNote?.grandTotal ?? 0.0;
          oldParty.outstandingBalance = (oldParty.outstandingBalance ?? 0.0) - oldAmt; // revert
          await isar.partys.put(oldParty);
        }

        if (newParty != null) {
          final amt = note.grandTotal ?? 0.0;
          newParty.outstandingBalance = (newParty.outstandingBalance ?? 0.0) + amt;
          await isar.partys.put(newParty);
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
            try { item.debitNote.value = note; } catch (_) {}
          }
          final itemId = await isar.debitNoteItems.put(item);
          item.id = itemId;

          // Deduct stock (Purchase Return = items are shipped out)
          Item? dbItem;
          if (item.itemId != null && item.itemId! > 0) {
            try { dbItem = await isar.items.get(item.itemId!); } catch (_) {}
          }
          if (dbItem == null && item.itemName != null && item.itemName!.isNotEmpty) {
            try { dbItem = await isar.items.filter().itemNameEqualTo(item.itemName!).findFirst(); } catch (_) {}
          }

          if (dbItem != null) {
            final double available = dbItem.currentStock ?? 0.0;
            final double returned = item.quantity ?? 0.0;
            dbItem.currentStock = available - returned;

            final log = '[${DateTime.now().toIso8601String().substring(0, 19)}] RETURNED OUT: -$returned | Bal: ${dbItem.currentStock} | Debit Note #${note.debitNoteNumber}';
            dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
            await isar.items.put(dbItem);
          }
        }

        bool isTxnNew = false;
        Transaction? txn;
        if (note.uuid != null && note.uuid!.isNotEmpty) {
          txn = await isar.transactions.filter().linkedBillUuidEqualTo(note.uuid!).findFirst();
        }
        if (txn == null && note.debitNoteNumber != null && note.debitNoteNumber!.isNotEmpty) {
          txn = await isar.transactions.filter().transactionNumberEqualTo(note.debitNoteNumber!).findFirst();
        }
        
        if (txn == null) {
          isTxnNew = true;
          txn = Transaction()
            ..uuid = _generateUuid()
            ..transactionType = 'Debit Note'
            ..createdAt = DateTime.now()
            ..version = 1;

          if (note.debitNoteNumber != null && note.debitNoteNumber!.isNotEmpty) {
            final existingTxnNo = await isar.transactions.filter().transactionNumberEqualTo(note.debitNoteNumber!).findFirst();
            if (existingTxnNo != null) {
              txn = existingTxnNo;
              isTxnNew = false;
            }
          }
        } else {
          txn.version = (txn.version ?? 1) + 1;
        }

        txn.transactionNumber = note.debitNoteNumber;
        txn.transactionDate = note.debitNoteDate ?? DateTime.now();
        txn.partyUuid = newParty?.uuid ?? note.partyName;
        txn.partyName = note.partyName;
        txn.amount = note.grandTotal;
        txn.paymentMode = 'Credit';
        txn.remarks = 'Purchase Return: Debit Note #${note.debitNoteNumber}. ${note.remarks ?? ""}';
        txn.linkedBillUuid = note.uuid;
        txn.updatedAt = DateTime.now();
        txn.isDeleted = false;
        txn.isSynced = false;
        
        if (newParty != null && !kIsWeb) {
          try { txn.party.value = newParty; } catch (_) {}
        }
        final txnId = await isar.transactions.put(txn);

        // Sync date across any existing transaction logs matching this debit note number or UUID
        final Set<int> syncedTxnIds = {txnId};
        if (note.debitNoteNumber != null && note.debitNoteNumber!.isNotEmpty) {
          final matchingTxns = await isar.transactions
              .filter()
              .group((q) => q.transactionNumberEqualTo(note.debitNoteNumber!).or().linkedBillUuidEqualTo(note.uuid ?? ''))
              .findAll();
          for (var mt in matchingTxns) {
            if (syncedTxnIds.add(mt.id)) {
              mt.transactionDate = note.debitNoteDate ?? DateTime.now();
              mt.partyName = note.partyName;
              mt.amount = note.grandTotal;
              mt.updatedAt = DateTime.now();
              await isar.transactions.put(mt);
            }
          }
        }

        // Sync log for Transaction
        final txnQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Transaction'
          ..entityId = txnId
          ..entityUuid = txn.uuid
          ..operation = isTxnNew ? 'Insert' : 'Update'
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

      logger.info('Debit Note #${note.debitNoteNumber} saved successfully.');
    } catch (e) {
      throw DatabaseException('Failed to save debit note: $e');
    }
  }

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
  }
}
