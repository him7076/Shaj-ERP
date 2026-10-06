import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'fixed_asset_collection.g.dart';

@collection
class FixedAssetItem implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? assetCode;

  @Index()
  String? assetName;

  String? assetType; // Furniture, Machinery, Vehicle, Computer, Building, Land, Office Equipment, etc.
  String? description;

  @Index()
  String? hsnCode;

  bool gstApplicable = true;
  double? gstRate;

  double? purchasePrice;
  double? salvageValue;
  double? depreciationRate; // e.g. 10.0 for 10%
  String? depreciationMethod; // Straight Line, WDV

  String? serialNumber;
  String? location;
  String? unit;

  double? quantity;
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
