import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'item_collection.dart';
import 'order_collection.dart';

part 'order_item_collection.g.dart';

@collection
class OrderItem implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  int? itemId;
  String? itemName;
  String? hsnCode;

  double? quantity;
  double? freeQuantity;
  String? unit;
  double? rate;

  double? discountPercent;
  double? discountAmount;
  double? taxableAmount;
  double? gstPercent;
  double? gstAmount;
  double? totalAmount; // Line total totalAmount

  // Isar Links
  final order = IsarLink<Order>();
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
