import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import 'isar_model.dart';

part 'task_collection.g.dart';

@collection
class Task implements IsarModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? uuid = const Uuid().v4();

  String? title;
  String? description;
  String? status; // e.g., 'Todo', 'In Progress', 'Done'
  String? priority; // e.g., 'Low', 'Medium', 'High'
  
  DateTime? dueDate;
  DateTime? completedAt;

  @override
  DateTime createdAt = DateTime.now();
  @override
  DateTime updatedAt = DateTime.now();

  @override
  bool isDeleted = false;
  @override
  bool isSynced = false;
  @override
  int version = 1;
}
