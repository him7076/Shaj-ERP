import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import 'isar_model.dart';

part 'machinery_category_collection.g.dart';

@collection
class MachineryCategory implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid = const Uuid().v4();

  @Index(type: IndexType.value)
  String? categoryName;

  String? description;

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
