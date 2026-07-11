import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'user_collection.g.dart';

@collection
class User implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  String? name;
  String? email;
  
  // Roles: Owner, Staff, Salesman
  String? role;

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
