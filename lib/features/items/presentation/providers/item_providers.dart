import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/item_repository.dart';
import 'package:business_sahaj_erp/domain/repositories/category_repository.dart';
import 'package:business_sahaj_erp/domain/repositories/brand_repository.dart';
import 'package:business_sahaj_erp/domain/repositories/unit_repository.dart';
import 'package:business_sahaj_erp/data/repositories/category_repository_impl.dart';
import 'package:business_sahaj_erp/data/repositories/brand_repository_impl.dart';
import 'package:business_sahaj_erp/data/repositories/unit_repository_impl.dart';
import 'package:business_sahaj_erp/core/services/barcode_service.dart';
import 'package:business_sahaj_erp/core/services/hsn_service.dart';
import 'package:business_sahaj_erp/core/services/image_service.dart';
import 'package:business_sahaj_erp/core/services/stock_service.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

// Service Providers
final barcodeServiceProvider = Provider<BarcodeService>((ref) {
  return BarcodeService();
});

final hsnServiceProvider = Provider<HsnService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HsnService(prefs);
});

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

final stockServiceProvider = Provider<StockService>((ref) {
  final itemRepo = ref.watch(itemRepositoryProvider);
  return StockService(itemRepo);
});

// Category, Brand, Unit Repository Providers
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return CategoryRepositoryImpl(isar);
});

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return BrandRepositoryImpl(isar);
});

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return UnitRepositoryImpl(isar);
});

// Category, Brand, Unit List Providers (helper for dropdowns/filters)
final categoriesListProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getAll();
});

final brandsListProvider = FutureProvider<List<Brand>>((ref) async {
  final repo = ref.watch(brandRepositoryProvider);
  return await repo.getAll();
});

final unitsListProvider = FutureProvider<List<Unit>>((ref) async {
  final repo = ref.watch(unitRepositoryProvider);
  return await repo.getAll();
});

final itemsListProvider = FutureProvider<List<Item>>((ref) async {
  final repo = ref.watch(itemRepositoryProvider);
  return await repo.getAll();
});

// Search & Filter State
class ItemSearchFilter {
  final String query;
  final int? categoryId;
  final int? brandId;
  final String stockStatus; // 'All', 'In Stock', 'Low Stock', 'Out of Stock'
  final double? gstRate;
  final String sortBy; // 'Name A-Z', 'Name Z-A', 'Price L-H', 'Price H-L', 'Stock L-H', 'Stock H-L'
  final int limit;

  const ItemSearchFilter({
    this.query = '',
    this.categoryId,
    this.brandId,
    this.stockStatus = 'All',
    this.gstRate,
    this.sortBy = 'Name A-Z',
    this.limit = 50,
  });

  ItemSearchFilter copyWith({
    String? query,
    int? categoryId,
    int? brandId,
    String? stockStatus,
    double? gstRate,
    String? sortBy,
    int? limit,
  }) {
    return ItemSearchFilter(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      stockStatus: stockStatus ?? this.stockStatus,
      gstRate: gstRate ?? this.gstRate,
      sortBy: sortBy ?? this.sortBy,
      limit: limit ?? this.limit,
    );
  }
}

final itemSearchProvider = StateProvider<ItemSearchFilter>((ref) => const ItemSearchFilter());

