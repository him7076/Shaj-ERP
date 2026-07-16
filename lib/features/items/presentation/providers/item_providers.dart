import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
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

  const ItemSearchFilter({
    this.query = '',
    this.categoryId,
    this.brandId,
    this.stockStatus = 'All',
    this.gstRate,
    this.sortBy = 'Name A-Z',
  });

  ItemSearchFilter copyWith({
    String? query,
    int? categoryId,
    int? brandId,
    String? stockStatus,
    double? gstRate,
    String? sortBy,
  }) {
    return ItemSearchFilter(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      stockStatus: stockStatus ?? this.stockStatus,
      gstRate: gstRate ?? this.gstRate,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final itemSearchProvider = StateProvider<ItemSearchFilter>((ref) => const ItemSearchFilter());

// Filtered and Sorted Items Provider (The computed list search engine)
final filteredItemsProvider = FutureProvider<List<Item>>((ref) async {
  final filter = ref.watch(itemSearchProvider);
  final itemRepo = ref.watch(itemRepositoryProvider);
  final stockService = ref.watch(stockServiceProvider);

  // Search items in DB
  var items = await itemRepo.searchItems(filter.query);

  // Load links asynchronously for UI display
  for (var item in items) {
    try { await item.category.load(); } catch (_) {}
    try { await item.brand.load(); } catch (_) {}
    try { await item.unit.load(); } catch (_) {}
  }

  // Filter Category
  if (filter.categoryId != null) {
    items = items.where((item) => item.category.value?.id == filter.categoryId).toList();
  }

  // Filter Brand
  if (filter.brandId != null) {
    items = items.where((item) => item.brand.value?.id == filter.brandId).toList();
  }

  // Filter GST
  if (filter.gstRate != null) {
    items = items.where((item) => item.gstRate == filter.gstRate).toList();
  }

  // Filter Stock Status
  if (filter.stockStatus != 'All') {
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
  }

  // Sort
  switch (filter.sortBy) {
    case 'Name A-Z':
      items.sort((a, b) => (a.itemName ?? '').compareTo(b.itemName ?? ''));
      break;
    case 'Name Z-A':
      items.sort((a, b) => (b.itemName ?? '').compareTo(a.itemName ?? ''));
      break;
    case 'Price L-H':
      items.sort((a, b) => (a.sellRate ?? 0.0).compareTo(b.sellRate ?? 0.0));
      break;
    case 'Price H-L':
      items.sort((a, b) => (b.sellRate ?? 0.0).compareTo(a.sellRate ?? 0.0));
      break;
    case 'Stock L-H':
      items.sort((a, b) => (a.currentStock ?? 0.0).compareTo(b.currentStock ?? 0.0));
      break;
    case 'Stock H-L':
      items.sort((a, b) => (b.currentStock ?? 0.0).compareTo(a.currentStock ?? 0.0));
      break;
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
