import 'package:isar/isar.dart';
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
      final count = await collection.filter().isDeletedEqualTo(false).count();
      final suffix = (count + 1).toString().padLeft(6, '0');
      return 'PUR-2026-$suffix';
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
        // 1. Put Purchase
        final purchaseId = await collection.put(purchase);
        purchase.id = purchaseId;

        // Load Party link
        try { await purchase.party.load(); } catch (_) {}
        final party = purchase.party.value;

        // 2. Adjust Party Outstanding Balance (For supplier purchase, outstanding balance reduces if paid or is tracked separately,
        // but for simplicity we keep it tracked if needed or just save party relation)
        if (party != null) {
          await isar.partys.put(party);
        }

        // 3. Clear old items if editing
        if (!isNew) {
          final oldItems = await isar.collection<PurchaseItem>()
              .filter()
              .purchase((q) => q.idEqualTo(purchaseId))
              .findAll();

          // Restore stock levels before deletion
          for (var oldItem in oldItems) {
            final targetItem = await isar.items.get(oldItem.itemId ?? 0);
            if (targetItem != null) {
              targetItem.currentStock = (targetItem.currentStock ?? 0.0) - (oldItem.quantity ?? 0.0);
              await isar.items.put(targetItem);
            }
          }
          
          await isar.collection<PurchaseItem>().deleteAll(oldItems.map((e) => e.id).toList());
        }

        // 4. Save new purchase items & adjust stocks
        for (var item in items) {
          item.uuid ??= _generateUuid();
          item.purchase.value = purchase;
          
          final itemId = await isar.collection<PurchaseItem>().put(item);
          item.id = itemId;
          await item.purchase.save();

          // Update product stock balance (Stock IN)
          final targetItem = await isar.items.get(item.itemId ?? 0);
          if (targetItem != null) {
            final double current = targetItem.currentStock ?? 0.0;
            targetItem.currentStock = current + (item.quantity ?? 0.0);
            
            // Add a history line inside item.notes
            final timestamp = DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' ');
            final logEntry = '[$timestamp] STOCK_IN (Purchase): +${item.quantity} | Bal: ${targetItem.currentStock} | Ref: ${purchase.purchaseNumber}';
            final currentNotes = targetItem.notes ?? '';
            targetItem.notes = currentNotes.isEmpty ? logEntry : '$logEntry\n$currentNotes';

            await isar.items.put(targetItem);
          }
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
