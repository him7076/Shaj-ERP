import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/sync_queue_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';

class SyncQueueRepositoryImpl extends BaseIsarRepository<SyncQueue> implements SyncQueueRepository {
  SyncQueueRepositoryImpl(Isar isar) : super(isar, 'SyncQueue');

  @override
  IsarCollection<SyncQueue> get collection => isar.collection<SyncQueue>();

  @override
  Future<List<SyncQueue>> getPendingSyncs() async {
    return await collection.filter().isSyncedEqualTo(false).findAll();
  }

  @override
  Future<void> markAsSynced(int id) async {
    final item = await collection.get(id);
    if (item != null) {
      item.isSynced = true;
      item.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await collection.put(item);
      });
    }
  }
}
