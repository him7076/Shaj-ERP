import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/task_repository.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements TaskRepository {
  final Isar _isar;

  TaskRepositoryImpl(this._isar);

  @override
  Future<List<Task>> getAll() async {
    return await _isar.tasks.filter().isDeletedEqualTo(false).sortByCreatedAtDesc().findAll();
  }

  @override
  Future<Task?> getById(int id) async {
    return await _isar.tasks.get(id);
  }

  @override
  Future<Task?> getByUuid(String uuid) async {
    return await _isar.tasks.filter().uuidEqualTo(uuid).findFirst();
  }

  @override
  Future<int> insert(Task task) async {
    if (task.uuid == null || task.uuid!.isEmpty) {
      task.uuid = const Uuid().v4();
    }
    task.createdAt = DateTime.now();
    task.updatedAt = DateTime.now();
    
    return await _isar.writeTxn(() async {
      return await _isar.tasks.put(task);
    });
  }

  @override
  Future<int> update(Task task) async {
    task.updatedAt = DateTime.now();
    task.isSynced = false;
    task.version += 1;
    
    return await _isar.writeTxn(() async {
      return await _isar.tasks.put(task);
    });
  }

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(id);
      if (task != null) {
        task.isDeleted = true;
        task.isSynced = false;
        task.updatedAt = DateTime.now();
        task.version += 1;
        await _isar.tasks.put(task);
      }
    });
  }

  @override
  Future<List<Task>> getByStatus(String status) async {
    return await _isar.tasks.filter()
      .isDeletedEqualTo(false)
      .statusEqualTo(status)
      .sortByCreatedAtDesc()
      .findAll();
  }
}
