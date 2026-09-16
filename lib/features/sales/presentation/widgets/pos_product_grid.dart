import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';

class POSProductGrid extends ConsumerStatefulWidget {
  const POSProductGrid({Key? key}) : super(key: key);

  @override
  ConsumerState<POSProductGrid> createState() => _POSProductGridState();
}

class _POSProductGridState extends ConsumerState<POSProductGrid> {
  Category? _selectedCategory;
  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  bool _isLoading = true;
  String? _errorMsg;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllItems() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final isar = ref.read(isarProvider);
      final items = await isar.items.filter().isDeletedEqualTo(false).findAll();
      // Load category links for each item (needed for filtering)
      for (var item in items) {
        try { await item.category.load(); } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _allItems = items;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'Error loading items: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    List<Item> result = _allItems;

    // Category filter
    if (_selectedCategory != null) {
      result = result.where((item) {
        return item.category.value?.id == _selectedCategory!.id;
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((item) {
        final name = (item.itemName ?? '').toLowerCase();
        final code = (item.itemCode ?? '').toLowerCase();
        final barcode = (item.barcode ?? '').toLowerCase();
        return name.contains(q) || code.contains(q) || barcode.contains(q);
      }).toList();
    }

    _filteredItems = result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilter();
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
                _applyFilter();
              });
            },
          ),
        ),

        // Category Filter Row
        SizedBox(
          height: 56,
          child: categoriesAsync.when(
            data: (categories) {
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _buildCategoryChip(null, 'All Items', theme),
                  ...categories.map((c) => _buildCategoryChip(c, c.categoryName ?? 'Unnamed', theme)),
                ],
              );
            },
            loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(fontSize: 11))),
          ),
        ),

        // Items Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMsg != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            onPressed: _fetchAllItems,
                          ),
                        ],
                      ),
                    )
                  : _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.outline),
                              const SizedBox(height: 8),
                              Text(
                                _selectedCategory != null
                                    ? 'No items in "${_selectedCategory!.categoryName}"'
                                    : 'No items found.',
                                style: TextStyle(color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchAllItems,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 180,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(_filteredItems[index], theme);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Category? category, String label, ThemeData theme) {
    final isSelected = (_selectedCategory == null && category == null) ||
        (_selectedCategory != null && category != null && _selectedCategory!.id == category.id);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        )),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
            _applyFilter();
          });
        },
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildProductCard(Item item, ThemeData theme) {
    final stock = item.currentStock ?? 0.0;
    final price = item.sellRate ?? 0.0;
    final isDark = theme.brightness == Brightness.dark;
    final isOutOfStock = stock <= 0;

    return InkWell(
      onTap: () {
        ref.read(invoiceCartProvider.notifier).addItem(item);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.itemName ?? "Item"} added to cart'),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 60, left: 20, right: 20),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildItemImage(item, theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    item.itemName ?? 'Unnamed',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  // Price + Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${stock.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bundle badge
            if (item.isBundle)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Bundle', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(Item item, ThemeData theme) {
    if (item.imagePaths != null && item.imagePaths!.isNotEmpty) {
      try {
        final raw = item.imagePaths!.first;
        // Handle base64 data URI (e.g. "data:image/png;base64,iVBOR...") or plain base64
        final base64Str = raw.contains(',') ? raw.split(',').last : raw;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(item, theme),
        );
      } catch (_) {
        return _buildPlaceholderIcon(item, theme);
      }
    }
    return _buildPlaceholderIcon(item, theme);
  }

  Widget _buildPlaceholderIcon(Item item, ThemeData theme) {
    return Center(
      child: Icon(
        item.isBundle ? Icons.extension_rounded : Icons.fastfood_rounded,
        size: 36,
        color: item.isBundle ? Colors.orange : theme.colorScheme.primary.withOpacity(0.4),
      ),
    );
  }
}
