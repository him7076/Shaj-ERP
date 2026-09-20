import 'package:business_sahaj_erp/data/local/collections/fixed_asset_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_transaction_collection.dart';

abstract class FixedAssetRepository {
  Future<void> purchaseAsset(FixedAsset asset, FixedAssetTransaction transaction);
  Future<void> depreciateAsset(FixedAsset asset, FixedAssetTransaction transaction);
  Future<void> sellAsset(FixedAsset asset, FixedAssetTransaction transaction);
  Future<List<FixedAsset>> getAllAssets();
  Future<List<FixedAssetTransaction>> getTransactionsForAsset(int assetId);
}
