import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'stock_adjustment_collection.g.dart';

@collection
class StockAdjustment implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index()
  String? itemUuid;

  int? itemId;
  String? itemName;

  String? adjustmentType; // 'Add' or 'Reduce'
  double? quantity;
  String? unit; // Primary or Secondary unit (e.g. Pcs, Box, Kg)
  double? ratePerUnit;
  double? totalValue; // Calculated as (quantity ?? 0.0) * (ratePerUnit ?? 0.0)
  DateTime? adjustmentDate;
  String? reason;
  String? notes;

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
