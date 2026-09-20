import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/task_repository.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';

class TaskRepositoryImpl extends BaseIsarRepository<Task> implements TaskRepository {
  TaskRepositoryImpl(Isar isar) : super(isar, 'Task');

  @override
  Future<List<Task>> getByStatus(String status) async {
    return await _isar.tasks.filter()
      .isDeletedEqualTo(false)
      .statusEqualTo(status)
      .sortByCreatedAtDesc()
      .findAll();
  }
}
