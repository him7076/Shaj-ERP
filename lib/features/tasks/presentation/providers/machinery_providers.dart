import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/data/local/collections/machinery_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/sync_manager.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

final machineryListProvider = StreamProvider<List<Machinery>>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  return dbService.isar.collection<Machinery>().where().filter().isDeletedEqualTo(false).watch(fireImmediately: true);
});

final machineryProvider = Provider<MachineryNotifier>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  return MachineryNotifier(dbService);
});

class MachineryNotifier {
  final DatabaseService _dbService;

  MachineryNotifier(this._dbService);

  Future<void> saveMachinery(Machinery machinery) async {
    final isNew = machinery.id == Isar.autoIncrement;
    if (machinery.uuid == null || machinery.uuid!.isEmpty) {
      machinery.uuid = const Uuid().v4();
    }
    
    machinery.updatedAt = DateTime.now();
    machinery.isSynced = false;

    await _dbService.isar.writeTxn(() async {
      await _dbService.isar.collection<Machinery>().put(machinery);
      
      final queueItem = SyncQueue()
        ..uuid = const Uuid().v4()
        ..entityType = 'Machinery'
        ..entityId = machinery.id
        ..entityUuid = machinery.uuid
        ..operation = isNew ? 'Insert' : 'Update'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await _dbService.isar.syncQueues.put(queueItem);
    });

    SyncManager.triggerUpload();
  }

  Future<void> deleteMachinery(int id) async {
    final machinery = await _dbService.isar.collection<Machinery>().get(id);
    if (machinery != null) {
      machinery.isDeleted = true;
      machinery.updatedAt = DateTime.now();
      machinery.isSynced = false;

      await _dbService.isar.writeTxn(() async {
        await _dbService.isar.collection<Machinery>().put(machinery);
        
        final queueItem = SyncQueue()
          ..uuid = const Uuid().v4()
          ..entityType = 'Machinery'
          ..entityId = machinery.id
          ..entityUuid = machinery.uuid
          ..operation = 'Delete'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await _dbService.isar.syncQueues.put(queueItem);
      });

      SyncManager.triggerUpload();
    }
  }

  Future<Machinery?> getMachinery(int id) async {
    return await _dbService.isar.collection<Machinery>().get(id);
  }
}
