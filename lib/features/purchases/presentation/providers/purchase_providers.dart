import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/purchase_repository.dart';
import 'package:business_sahaj_erp/data/repositories/purchase_repository_impl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return PurchaseRepositoryImpl(isar);
});

class PurchaseSearchFilter {
  final String query;
  final int limit;

  const PurchaseSearchFilter({
    this.query = '',
    this.limit = 50,
  });

  PurchaseSearchFilter copyWith({String? query, int? limit}) {
    return PurchaseSearchFilter(
      query: query ?? this.query,
      limit: limit ?? this.limit,
    );
  }
}

final purchaseSearchFilterProvider = StateProvider<PurchaseSearchFilter>((ref) => const PurchaseSearchFilter());

// Helper to build the base query for both list and totals
QueryBuilder<Purchase, Purchase, QAfterSortBy> _buildPurchaseQuery(Isar isar, PurchaseSearchFilter filter) {
  var qb = isar.purchases.filter().isDeletedEqualTo(false);
  
  if (filter.query.trim().isNotEmpty) {
    final q = filter.query.trim().toLowerCase();
    qb = qb.and().group((q2) => q2
      .purchaseNumberContains(q, caseSensitive: false)
      .or()
      .partyNameContains(q, caseSensitive: false)
      .or()
      .remarksContains(q, caseSensitive: false)
    );
  }
  
  return qb.sortByPurchaseDateDesc();
}

final purchaseListProvider = FutureProvider<List<Purchase>>((ref) async {
  final isar = ref.watch(isarProvider);
  final filter = ref.watch(purchaseSearchFilterProvider);
  
  final qb = _buildPurchaseQuery(isar, filter);
  return await qb.limit(filter.limit).findAll();
});

class PurchaseTotals {
  final double totalAmt;
  final double totalTax;
  const PurchaseTotals(this.totalAmt, this.totalTax);
}

final purchaseTotalsProvider = FutureProvider<PurchaseTotals>((ref) async {
  final isar = ref.watch(isarProvider);
  final filter = ref.watch(purchaseSearchFilterProvider);
  
  final qb = _buildPurchaseQuery(isar, filter);
  
  final grandTotals = await qb.grandTotalProperty().findAll();
  final taxTotals = await qb.totalGSTProperty().findAll();
  
  final totalAmt = grandTotals.whereType<double>().fold(0.0, (sum, val) => sum + val);
  final totalTax = taxTotals.whereType<double>().fold(0.0, (sum, val) => sum + val);
  
  return PurchaseTotals(totalAmt, totalTax);
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
