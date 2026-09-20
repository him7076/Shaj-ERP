import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/domain/repositories/fixed_asset_repository.dart';
import 'package:business_sahaj_erp/data/repositories/fixed_asset_repository_impl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_transaction_collection.dart';

final fixedAssetRepositoryProvider = Provider<FixedAssetRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return FixedAssetRepositoryImpl(isar);
});

final fixedAssetsProvider = FutureProvider<List<FixedAsset>>((ref) async {
  final repo = ref.watch(fixedAssetRepositoryProvider);
  return repo.getAllAssets();
});

final faTransactionsProvider = FutureProvider.family<List<FixedAssetTransaction>, int>((ref, assetId) async {
  final repo = ref.watch(fixedAssetRepositoryProvider);
  return repo.getTransactionsForAsset(assetId);
});
