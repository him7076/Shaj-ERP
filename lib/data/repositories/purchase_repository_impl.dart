import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/purchase_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/sync_manager.dart';

class PurchaseRepositoryImpl extends BaseIsarRepository<Purchase> implements PurchaseRepository {
  PurchaseRepositoryImpl(Isar isar) : super(isar, 'Purchase');

  @override
  IsarCollection<Purchase> get collection => isar.collection<Purchase>();

  @override
  Future<List<Purchase>> searchPurchases(String query) async {
    if (query.trim().isEmpty) {
      return await getAll();
    }

    try {
      final cleanQuery = query.trim();
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .purchaseNumberContains(cleanQuery, caseSensitive: false)
              .or()
              .partyNameContains(cleanQuery, caseSensitive: false))
          .findAll();
    } catch (e) {
      throw DatabaseException('Failed to search purchases: $e');
    }
  }

  @override
  Future<String> generateNextPurchaseNumber() async {
    try {
      final allPurchases = await collection.where().findAll();
      int maxNum = 0;
      for (var pur in allPurchases) {
        if (pur.purchaseNumber != null) {
          final match = RegExp(r'\d+').firstMatch(pur.purchaseNumber!);
          if (match != null) {
            final parsed = int.tryParse(match.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final nextNum = maxNum + 1;
      final suffix = nextNum.toString().padLeft(2, '0');
      return 'PUR-$suffix';
    } catch (e) {
      throw DatabaseException('Failed to generate purchase number: $e');
    }
  }

  @override
  Future<void> savePurchase(Purchase purchase, List<PurchaseItem> items) async {
    try {
      final isNew = purchase.id == Isar.autoIncrement;
      purchase.uuid ??= _generateUuid();
      purchase.createdAt = isNew ? DateTime.now() : purchase.createdAt;
      purchase.updatedAt = DateTime.now();
      purchase.isDeleted = false;
      purchase.isSynced = false;
      purchase.version = isNew ? 1 : purchase.version + 1;

      await isar.writeTxn(() async {
        // Fetch old purchase before putting (if editing)
        Purchase? oldPurchase;
        if (!isNew) {
          oldPurchase = await collection.get(purchase.id);
        }

        // 1. Put Purchase
        final purchaseId = await collection.put(purchase);
        purchase.id = purchaseId;

        // Load Party link
        if (!kIsWeb) {
          try { await purchase.party.load(); } catch (_) {}
        }
        final party = kIsWeb
            ? (purchase.partyId != null ? await isar.partys.get(purchase.partyId!) : null)
            : purchase.party.value;

        // 2. Adjust Party Outstanding Balance
        if (oldPurchase != null) {
          final oldPartyId = oldPurchase.partyId;
          final oldParty = oldPartyId != null ? await isar.partys.get(oldPartyId) : null;
          if (oldParty != null) {
            oldParty.outstandingBalance = (oldParty.outstandingBalance ?? 0.0) - (oldPurchase.pendingAmount ?? 0.0);
            await isar.partys.put(oldParty);
          }
        }

        if (party != null) {
          party.outstandingBalance = (party.outstandingBalance ?? 0.0) + (purchase.pendingAmount ?? 0.0);
          party.updatedAt = DateTime.now();
          await isar.partys.put(party);
        }

        // 3. Clear old items if editing
        if (!isNew) {
          final oldItems = await isar.collection<PurchaseItem>()
              .filter()
              .purchaseUuidEqualTo(purchase.uuid)
              .or()
              .purchaseIdEqualTo(purchaseId)
              .or()
              .purchase((q) => q.idEqualTo(purchaseId))
              .findAll();

          // Restore stock levels before deletion (converting secondary unit if applicable)
          for (var oldItem in oldItems) {
            final targetItem = await isar.items.get(oldItem.itemId ?? 0);
            if (targetItem != null) {
              double restoredQty = oldItem.quantity ?? 0.0;
              final convFactor = targetItem.conversionFactor ?? 1.0;
              if (convFactor > 1.0 && targetItem.secondaryUnit != null && targetItem.secondaryUnit!.isNotEmpty) {
                final uName = (oldItem.unit ?? '').trim().toLowerCase();
                final sName = targetItem.secondaryUnit!.trim().toLowerCase();
                final pName = (targetItem.primaryUnitName ?? targetItem.unit.value?.shortName ?? '').trim().toLowerCase();
                if (uName == sName && uName != pName) {
                  restoredQty = restoredQty / convFactor;
                }
              }
              targetItem.currentStock = (targetItem.currentStock ?? 0.0) - restoredQty;
              await isar.items.put(targetItem);
            }
          }
          
          await isar.collection<PurchaseItem>().deleteAll(oldItems.map((e) => e.id).toList());
        }

        // 4. Save new purchase items & adjust stocks in batch
        final newItems = <PurchaseItem>[];
        final itemIds = items.map((i) => i.itemId ?? 0).where((id) => id > 0).toSet();
        final fetchedItems = await isar.items.getAll(itemIds.toList());
        final Map<int, Item> targetItemMap = {
          for (var item in fetchedItems)
            if (item != null) item.id: item
        };

        for (var item in items) {
          final newItem = PurchaseItem()
            ..uuid = _generateUuid()
            ..purchaseId = purchaseId
            ..purchaseUuid = purchase.uuid
            ..itemId = item.itemId
            ..itemName = item.itemName
            ..hsnCode = item.hsnCode
            ..quantity = item.quantity ?? 1.0
            ..unit = item.unit
            ..rate = item.rate ?? 0.0
            ..discount = item.discount ?? 0.0
            ..taxableAmount = item.taxableAmount ?? 0.0
            ..gstRate = item.gstRate ?? 18.0
            ..gstAmount = item.gstAmount ?? 0.0
            ..totalAmount = item.totalAmount ?? 0.0
            ..batchNumber = item.batchNumber
            ..expiryDate = item.expiryDate
            ..mfgDate = item.mfgDate
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          if (!kIsWeb) {
            newItem.item.value = item.item.value;
            newItem.purchase.value = purchase;
          }

          newItems.add(newItem);

          final targetItem = targetItemMap[item.itemId ?? 0];
          if (targetItem != null) {
            final double current = targetItem.currentStock ?? 0.0;
            double qtyInPrimary = item.quantity ?? 0.0;
            final convFactor = targetItem.conversionFactor ?? 1.0;
            if (convFactor > 1.0 && targetItem.secondaryUnit != null && targetItem.secondaryUnit!.isNotEmpty) {
              final uName = (item.unit ?? '').trim().toLowerCase();
              final sName = targetItem.secondaryUnit!.trim().toLowerCase();
              final pName = (targetItem.primaryUnitName ?? targetItem.unit.value?.shortName ?? '').trim().toLowerCase();
              if (uName == sName && uName != pName) {
                qtyInPrimary = qtyInPrimary / convFactor;
              }
            }

            targetItem.currentStock = current + qtyInPrimary;

            final timestamp = DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' ');
            final logEntry = '[$timestamp] STOCK_IN (Purchase): +$qtyInPrimary | Bal: ${targetItem.currentStock} | Ref: ${purchase.purchaseNumber}';
            final currentNotes = targetItem.notes ?? '';
            targetItem.notes = currentNotes.isEmpty ? logEntry : '$logEntry\n$currentNotes';
          }
        }

        await isar.purchaseItems.putAll(newItems);
        if (targetItemMap.isNotEmpty) {
          await isar.items.putAll(targetItemMap.values.toList());
        }

        // 5. Create Sync Queue record
        final queueItem = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Purchase'
          ..entityId = purchaseId
          ..entityUuid = purchase.uuid
          ..operation = isNew ? 'Insert' : 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(queueItem);
      });
      
      logger.info('Purchase bill ${purchase.purchaseNumber} saved successfully.');
      Future.microtask(() {
        try { SyncManager.triggerUpload(); } catch (_) {}
      });
    } catch (e) {
      throw DatabaseException('Failed to save purchase bill: $e');
    }
  }

  // Self-contained UUID generator
  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
  }
}
