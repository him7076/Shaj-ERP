import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/purchase_repository.dart';
import 'package:business_sahaj_erp/data/repositories/purchase_repository_impl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PurchaseRepositoryImpl(dbService.isar);
});

final purchaseSearchQueryProvider = StateProvider<String>((ref) => '');

final purchaseListProvider = FutureProvider<List<Purchase>>((ref) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  final query = ref.watch(purchaseSearchQueryProvider);
  
  if (query.trim().isEmpty) {
    return await repo.getAll();
  } else {
    return await repo.searchPurchases(query);
  }
});

class PurchaseNotifier extends StateNotifier<AsyncValue<void>> {
  final PurchaseRepository _repository;
  final Ref _ref;

  PurchaseNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> savePurchase(Purchase purchase, List<PurchaseItem> items) async {
    state = const AsyncValue.loading();
    try {
      await _repository.savePurchase(purchase, items);
      state = const AsyncValue.data(null);
      // Invalidate purchase list to refresh UI
      _ref.invalidate(purchaseListProvider);
      return true;
    } catch (e, stack) {
      logger.error('Failed to save purchase bill', e, stack);
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deletePurchase(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(purchaseListProvider);
      return true;
    } catch (e, stack) {
      logger.error('Failed to delete purchase bill', e, stack);
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final purchaseNotifierProvider = StateNotifierProvider<PurchaseNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(purchaseRepositoryProvider);
  return PurchaseNotifier(repo, ref);
});
