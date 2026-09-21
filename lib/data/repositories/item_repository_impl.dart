import 'package:isar/isar.dart';
import 'dart:math';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/item_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/services/sync_manager.dart';

class ItemRepositoryImpl extends BaseIsarRepository<Item> implements ItemRepository {
  ItemRepositoryImpl(Isar isar) : super(isar, 'Item');

  @override
  IsarCollection<Item> get collection => isar.collection<Item>();

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '\-\';
  }

  @override
  Future<List<Item>> searchItems(String query) async {
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
              .itemNameContains(cleanQuery, caseSensitive: false)
              .or()
              .itemCodeContains(cleanQuery, caseSensitive: false)
              .or()
              .hsnCodeContains(cleanQuery, caseSensitive: false)
              .or()
              .barcodeContains(cleanQuery, caseSensitive: false)
              .or()
              .skuContains(cleanQuery, caseSensitive: false)
              .or()
              .skuCodeContains(cleanQuery, caseSensitive: false))
          .findAll();
    } catch (e) {
      throw DatabaseException('Failed to search items: \');
    }
  }

  @override
  Future<String> generateNextItemCode() async {
    try {
      final lastItem = await collection
          .filter()
          .itemCodeIsNotNull()
          .sortByItemCodeDesc()
          .findFirst();

      if (lastItem == null || lastItem.itemCode == null) {
        return 'ITM00001';
      }

      final code = lastItem.itemCode!;
      if (!code.startsWith('ITM')) {
        return 'ITM00001';
      }

      final numStr = code.substring(3);
      final currentNum = int.tryParse(numStr) ?? 0;
      final nextNum = currentNum + 1;
      
      final nextCode = 'ITM\';
      logger.debug('Generated next item code: \ (previous: \)');
      return nextCode;
    } catch (e) {
      throw DatabaseException('Failed to generate next item code: \');
    }
  }

  @override
  Future<List<Item>> getAll() async {
    try {
      final items = await collection.filter().isDeletedEqualTo(false).findAll();
      for (var item in items) {
        try { await item.category.load(); } catch (_) {}
        try { await item.brand.load(); } catch (_) {}
        try { await item.unit.load(); } catch (_) {}
      }
      return items;
    } catch (e) {
      throw DatabaseException('Failed to retrieve all active Item: \');
    }
  }

  @override
  Future<Item?> getByUuid(String uuid) async {
    try {
      final allItems = await getAll();
      final entity = allItems.where((e) => e.uuid == uuid).firstOrNull;
      if (entity == null || entity.isDeleted) return null;
      return entity;
    } catch (e) {
      throw DatabaseException('Failed to retrieve Item by uuid: \');
    }
  }

  @override
  Future<void> create(Item entity, {bool isSyncDownload = false}) async {
    try {
      entity.uuid ??= _generateUuid();
      entity.createdAt = DateTime.now();
      entity.updatedAt = DateTime.now();
      entity.isDeleted = false;
      entity.isSynced = isSyncDownload;
      entity.version = 1;

      await isar.writeTxn(() async {
        final id = await collection.put(entity);
        entity.id = id;

        if (!isSyncDownload) {
          final queueItem = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = 'Item'
            ..entityId = id
            ..entityUuid = entity.uuid
            ..operation = 'Insert'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(queueItem);
        }

        final managedItem = await collection.get(id);
        if (managedItem != null) {
          managedItem.category.value = entity.category.value;
          managedItem.unit.value = entity.unit.value;
          managedItem.brand.value = entity.brand.value;
          try {
            await managedItem.category.save();
            await managedItem.unit.save();
            await managedItem.brand.save();
          } catch (e) {
            if (!e.toString().contains('managed by Isar')) {
              rethrow;
            }
          }
        }
      });
      
      logger.debug('Item created. isSyncDownload: \, UUID: \');
      if (!isSyncDownload) SyncManager.triggerUpload();
    } catch (e) {
      throw DatabaseException('Failed to create Item: \');
    }
  }

  @override
  Future<void> update(Item entity, {bool isSyncDownload = false}) async {
    try {
      final existing = await collection.get(entity.id);
      if (existing == null) {
        throw RecordNotFoundException('Cannot update Item: Record not found.');
      }

      if (!isSyncDownload) {
        entity.updatedAt = DateTime.now();
        entity.isSynced = false;
        entity.version += 1;
      } else {
        entity.isSynced = true;
      }

      await isar.writeTxn(() async {
        await collection.put(entity);

        if (!isSyncDownload) {
          final queueItem = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = 'Item'
            ..entityId = entity.id
            ..entityUuid = entity.uuid
            ..operation = 'Update'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(queueItem);
        }

        final managedItem = await collection.get(entity.id);
        if (managedItem != null) {
          managedItem.category.value = entity.category.value;
          managedItem.unit.value = entity.unit.value;
          managedItem.brand.value = entity.brand.value;
          try {
            await managedItem.category.save();
            await managedItem.unit.save();
            await managedItem.brand.save();
          } catch (e) {
            if (!e.toString().contains('managed by Isar')) {
              rethrow;
            }
          }
        }
      });
      
      logger.debug('Item updated. isSyncDownload: \, UUID: \');
      if (!isSyncDownload) SyncManager.triggerUpload();
    } on RecordNotFoundException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to update Item: \');
    }
  }
}
