import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class POSProductGrid extends ConsumerStatefulWidget {
  const POSProductGrid({Key? key}) : super(key: key);

  @override
  ConsumerState<POSProductGrid> createState() => _POSProductGridState();
}

class _POSProductGridState extends ConsumerState<POSProductGrid> {
  int? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<int, double> _itemQuantities = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final itemsAsync = ref.watch(itemsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items by name, code...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
          child: itemsAsync.when(
            data: (allItems) {
              // Filter by category using the item's category link value
              List<Item> items = allItems;

              if (_selectedCategoryId != null) {
                items = items.where((i) {
                  final catId = i.category.value?.id;
                  return catId == _selectedCategoryId;
                }).toList();
              }

              // Filter by search query
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                items = items.where((i) {
                  final name = (i.itemName ?? '').toLowerCase();
                  final code = (i.itemCode ?? '').toLowerCase();
                  final barcode = (i.barcode ?? '').toLowerCase();
                  return name.contains(q) || code.contains(q) || barcode.contains(q);
                }).toList();
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: items.length + 1,
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return _buildCreateNewCard(theme, context);
                  }
                  return _buildProductCard(items[index], theme);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error loading items: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    onPressed: () => ref.invalidate(itemsListProvider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Category? category, String label, ThemeData theme) {
    final isSelected = (_selectedCategoryId == null && category == null) ||
        (_selectedCategoryId != null && category != null && _selectedCategoryId == category.id);
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
            _selectedCategoryId = category?.id;
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

    return Card(
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
                          color: stock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${stock.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stock > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Quantity Selector & Add Button
                  Row(
                    children: [
                      // Minus Button
                      InkWell(
                        onTap: () {
                          setState(() {
                            final current = _itemQuantities[item.id] ?? 1.0;
                            if (current > 1.0) {
                              _itemQuantities[item.id] = current - 1.0;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Manual Input
                      Expanded(
                        child: SizedBox(
                          height: 26,
                          child: TextFormField(
                            key: ValueKey('qty_${item.id}_${_itemQuantities[item.id] ?? 1.0}'),
                            initialValue: (_itemQuantities[item.id] ?? 1.0).toStringAsFixed(0),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                _itemQuantities[item.id] = parsed;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Plus Button
                      InkWell(
                        onTap: () {
                          setState(() {
                            final current = _itemQuantities[item.id] ?? 1.0;
                            _itemQuantities[item.id] = current + 1.0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.add, size: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Button
                      InkWell(
                        onTap: () {
                          final qty = _itemQuantities[item.id] ?? 1.0;
                          ref.read(invoiceCartProvider.notifier).addItem(item, qty: qty);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${qty.toInt()}x ${item.itemName ?? "Item"} added to cart'),
                              duration: const Duration(milliseconds: 800),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(bottom: 60, left: 20, right: 20),
                            ),
                          );
                          // Reset qty to 1 after adding
                          setState(() {
                            _itemQuantities.remove(item.id);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ADD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
      );
  }

  Widget _buildItemImage(Item item, ThemeData theme) {
    if (item.imagePaths != null && item.imagePaths!.isNotEmpty) {
      try {
        final raw = item.imagePaths!.first;
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

  Widget _buildCreateNewCard(ThemeData theme, BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 1),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditItemScreen(),
            ),
          );
          // After returning from AddEditItemScreen, we want to invalidate the items list
          // so the new item shows up.
          ref.invalidate(itemsListProvider);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Create New Item',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
