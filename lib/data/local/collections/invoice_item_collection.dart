import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'item_collection.dart';
import 'invoice_collection.dart';

part 'invoice_item_collection.g.dart';

@collection
class InvoiceItem implements IsarModel {
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
  double? rate;
  double? discount; // discount amount

  double? taxableAmount;
  double? gstRate;
  double? gstAmount;
  double? totalAmount; // maps to amount line total

  // Isar Links
  final invoice = IsarLink<Invoice>();
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
