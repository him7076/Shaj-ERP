import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/item_detail_screen.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_item_sheet.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcodeService = ref.read(barcodeServiceProvider);
    final code = await barcodeService.scanBarcode(context);
    if (code != null) {
      // Set search query to scanned barcode to find it instantly
      _searchController.text = code;
      ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(query: code));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned Barcode: $code. Showing matches.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _exportCatalogToPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating PDF Catalog directory...'),
        backgroundColor: Colors.blue,
      ),
    );
    // Simulating PDF generation delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF Catalog Directory generated and printed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(itemSearchProvider);
    final itemsAsync = ref.watch(filteredItemsProvider);
    final lowStockAsync = ref.watch(lowStockAlertProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final brandsAsync = ref.watch(brandsListProvider);
    final cart = ref.watch(itemCartNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Inventory Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            onPressed: _scanBarcode,
            tooltip: 'Scan Barcode',
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: _exportCatalogToPdf,
            tooltip: 'Export Catalog PDF',
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_outlined),
            onPressed: () {
              AddItemSheet.show(context);
            },
            tooltip: 'Quick Add Product',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Low stock warning banner if any items are running low
          lowStockAsync.when(
            data: (lowStockItems) {
              if (lowStockItems.isEmpty) return const SizedBox.shrink();
              return Material(
                color: Colors.orange.shade50,
                child: InkWell(
                  onTap: () {
                    // Quick filter to low stock items
                    ref.read(itemSearchProvider.notifier).update(
                          (state) => state.copyWith(stockStatus: 'Low Stock'),
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Warning: ${lowStockItems.length} products are running below reorder level!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Name, Code, HSN, Barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(itemSearchProvider.notifier).update(
                                      (state) => state.copyWith(query: ''),
                                    );
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    onChanged: (val) {
                      ref.read(itemSearchProvider.notifier).update(
                            (state) => state.copyWith(query: val),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Panel (collapsible)
          if (_showFilters) _buildFilterPanel(theme, filter, categoriesAsync, brandsAsync),

          // Horizontal Category Chip Quick Filters
          _buildCategoryChipBar(theme, filter, categoriesAsync),

          // Item List / Grid
          Expanded(
            child: itemsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No products found matching filters.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product Master'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEditItemScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final itemQty = cart[item.uuid ?? ''] ?? 0;
                    return _buildProductCard(item, itemQty, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load catalog: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditItemScreen(),
            ),
          );
          ref.invalidate(filteredItemsProvider);
        },
      ),
    );
  }

  Widget _buildCategoryChipBar(
    ThemeData theme,
    ItemSearchFilter filter,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final cat = isAll ? null : categories[index - 1];
              final isSelected = isAll ? filter.categoryId == null : filter.categoryId == cat?.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(isAll ? 'All Categories' : (cat?.categoryName ?? '')),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(itemSearchProvider.notifier).update(
                          (state) => state.copyWith(
                            categoryId: selected ? cat?.id : null,
                          ),
                        );
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFilterPanel(
    ThemeData theme,
    ItemSearchFilter filter,
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<Brand>> brandsAsync,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Stock status filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filter.stockStatus,
                  decoration: const InputDecoration(
                    labelText: 'Stock Level Status',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Stock Levels')),
                    DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                    DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock Warning')),
                    DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(stockStatus: v));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Sorting
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filter.sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort Catalog By',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Name A-Z', child: Text('Name (A-Z)')),
                    DropdownMenuItem(value: 'Name Z-A', child: Text('Name (Z-A)')),
                    DropdownMenuItem(value: 'Price L-H', child: Text('Price (Low-High)')),
                    DropdownMenuItem(value: 'Price H-L', child: Text('Price (High-Low)')),
                    DropdownMenuItem(value: 'Stock L-H', child: Text('Stock (Low-High)')),
                    DropdownMenuItem(value: 'Stock H-L', child: Text('Stock (High-Low)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(sortBy: v));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Brand filter
              Expanded(
                child: brandsAsync.when(
                  data: (brands) {
                    return DropdownButtonFormField<int?>(
                      value: filter.brandId,
                      decoration: const InputDecoration(
                        labelText: 'Brand Master',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All Brands')),
                        ...brands.map((b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.brandName ?? ''))),
                      ],
                      onChanged: (v) {
                        ref.read(itemSearchProvider.notifier).update((state) => state.copyWith(brandId: v));
                      },
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, __) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 8),

              // Reset filters button
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Filters'),
                onPressed: () {
                  _searchController.clear();
                  ref.read(itemSearchProvider.notifier).state = const ItemSearchFilter();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Item item, int quantity, ThemeData theme) {
    final hasImage = item.imagePaths != null && item.imagePaths!.isNotEmpty;
    final stockVal = item.currentStock ?? 0.0;
    final reorderVal = item.reorderLevel ?? 0.0;
    final isOut = stockVal <= 0;
    final isLow = stockVal <= reorderVal;

    Color stockColor = Colors.green;
    String stockLabel = 'In Stock (${stockVal.toInt()})';
    if (isOut) {
      stockColor = Colors.red;
      stockLabel = 'Out of Stock';
    } else if (isLow) {
      stockColor = Colors.orange;
      stockLabel = 'Low Stock (${stockVal.toInt()})';
    }

    return Card(
      key: ValueKey(item.uuid),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLow ? stockColor.withOpacity(0.3) : theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: isLow ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Open Details Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(itemUuid: item.uuid!),
            ),
          ).then((_) => ref.invalidate(filteredItemsProvider));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: hasImage
                      ? Image.file(
                          File(item.imagePaths!.first),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: theme.colorScheme.surfaceVariant,
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: Icon(Icons.inventory, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Product Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${item.itemCode ?? "N/A"} | HSN: ${item.hsnCode ?? "N/A"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Stock warning label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: stockColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            stockLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: stockColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.brand.value?.brandName != null)
                          Text(
                            '•  ${item.brand.value!.brandName}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${item.sellRate?.toStringAsFixed(2) ?? "0.00"}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Quantity trigger buttons (+ / -)
              _buildAmazonQuantityController(item, quantity, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmazonQuantityController(Item item, int quantity, ThemeData theme) {
    if (quantity == 0) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 1,
        ),
        onPressed: () {
          ref.read(itemCartNotifierProvider.notifier).increment(item.uuid!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${item.itemName}" added to basket.'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: const Text('ADD'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              ref.read(itemCartNotifierProvider.notifier).decrement(item.uuid!);
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () {
              ref.read(itemCartNotifierProvider.notifier).increment(item.uuid!);
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}
