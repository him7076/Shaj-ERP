import 'package:isar/isar.dart';
import 'dart:math';
import 'package:business_sahaj_erp/data/local/collections/isar_model.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/base_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

abstract class BaseIsarRepository<T extends IsarModel> implements BaseRepository<T> {
  final Isar isar;
  final String entityType;

  BaseIsarRepository(this.isar, this.entityType);

  IsarCollection<T> get collection => isar.collection<T>();

  @override
  Future<T?> getById(int id) async {
    try {
      final entity = await collection.get(id);
      if (entity == null || entity.isDeleted) return null;
      return entity;
    } catch (e) {
      throw DatabaseException('Failed to retrieve $entityType by ID $id: $e');
    }
  }

  @override
  Future<T?> getByUuid(String uuid) async {
    try {
      final query = collection.buildQuery<T>(
        filter: FilterCondition.equalTo(
          property: 'uuid',
          value: uuid,
        ),
      );
      final entity = await query.findFirst();
      if (entity == null || entity.isDeleted) return null;
      return entity;
    } catch (e) {
      throw DatabaseException('Failed to retrieve $entityType by UUID $uuid: $e');
    }
  }

  @override
  Future<List<T>> getAll() async {
    try {
      final query = collection.buildQuery<T>(
        filter: FilterCondition.equalTo(
          property: 'isDeleted',
          value: false,
        ),
      );
      return await query.findAll();
    } catch (e) {
      throw DatabaseException('Failed to retrieve all active $entityType: $e');
    }
  }

  @override
  Future<void> create(T entity, {bool isSyncDownload = false}) async {
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

        // Only log to sync queue if it is a local change, not a downloaded sync
        if (!isSyncDownload) {
          final queueItem = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = entityType
            ..entityId = id
            ..entityUuid = entity.uuid
            ..operation = 'Insert'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(queueItem);
        }
      });
      
      logger.debug('$entityType created. isSyncDownload: $isSyncDownload, UUID: ${entity.uuid}');
    } catch (e) {
      throw DatabaseException('Failed to create $entityType: $e');
    }
  }

  @override
  Future<void> update(T entity, {bool isSyncDownload = false}) async {
    try {
      // Ensure the record exists and is active (unless it's a sync download, which might overwrite deleted status)
      final existing = await collection.get(entity.id);
      if (existing == null) {
        throw RecordNotFoundException('Cannot update $entityType: Record not found.');
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

        // Only log to sync queue if it is a local change
        if (!isSyncDownload) {
          final queueItem = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = entityType
            ..entityId = entity.id
            ..entityUuid = entity.uuid
            ..operation = 'Update'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(queueItem);
        }
      });
      
      logger.debug('$entityType updated. isSyncDownload: $isSyncDownload, UUID: ${entity.uuid}');
    } on RecordNotFoundException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to update $entityType: $e');
    }
  }

  @override
  Future<void> delete(int id) async {
    // Map hard-delete ID call to soft-delete to comply with guidelines
    try {
      final entity = await collection.get(id);
      if (entity == null || entity.isDeleted) {
        throw RecordNotFoundException('$entityType with ID $id not found.');
      }
      
      await softDelete(entity.uuid!);
    } on RecordNotFoundException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to delete $entityType by ID $id: $e');
    }
  }

  @override
  Future<void> softDelete(String uuid, {bool isSyncDownload = false}) async {
    try {
      final query = collection.buildQuery<T>(
        filter: FilterCondition.equalTo(
          property: 'uuid',
          value: uuid,
        ),
      );
      final entity = await query.findFirst();
      if (entity == null) {
        throw RecordNotFoundException('$entityType with UUID $uuid not found.');
      }

      entity.isDeleted = true;
      if (!isSyncDownload) {
        entity.isSynced = false;
        entity.updatedAt = DateTime.now();
        entity.version += 1;
      } else {
        entity.isSynced = true;
      }

      await isar.writeTxn(() async {
        await collection.put(entity);

        // Only log to sync queue if it is a local change
        if (!isSyncDownload) {
          final queueItem = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = entityType
            ..entityId = entity.id
            ..entityUuid = entity.uuid
            ..operation = 'Delete'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(queueItem);
        }
      });
      
      logger.debug('$entityType soft-deleted. isSyncDownload: $isSyncDownload, UUID: $uuid');
    } on RecordNotFoundException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to soft-delete $entityType: $e');
    }
  }

  // Self-contained UUID generator
  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
  }
}
