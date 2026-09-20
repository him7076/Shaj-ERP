import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';

import 'package:business_sahaj_erp/domain/repositories/base_repository.dart';

abstract class TaskRepository extends BaseRepository<Task> {
  Future<List<Task>> getByStatus(String status);
}
