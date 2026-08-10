import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'expense_item_collection.g.dart';

@collection
class ExpenseItem implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index()
  String? itemName;

  double? defaultRate;

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
