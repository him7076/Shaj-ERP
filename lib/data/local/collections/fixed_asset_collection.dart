import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'account_collection.dart';

part 'fixed_asset_collection.g.dart';

@collection
class FixedAsset implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(type: IndexType.value)
  String? assetName;

  String? assetType; // e.g. Machinery, Vehicles, Computers
  String? description;

  DateTime? purchaseDate;
  
  double purchaseCost = 0.0;
  double accumulatedDepreciation = 0.0;
  double bookValue = 0.0;

  double depreciationRate = 0.0; // Percentage
  String? depreciationMethod; // Straight Line, WDV
  
  String? status; // Active, Disposed, Sold

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
