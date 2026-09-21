import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/machinery_category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:uuid/uuid.dart';

final machineryCategoryProvider = Provider<MachineryCategoryNotifier>((ref) {
  return MachineryCategoryNotifier(ref);
});

final machineryCategoryListProvider = FutureProvider<List<MachineryCategory>>((ref) async {
  final notifier = ref.watch(machineryCategoryProvider);
  return notifier.getAllCategories();
});

class MachineryCategoryNotifier {
  final Ref ref;

  MachineryCategoryNotifier(this.ref);

  Future<List<MachineryCategory>> getAllCategories() async {
    final db = ref.read(databaseServiceProvider).isar;
    return await db.collection<MachineryCategory>().filter().isDeletedEqualTo(false).findAll();
  }

  Future<MachineryCategory?> getCategory(int id) async {
    final db = ref.read(databaseServiceProvider).isar;
    return await db.collection<MachineryCategory>().get(id);
  }

  Future<void> saveCategory(MachineryCategory category) async {
    final db = ref.read(databaseServiceProvider).isar;
    
    await db.writeTxn(() async {
      category.updatedAt = DateTime.now();
      if (category.id == Isar.autoIncrement) {
        category.createdAt = DateTime.now();
      } else {
        category.version += 1;
      }
      
      category.isSynced = false;
      await db.collection<MachineryCategory>().put(category);
      
      final syncQueue = SyncQueue()
        ..uuid = const Uuid().v4()
        ..entityType = 'MachineryCategory'
        ..entityId = category.id
        ..entityUuid = category.uuid
        ..operation = 'Update'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
        
      await db.syncQueues.put(syncQueue);
    });

    try {
      ref.read(syncManagerProvider).triggerUpload();
    } catch (_) {}
    
    ref.invalidate(machineryCategoryListProvider);
  }

  Future<void> deleteCategory(int id) async {
    final db = ref.read(databaseServiceProvider).isar;
    
    await db.writeTxn(() async {
      final category = await db.collection<MachineryCategory>().get(id);
      if (category != null) {
        category.isDeleted = true;
        category.isSynced = false;
        category.updatedAt = DateTime.now();
        category.version += 1;
        await db.collection<MachineryCategory>().put(category);
        
        final syncQueue = SyncQueue()
          ..uuid = const Uuid().v4()
          ..entityType = 'MachineryCategory'
          ..entityId = category.id
          ..entityUuid = category.uuid
          ..operation = 'Delete'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
          
        await db.syncQueues.put(syncQueue);
      }
    });

    try {
      ref.read(syncManagerProvider).triggerUpload();
    } catch (_) {}

    ref.invalidate(machineryCategoryListProvider);
  }
}
