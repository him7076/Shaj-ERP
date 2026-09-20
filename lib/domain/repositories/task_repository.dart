import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';

abstract class TaskRepository {
  Future<List<Task>> getAll();
  Future<Task?> getById(int id);
  Future<Task?> getByUuid(String uuid);
  Future<int> insert(Task task);
  Future<int> update(Task task);
  Future<void> delete(int id);
  Future<List<Task>> getByStatus(String status);
}
