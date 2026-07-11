import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'unit_collection.g.dart';

@collection
class Unit implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  String? unitName;
  String? shortName; // E.g. PCS, KG, LTR

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
