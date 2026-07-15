import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'item_collection.dart';
import 'purchase_collection.dart';

part 'purchase_item_collection.g.dart';

@collection
class PurchaseItem implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  int? itemId;
  String? itemName;
  String? hsnCode;

  double? quantity;
  double? rate;
  double? discount;

  double? taxableAmount;
  double? gstRate;
  double? gstAmount;
  double? totalAmount;

  // Isar Links
  final purchase = IsarLink<Purchase>();
  final item = IsarLink<Item>();

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
