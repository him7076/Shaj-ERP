import 'package:isar/isar.dart';

abstract class IsarModel {
  Id get id;
  set id(Id value);

  String? get uuid;
  set uuid(String? value);

  DateTime get createdAt;
  set createdAt(DateTime value);

  DateTime get updatedAt;
  set updatedAt(DateTime value);

  bool get isDeleted;
  set isDeleted(bool value);

  bool get isSynced;
  set isSynced(bool value);

  int get version;
  set version(int value);
}
