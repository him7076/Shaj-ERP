import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'base_repository.dart';

abstract class SyncQueueRepository implements BaseRepository<SyncQueue> {
  /// Retrieves all sync items that are pending sync (isSynced == false)
  Future<List<SyncQueue>> getPendingSyncs();

  /// Marks a sync queue entry as successfully synced
  Future<void> markAsSynced(int id);
}
