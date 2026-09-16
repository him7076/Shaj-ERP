import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class POSProductGrid extends ConsumerStatefulWidget {
  const POSProductGrid({Key? key}) : super(key: key);

  @override
  ConsumerState<POSProductGrid> createState() => _POSProductGridState();
}

class _POSProductGridState extends ConsumerState<POSProductGrid> {
  Category? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final itemsAsync = ref.watch(itemsListProvider); // we'll use all items and filter locally to avoid refetching

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Filter Row
        SizedBox(
          height: 60,
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading categories')),
          ),
        ),
        const SizedBox(height: 8),
        
        // Items Grid
        Expanded(
          child: itemsAsync.when(
            data: (allItems) {
              final items = _selectedCategory == null 
                  ? allItems 
                  : allItems.where((i) => i.category.value?.id == _selectedCategory!.id).toList();

              if (items.isEmpty) {
                return Center(child: Text('DEBUG: allItems length is ${allItems.length}. items length is ${items.length}. _selectedCategory is ${_selectedCategory?.id}.'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(items[index], theme);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error loading items: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Category? category, String label, ThemeData theme) {
    final isSelected = _selectedCategory?.id == category?.id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildProductCard(Item item, ThemeData theme) {
    final stock = item.currentStock ?? 0.0;
    final price = item.sellRate ?? 0.0;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        ref.read(invoiceCartProvider.notifier).addItem(item);
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder for image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: item.imagePaths != null && item.imagePaths!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(item.imagePaths!.first.split(',').last),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => _buildPlaceholderIcon(item, theme),
                          ),
                        )
                      : _buildPlaceholderIcon(item, theme),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.itemName ?? 'Unnamed',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(Item item, ThemeData theme) {
    return Center(
      child: Icon(
        item.isBundle ? Icons.extension_rounded : Icons.fastfood_rounded,
        size: 40,
        color: item.isBundle ? Colors.orange : theme.colorScheme.primary.withOpacity(0.5),
      ),
    );
  }
}



