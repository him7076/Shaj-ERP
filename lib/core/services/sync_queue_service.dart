import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class SyncQueueService {
  final DatabaseService _dbService;

  SyncQueueService(this._dbService);

  IsarCollection<SyncQueue> get _queueCollection => _dbService.isar.syncQueues;

  /// Fetch all pending queue records, ordered by creation date (FIFO)
  Future<List<SyncQueue>> getPendingQueue() async {
    try {
      return await _queueCollection.filter().isSyncedEqualTo(false).sortByCreatedAt().findAll();
    } catch (e) {
      logger.error('Failed to get pending sync queue', e);
      return [];
    }
  }

  /// Remove sync queue item from local db once uploaded successfully
  Future<void> removeQueueItem(int id) async {
    try {
      await _dbService.isar.writeTxn(() async {
        await _queueCollection.delete(id);
      });
      logger.debug('Removed SyncQueue item ID $id from queue.');
    } catch (e) {
      logger.error('Failed to remove SyncQueue item ID $id', e);
    }
  }

  /// Record a failed synchronization attempt and increment retry count
  Future<void> updateAttempt(SyncQueue queueItem, String errorMessage) async {
    try {
      queueItem.retryCount += 1;
      queueItem.lastAttempt = DateTime.now();
      
      await _dbService.isar.writeTxn(() async {
        await _queueCollection.put(queueItem);
      });
      logger.debug('Incremented retryCount for SyncQueue ID ${queueItem.id} to ${queueItem.retryCount}. Error: $errorMessage');
    } catch (e) {
      logger.error('Failed to update SyncQueue attempt for ID ${queueItem.id}', e);
    }
  }

  /// Remove multiple sync queue items by IDs atomically
  Future<void> removeQueueItemsByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    try {
      await _dbService.isar.writeTxn(() async {
        await _queueCollection.deleteAll(ids);
      });
      logger.debug('Removed ${ids.length} SyncQueue items from queue.');
    } catch (e) {
      logger.error('Failed to remove batch SyncQueue items', e);
    }
  }

  /// Atomically remove sync queue items created at or before cutoff timestamp
  Future<void> removeQueueItemsBefore(DateTime cutoff) async {
    try {
      final allQueue = await _queueCollection.filter().idGreaterThan(-1).findAll();
      final itemsToDelete = allQueue.where((e) => e.createdAt.isBefore(cutoff) || e.createdAt.isAtSameMomentAs(cutoff)).toList();
      if (itemsToDelete.isEmpty) return;
      final ids = itemsToDelete.map((e) => e.id).toList();
      await removeQueueItemsByIds(ids);
      logger.info('Atomic Queue Clearing: Removed ${ids.length} queue items created before $cutoff');
    } catch (e) {
      logger.error('Failed atomic queue clearing before cutoff', e);
    }
  }

  /// Resets retries on all unsynced queue items to trigger sync retry phase
  Future<void> resetAllRetries() async {
    try {
      final pendingItems = await _queueCollection.filter().isSyncedEqualTo(false).findAll();
      if (pendingItems.isEmpty) return;

      await _dbService.isar.writeTxn(() async {
        for (var item in pendingItems) {
          item.retryCount = 0;
          item.lastAttempt = null;
          item.lastError = null;
          await _queueCollection.put(item);
        }
      });
      logger.info('Reset retry counters on ${pendingItems.length} sync queue tasks.');
    } catch (e) {
      logger.error('Failed to reset sync queue retries', e);
    }
  }
}
