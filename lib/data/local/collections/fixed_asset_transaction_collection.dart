import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'fixed_asset_collection.dart';
part 'fixed_asset_transaction_collection.g.dart';

@collection
class FixedAssetTransaction implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(type: IndexType.value)
  int? assetId;
  String? assetUuid;

  DateTime? transactionDate;
  
  String? transactionType; // Purchase, Depreciation, Disposal, Revaluation
  String? referenceNumber;
  String? remarks;

  double amount = 0.0;
  
  // Isar Links
  final asset = IsarLink<FixedAsset>();
  String? debitAccountName;
  String? creditAccountName;

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
