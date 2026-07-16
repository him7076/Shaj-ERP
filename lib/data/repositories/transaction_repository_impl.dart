import 'dart:math';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
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
      final count = await collection.filter().isDeletedEqualTo(false).count();
      final suffix = (count + 1).toString().padLeft(6, '0');
      String prefix = 'TXN';
      if (type == 'Credit Note') prefix = 'CN';
      if (type == 'Debit Note') prefix = 'DN';
      return '$prefix-2026-$suffix';
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
        // 1. Put the transaction
        final transactionId = await collection.put(transaction);
        transaction.id = transactionId;

        // 2. Adjust Party Outstanding Balances
        if (transaction.partyUuid != null) {
          final party = await isar.partys.filter().uuidEqualTo(transaction.partyUuid).findFirst();
          if (party != null) {
            final amt = transaction.amount ?? 0.0;
            final type = transaction.transactionType;
            
            // Adjust customer outstanding balance:
            // - Receipt (Payment In), Credit Note, Debit Note, Payment (Payment Out) reduces outstanding balance
            if (type == 'Receipt' || type == 'Credit Note' || type == 'Payment' || type == 'Debit Note') {
              party.outstandingBalance = (party.outstandingBalance ?? 0.0) - amt;
            } else if (type == 'Sales' || type == 'Purchase') {
              party.outstandingBalance = (party.outstandingBalance ?? 0.0) + amt;
            }
            party.updatedAt = DateTime.now();
            await isar.partys.put(party);
            if (!kIsWeb) {
              transaction.party.value = party;
              await transaction.party.save();
            }
          }
        }

        // 3. For transfer type, adjust target party too
        if (transaction.transactionType == 'Transfer' && transaction.targetPartyUuid != null) {
          final targetParty = await isar.partys.filter().uuidEqualTo(transaction.targetPartyUuid).findFirst();
          if (targetParty != null) {
            final amt = transaction.amount ?? 0.0;
            // Target party receives money, so their outstanding increases/decreases based on standard double entry.
            // In ERP, transfer reduces outstanding of sender (source) and increases target balance.
            targetParty.outstandingBalance = (targetParty.outstandingBalance ?? 0.0) + amt;
            targetParty.updatedAt = DateTime.now();
            await isar.partys.put(targetParty);
          }
        }

        // 4. Update linked Invoice or Purchase bill
        if (transaction.linkedBillUuid != null) {
          final amt = transaction.amount ?? 0.0;
          final type = transaction.transactionType;

          if (type == 'Receipt' || type == 'Credit Note') {
            final invoice = await isar.invoices.filter().uuidEqualTo(transaction.linkedBillUuid).findFirst();
            if (invoice != null) {
              invoice.paidAmount = (invoice.paidAmount ?? 0.0) + amt;
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
            final purchase = await isar.purchases.filter().uuidEqualTo(transaction.linkedBillUuid).findFirst();
            if (purchase != null) {
              purchase.paidAmount = (purchase.paidAmount ?? 0.0) + amt;
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

        // 5. Add to Sync Queue
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

            // Revert changes
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
          final amt = transaction.amount ?? 0.0;
          final type = transaction.transactionType;

          if (type == 'Receipt' || type == 'Credit Note') {
            final invoice = await isar.invoices.filter().uuidEqualTo(transaction.linkedBillUuid).findFirst();
            if (invoice != null) {
              invoice.paidAmount = (invoice.paidAmount ?? 0.0) - amt;
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
            final purchase = await isar.purchases.filter().uuidEqualTo(transaction.linkedBillUuid).findFirst();
            if (purchase != null) {
              purchase.paidAmount = (purchase.paidAmount ?? 0.0) - amt;
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

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
  }
}