// Filtered and Sorted Items Provider (The computed list search engine)
final filteredItemsProvider = FutureProvider<List<Item>>((ref) async {
  final filter = ref.watch(itemSearchProvider);
  final itemRepo = ref.watch(itemRepositoryProvider);
  final stockService = ref.watch(stockServiceProvider);

  final isar = ref.watch(isarProvider);

  dynamic queryBuilder = isar.items.filter().isDeletedEqualTo(false);
  
  if (filter.query.trim().isNotEmpty) {
      final cleanQuery = filter.query.trim();
      queryBuilder = queryBuilder.and().group((q) => q
          .itemNameContains(cleanQuery, caseSensitive: false)
          .or()
          .itemCodeContains(cleanQuery, caseSensitive: false)
          .or()
          .hsnCodeContains(cleanQuery, caseSensitive: false)
          .or()
          .barcodeContains(cleanQuery, caseSensitive: false)
          .or()
          .skuContains(cleanQuery, caseSensitive: false)
          .or()
          .skuCodeContains(cleanQuery, caseSensitive: false)
      );
  }

  if (filter.categoryId != null) {
      queryBuilder = queryBuilder.and().category((q) => q.idEqualTo(filter.categoryId!));
  }

  if (filter.brandId != null) {
      queryBuilder = queryBuilder.and().brand((q) => q.idEqualTo(filter.brandId!));
  }
  
  if (filter.gstRate != null) {
      queryBuilder = queryBuilder.and().gstRateEqualTo(filter.gstRate);
  }
  
  // Sort
  switch (filter.sortBy) {
    case 'Name A-Z':
      queryBuilder = queryBuilder.sortByItemName();
      break;
    case 'Name Z-A':
      queryBuilder = queryBuilder.sortByItemNameDesc();
      break;
    case 'Price L-H':
      queryBuilder = queryBuilder.sortBySellRate();
      break;
    case 'Price H-L':
      queryBuilder = queryBuilder.sortBySellRateDesc();
      break;
    case 'Stock L-H':
      queryBuilder = queryBuilder.sortByCurrentStock();
      break;
    case 'Stock H-L':
      queryBuilder = queryBuilder.sortByCurrentStockDesc();
      break;
  }

  // If there's no dart-side filtering, push pagination to DB
  var items = <Item>[];
  if (filter.stockStatus == 'All') {
    items = await queryBuilder.limit(filter.limit).findAll();
  } else {
    // Cannot push limit to DB because dart-side filtering will drop items, breaking pagination sizes
    items = await queryBuilder.findAll();
    
    // Filter Stock Status in Dart
    switch (filter.stockStatus) {
      case 'In Stock':
        items = items.where((item) => (item.currentStock ?? 0.0) > (item.reorderLevel ?? 0.0)).toList();
        break;
      case 'Low Stock':
        items = items.where((item) => stockService.isLowStock(item) && !stockService.isOutOfStock(item)).toList();
        break;
      case 'Out of Stock':
        items = items.where((item) => stockService.isOutOfStock(item)).toList();
        break;
    }
    
    // Apply limit after filtering
    if (items.length > filter.limit) {
      items = items.sublist(0, filter.limit);
    }
  }

  return items;
});

// Low Stock Alert Provider (Identifies products that are running low on stock)
final lowStockAlertProvider = FutureProvider<List<Item>>((ref) async {
  final itemRepo = ref.watch(itemRepositoryProvider);
  final stockService = ref.watch(stockServiceProvider);
  final items = await itemRepo.getAll();
  return stockService.getLowStockItems(items);
});

// Temporary Order Cart State Notifier (Simulates card count state matching Amazon style trigger +/-)
class ItemCartNotifier extends StateNotifier<Map<String, int>> {
  ItemCartNotifier() : super({});

  void setQuantity(String itemUuid, int quantity) {
    if (quantity <= 0) {
      remove(itemUuid);
    } else {
      state = {...state, itemUuid: quantity};
    }
  }

  void increment(String itemUuid) {
    final current = state[itemUuid] ?? 0;
    state = {...state, itemUuid: current + 1};
  }

  void decrement(String itemUuid) {
    final current = state[itemUuid] ?? 0;
    if (current <= 1) {
      remove(itemUuid);
    } else {
      state = {...state, itemUuid: current - 1};
    }
  }

  void remove(String itemUuid) {
    final newState = Map<String, int>.from(state);
    newState.remove(itemUuid);
    state = newState;
  }

  void clear() {
    state = {};
  }
}

final itemCartNotifierProvider = StateNotifierProvider<ItemCartNotifier, Map<String, int>>((ref) {
  return ItemCartNotifier();
});

// Pre-computed weighted average buy rate cache — built ONCE, used by all item cards instantly
// Eliminates per-card FutureBuilder N+1 full-table-scan queries
final itemBuyRateCacheProvider = FutureProvider<Map<String, double>>((ref) async {
  final isar = ref.watch(isarProvider);
  
  final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

  // Limit to last 6 months to avoid scanning the entire historical table
  final purchaseItems = await isar.collection<PurchaseItem>().filter()
      .isDeletedEqualTo(false)
      .and()
      .createdAtGreaterThan(sixMonthsAgo)
      .findAll();

  final Map<String, double> totalAmtMap = {};
  final Map<String, double> totalQtyMap = {};

  for (var pi in purchaseItems) {
    final key = pi.itemName?.trim().toLowerCase() ?? '';
    if (key.isEmpty) continue;
    final q = pi.quantity ?? 0.0;
    final r = pi.rate ?? 0.0;
    if (q > 0) {
      totalAmtMap[key] = (totalAmtMap[key] ?? 0.0) + (q * r);
      totalQtyMap[key] = (totalQtyMap[key] ?? 0.0) + q;
    }
  }

  final Map<String, double> rateMap = {};
  for (var key in totalAmtMap.keys) {
    final qty = totalQtyMap[key] ?? 0.0;
    if (qty > 0) {
      rateMap[key] = totalAmtMap[key]! / qty;
    }
  }

  return rateMap;
});
