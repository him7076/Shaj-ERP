import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'task_collection.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? uuid = const Uuid().v4();

  String? title;
  String? description;
  String? status; // e.g., 'Todo', 'In Progress', 'Done'
  String? priority; // e.g., 'Low', 'Medium', 'High'
  
  DateTime? dueDate;
  DateTime? completedAt;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  bool isDeleted = false;
  bool isSynced = false;
  int version = 1;
}
