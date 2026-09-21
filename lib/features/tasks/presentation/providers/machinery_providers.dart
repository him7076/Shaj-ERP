import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/data/local/collections/machinery_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

final machineryListProvider = StreamProvider<List<Machinery>>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  return dbService.isar.collection<Machinery>().where().filter().isDeletedEqualTo(false).watch(fireImmediately: true);
});

final machineryProvider = Provider<MachineryNotifier>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  final syncService = ref.read(syncServiceProvider);
  return MachineryNotifier(dbService, syncService);
});

class MachineryNotifier {
  final DatabaseService _dbService;
  final SyncService _syncService;

  MachineryNotifier(this._dbService, this._syncService);

  Future<void> saveMachinery(Machinery machinery) async {
    final isNew = machinery.id == Isar.autoIncrement;
    if (machinery.uuid == null || machinery.uuid!.isEmpty) {
      machinery.uuid = const Uuid().v4();
    }
    
    machinery.updatedAt = DateTime.now();
    machinery.isSynced = false;

    await _dbService.isar.writeTxn(() async {
      await _dbService.isar.collection<Machinery>().put(machinery);
    });

    _syncService.enqueueSync('Machinery', machinery.id, isNew ? 'Create' : 'Update');
  }

  Future<void> deleteMachinery(int id) async {
    final machinery = await _dbService.isar.collection<Machinery>().get(id);
    if (machinery != null) {
      machinery.isDeleted = true;
      machinery.updatedAt = DateTime.now();
      machinery.isSynced = false;

      await _dbService.isar.writeTxn(() async {
        await _dbService.isar.collection<Machinery>().put(machinery);
      });

      _syncService.enqueueSync('Machinery', machinery.id, 'Update'); // Soft delete
    }
  }

  Future<Machinery?> getMachinery(int id) async {
    return await _dbService.isar.collection<Machinery>().get(id);
  }
}
