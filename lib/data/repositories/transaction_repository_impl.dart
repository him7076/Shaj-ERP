import 'dart:math';
import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/deleted_voucher_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/transaction_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class TransactionRepositoryImpl extends BaseIsarRepository<Transaction> implements TransactionRepository {
  TransactionRepositoryImpl(Isar isar) : super(isar, 'Transaction');

  @override
  IsarCollection<Transaction> get collection => isar.collection<Transaction>();

  @override
  Future<List<Transaction>> searchTransactions(String query) async {
    if (query.trim().isEmpty) {
      return await getAll();
    }
    try {
      final cleanQuery = query.trim().toLowerCase();
      final all = await getAll();
      return all.where((t) {
        return (t.transactionNumber?.toLowerCase().contains(cleanQuery) ?? false) ||
               (t.partyName?.toLowerCase().contains(cleanQuery) ?? false) ||
               (t.transactionType?.toLowerCase().contains(cleanQuery) ?? false) ||
               (t.remarks?.toLowerCase().contains(cleanQuery) ?? false);
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to search transactions: $e');
    }
  }

  @override
  Future<String> generateNextTransactionNumber(String type) async {
    try {
      final allTxns = await collection.where().findAll();
      int maxNum = 0;
      for (var t in allTxns) {
        if (t.transactionType == type && t.transactionNumber != null) {
          final match = RegExp(r'\d+').firstMatch(t.transactionNumber!);
          if (match != null) {
            final parsed = int.tryParse(match.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final nextNum = maxNum + 1;
      final suffix = nextNum.toString().padLeft(2, '0');
      String prefix = 'PAYMENT';
      if (type == 'Receipt' || type == 'Payment In') prefix = 'RECEIPT';
      if (type == 'Expense') prefix = 'EXP';
      if (type == 'Other Income') prefix = 'OTHER Income';
      if (type == 'Credit Note') prefix = 'CN';
      if (type == 'Debit Note') prefix = 'DN';
      return '$prefix-$suffix';
    } catch (e) {
      throw DatabaseException('Failed to generate transaction number: $e');
    }
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    try {
      final isNew = transaction.id == Isar.autoIncrement;
      transaction.uuid ??= _generateUuid();
      transaction.transactionNumber ??= await generateNextTransactionNumber(transaction.transactionType ?? 'Payment');
      transaction.createdAt = isNew ? DateTime.now() : transaction.createdAt;
      transaction.updatedAt = DateTime.now();
      transaction.isDeleted = false;
      transaction.isSynced = false;
      transaction.version = isNew ? 1 : transaction.version + 1;

      await isar.writeTxn(() async {
        // Fetch old transaction before putting the updated one (if editing)
        Transaction? oldTransaction;
        if (!isNew) {
          oldTransaction = await collection.get(transaction.id);
        }

        // 1. Revert Old Transaction's Balances (if editing)
        if (oldTransaction != null) {
          // Revert old party outstanding balance
          if (oldTransaction.partyUuid != null) {
            final oldParty = await isar.partys.filter().uuidEqualTo(oldTransaction.partyUuid).findFirst();
            if (oldParty != null) {
              final oldAmt = oldTransaction.amount ?? 0.0;
              final oldType = oldTransaction.transactionType;
              if (oldType == 'Receipt' || oldType == 'Credit Note' || oldType == 'Payment' || oldType == 'Debit Note') {
                oldParty.outstandingBalance = (oldParty.outstandingBalance ?? 0.0) + oldAmt;
              } else if (oldType == 'Sales' || oldType == 'Purchase') {
                oldParty.outstandingBalance = (oldParty.outstandingBalance ?? 0.0) - oldAmt;
              }
              oldParty.updatedAt = DateTime.now();
              await isar.partys.put(oldParty);
            }
          }

          // Revert old target party balance (if Transfer)
          if (oldTransaction.transactionType == 'Transfer' && oldTransaction.targetPartyUuid != null) {
            final oldTargetParty = await isar.partys.filter().uuidEqualTo(oldTransaction.targetPartyUuid).findFirst();
            if (oldTargetParty != null) {
              final oldAmt = oldTransaction.amount ?? 0.0;
              oldTargetParty.outstandingBalance = (oldTargetParty.outstandingBalance ?? 0.0) - oldAmt;
              oldTargetParty.updatedAt = DateTime.now();
              await isar.partys.put(oldTargetParty);
            }
          }

          // Revert old linked bills
          if (oldTransaction.linkedBillUuid != null) {
            final oldType = oldTransaction.transactionType;
            final oldAmt = oldTransaction.amount ?? 0.0;
            final oldAllocations = _parseAllocations(oldTransaction.linkedBillUuid, oldAmt);

            for (final entry in oldAllocations.entries) {
              final billUuid = entry.key;
              final allocAmt = entry.value;

              if (oldType == 'Receipt' || oldType == 'Credit Note') {
                final invoice = await isar.invoices.filter().uuidEqualTo(billUuid).findFirst();
                if (invoice != null) {
                  invoice.paidAmount = (invoice.paidAmount ?? 0.0) - allocAmt;
                  invoice.pendingAmount = (invoice.grandTotal ?? 0.0) - invoice.paidAmount!;
                  if (invoice.pendingAmount! <= 0) {
                    invoice.paymentStatus = 'Paid';
                  } else if (invoice.paidAmount! > 0) {
                    invoice.paymentStatus = 'Partially Paid';
                  } else {
                    invoice.paymentStatus = 'Unpaid';
                  }
                  invoice.updatedAt = DateTime.now();
                  invoice.isSynced = false;
                  await isar.invoices.put(invoice);
                  await isar.syncQueues.put(SyncQueue()
                    ..uuid = _generateUuid()
                    ..entityType = 'Invoice'
                    ..entityId = invoice.id
                    ..entityUuid = invoice.uuid
                    ..operation = 'Update'
                    ..createdAt = DateTime.now()
                    ..updatedAt = DateTime.now());
                }
              } else if (oldType == 'Payment' || oldType == 'Debit Note') {
                final purchase = await isar.purchases.filter().uuidEqualTo(billUuid).findFirst();
                if (purchase != null) {
                  purchase.paidAmount = (purchase.paidAmount ?? 0.0) - allocAmt;
                  purchase.pendingAmount = (purchase.grandTotal ?? 0.0) - purchase.paidAmount!;
                  if (purchase.pendingAmount! <= 0) {
                    purchase.paymentStatus = 'Paid';
                  } else if (purchase.paidAmount! > 0) {
                    purchase.paymentStatus = 'Partially Paid';
                  } else {
                    purchase.paymentStatus = 'Unpaid';
                  }
                  purchase.updatedAt = DateTime.now();
                  purchase.isSynced = false;
                  await isar.purchases.put(purchase);
                  await isar.syncQueues.put(SyncQueue()
                    ..uuid = _generateUuid()
                    ..entityType = 'Purchase'
                    ..entityId = purchase.id
                    ..entityUuid = purchase.uuid
                    ..operation = 'Update'
                    ..createdAt = DateTime.now()
                    ..updatedAt = DateTime.now());
                }
              }
            }
          }
        }

        // 2. Put the transaction
        final transactionId = await collection.put(transaction);
        transaction.id = transactionId;

        // 3. Adjust Party Outstanding Balances
        if (transaction.partyUuid != null) {
          final party = await isar.partys.filter().uuidEqualTo(transaction.partyUuid).findFirst();
          if (party != null) {
            final amt = transaction.amount ?? 0.0;
            final type = transaction.transactionType;
            
            if (type == 'Receipt' || type == 'Credit Note' || type == 'Payment' || type == 'Debit Note') {
              party.outstandingBalance = (party.outstandingBalance ?? 0.0) - amt;
            } else if (type == 'Sales' || type == 'Purchase') {
              party.outstandingBalance = (party.outstandingBalance ?? 0.0) + amt;
            }
            party.updatedAt = DateTime.now();
            party.isSynced = false;
            await isar.partys.put(party);
            if (!kIsWeb) {
              transaction.party.value = party;
              await transaction.party.save();
            }
            await isar.syncQueues.put(SyncQueue()
              ..uuid = _generateUuid()
              ..entityType = 'Party'
              ..entityId = party.id
              ..entityUuid = party.uuid
              ..operation = 'Update'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now());
          }
        }

        // 4. Adjust target party (if Transfer)
        if (transaction.transactionType == 'Transfer' && transaction.targetPartyUuid != null) {
          final targetParty = await isar.partys.filter().uuidEqualTo(transaction.targetPartyUuid).findFirst();
          if (targetParty != null) {
            final amt = transaction.amount ?? 0.0;
            targetParty.outstandingBalance = (targetParty.outstandingBalance ?? 0.0) + amt;
            targetParty.updatedAt = DateTime.now();
            targetParty.isSynced = false;
            await isar.partys.put(targetParty);
            await isar.syncQueues.put(SyncQueue()
              ..uuid = _generateUuid()
              ..entityType = 'Party'
              ..entityId = targetParty.id
              ..entityUuid = targetParty.uuid
              ..operation = 'Update'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now());
          }
        }

        // 5. Update linked Invoices or Purchase bills
        if (transaction.linkedBillUuid != null) {
          final type = transaction.transactionType;
          final amt = transaction.amount ?? 0.0;
          final allocations = _parseAllocations(transaction.linkedBillUuid, amt);

          for (final entry in allocations.entries) {
            final billUuid = entry.key;
            final allocAmt = entry.value;

            if (type == 'Receipt' || type == 'Credit Note') {
              final invoice = await isar.invoices.filter().uuidEqualTo(billUuid).findFirst();
              if (invoice != null) {
                invoice.paidAmount = (invoice.paidAmount ?? 0.0) + allocAmt;
                invoice.pendingAmount = (invoice.grandTotal ?? 0.0) - invoice.paidAmount!;
                if (invoice.pendingAmount! <= 0) {
                  invoice.paymentStatus = 'Paid';
                } else if (invoice.paidAmount! > 0) {
                  invoice.paymentStatus = 'Partially Paid';
                } else {
                  invoice.paymentStatus = 'Unpaid';
                }
                invoice.updatedAt = DateTime.now();
                invoice.isSynced = false;
                await isar.invoices.put(invoice);
                await isar.syncQueues.put(SyncQueue()
                  ..uuid = _generateUuid()
                  ..entityType = 'Invoice'
                  ..entityId = invoice.id
                  ..entityUuid = invoice.uuid
                  ..operation = 'Update'
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now());
              }
            } else if (type == 'Payment' || type == 'Debit Note') {
              final purchase = await isar.purchases.filter().uuidEqualTo(billUuid).findFirst();
              if (purchase != null) {
                purchase.paidAmount = (purchase.paidAmount ?? 0.0) + allocAmt;
                purchase.pendingAmount = (purchase.grandTotal ?? 0.0) - purchase.paidAmount!;
                if (purchase.pendingAmount! <= 0) {
                  purchase.paymentStatus = 'Paid';
                } else if (purchase.paidAmount! > 0) {
                  purchase.paymentStatus = 'Partially Paid';
                } else {
                  purchase.paymentStatus = 'Unpaid';
                }
                purchase.updatedAt = DateTime.now();
                purchase.isSynced = false;
                await isar.purchases.put(purchase);
                await isar.syncQueues.put(SyncQueue()
                  ..uuid = _generateUuid()
                  ..entityType = 'Purchase'
                  ..entityId = purchase.id
                  ..entityUuid = purchase.uuid
                  ..operation = 'Update'
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now());
              }
            }
          }
        }

        // 6. Add to Sync Queue
        final queueItem = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Transaction'
          ..entityId = transactionId
          ..entityUuid = transaction.uuid
          ..operation = isNew ? 'Insert' : 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(queueItem);
      });

      logger.info('Transaction ${transaction.transactionNumber} saved successfully.');
    } catch (e) {
      throw DatabaseException('Failed to save transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(Transaction transaction) async {
    try {
      await isar.writeTxn(() async {
        transaction.isDeleted = true;
        transaction.updatedAt = DateTime.now();
        await collection.put(transaction);

        // Revert party balances
        if (transaction.partyUuid != null) {
          final party = await isar.partys.filter().uuidEqualTo(transaction.partyUuid).findFirst();
          if (party != null) {
            final amt = transaction.amount ?? 0.0;
            final type = transaction.transactionType;

            if (type == 'Receipt' || type == 'Credit Note' || type == 'Payment' || type == 'Debit Note') {
              party.outstandingBalance = (party.outstandingBalance ?? 0.0) + amt;
            } else if (type == 'Sales' || type == 'Purchase') {
              party.outstandingBalance = (party.outstandingBalance ?? 0.0) - amt;
            }
            party.updatedAt = DateTime.now();
            await isar.partys.put(party);
          }
        }

        if (transaction.transactionType == 'Transfer' && transaction.targetPartyUuid != null) {
          final targetParty = await isar.partys.filter().uuidEqualTo(transaction.targetPartyUuid).findFirst();
          if (targetParty != null) {
            final amt = transaction.amount ?? 0.0;
            targetParty.outstandingBalance = (targetParty.outstandingBalance ?? 0.0) - amt;
            targetParty.updatedAt = DateTime.now();
            await isar.partys.put(targetParty);
          }
        }

        // Revert linked bill totals
        if (transaction.linkedBillUuid != null) {
          final type = transaction.transactionType;
          final amt = transaction.amount ?? 0.0;
          final allocations = _parseAllocations(transaction.linkedBillUuid, amt);

          for (final entry in allocations.entries) {
            final billUuid = entry.key;
            final allocAmt = entry.value;

            if (type == 'Receipt' || type == 'Credit Note') {
              final invoice = await isar.invoices.filter().uuidEqualTo(billUuid).findFirst();
              if (invoice != null) {
                invoice.paidAmount = (invoice.paidAmount ?? 0.0) - allocAmt;
                invoice.pendingAmount = (invoice.grandTotal ?? 0.0) - invoice.paidAmount!;
                if (invoice.pendingAmount! <= 0) {
                  invoice.paymentStatus = 'Paid';
                } else if (invoice.paidAmount! > 0) {
                  invoice.paymentStatus = 'Partially Paid';
                } else {
                  invoice.paymentStatus = 'Unpaid';
                }
                invoice.updatedAt = DateTime.now();
                await isar.invoices.put(invoice);
              }
            } else if (type == 'Payment' || type == 'Debit Note') {
              final purchase = await isar.purchases.filter().uuidEqualTo(billUuid).findFirst();
              if (purchase != null) {
                purchase.paidAmount = (purchase.paidAmount ?? 0.0) - allocAmt;
                purchase.pendingAmount = (purchase.grandTotal ?? 0.0) - purchase.paidAmount!;
                if (purchase.pendingAmount! <= 0) {
                  purchase.paymentStatus = 'Paid';
                } else if (purchase.paidAmount! > 0) {
                  purchase.paymentStatus = 'Partially Paid';
                } else {
                  purchase.paymentStatus = 'Unpaid';
                }
                purchase.updatedAt = DateTime.now();
                await isar.purchases.put(purchase);
              }
            }
          }
        }

        // Create Audit Record for Deleted Voucher
        final deletedVoucher = DeletedVoucher()
          ..uuid = _generateUuid()
          ..voucherType = transaction.transactionType ?? 'Transaction'
          ..voucherNumber = transaction.transactionNumber
          ..partyName = transaction.partyName
          ..amount = transaction.amount
          ..remarks = transaction.remarks
          ..deletedAt = DateTime.now()
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.collection<DeletedVoucher>().put(deletedVoucher);


        // Add to Sync Queue
        final queueItem = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Transaction'
          ..entityId = transaction.id
          ..entityUuid = transaction.uuid
          ..operation = 'Delete'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(queueItem);
      });

      logger.info('Transaction ${transaction.transactionNumber} deleted.');
    } catch (e) {
      throw DatabaseException('Failed to delete transaction: $e');
    }
  }

  Map<String, double> _parseAllocations(String? linkedBillUuid, double txnAmount) {
    if (linkedBillUuid == null || linkedBillUuid.trim().isEmpty) {
      return {};
    }
    final clean = linkedBillUuid.trim();
    if (clean.startsWith('{')) {
      try {
        final decoded = json.decode(clean) as Map<String, dynamic>;
        return decoded.map((key, val) => MapEntry(key, (val as num).toDouble()));
      } catch (_) {
        return {clean: txnAmount};
      }
    } else {
      return {clean: txnAmount};
    }
  }

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
  }
}
