import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import 'isar_model.dart';

part 'machinery_collection.g.dart';

@collection
class Machinery implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid = const Uuid().v4();

  @Index(type: IndexType.value)
  String? partyUuid;

  @Index(type: IndexType.value)
  String? machineName;

  String? brandName;
  String? modelNumber;
  String? serialNumber;
  String? description;
  List<String>? photos;
  String? googlePhotosLink;

  int? serviceIntervalMonths;
  int? serviceIntervalDays;

  DateTime? lastServiceDate;
  DateTime? nextServiceDate;

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
