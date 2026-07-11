import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'settings_collection.g.dart';

@collection
class Settings implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  String? companyName;
  String? companyGST;
  String? companyAddress;
  String? companyPhone;
  String? companyEmail;
  String? logoPath;
  String? themeMode;

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
