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

  /// Resets retries on all failed items to trigger another sync phase
  Future<void> resetAllRetries() async {
    try {
      final failedItems = await _queueCollection.filter().retryCountGreaterThan(0).findAll();
      if (failedItems.isEmpty) return;

      await _dbService.isar.writeTxn(() async {
        for (var item in failedItems) {
          item.retryCount = 0;
          item.lastAttempt = null;
          await _queueCollection.put(item);
        }
      });
      logger.info('Reset retry counters on ${failedItems.length} failed sync tasks.');
    } catch (e) {
      logger.error('Failed to reset sync queue retries', e);
    }
  }
}
