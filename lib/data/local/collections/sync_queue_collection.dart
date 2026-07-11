import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'sync_queue_collection.g.dart';

@collection
class SyncQueue implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  String? entityType; // E.g. 'Party', 'Item', 'Order', 'Invoice'
  
  @Index()
  int? entityId; // Local Isar ID of the entity
  
  @Index()
  String? entityUuid; // Global UUID of the entity

  // Operations: Insert, Update, Delete
  String? operation;

  int retryCount = 0;
  DateTime? lastAttempt;
  String? lastError;

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
