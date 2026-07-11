import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemUuid;

  const ItemDetailScreen({Key? key, required this.itemUuid}) : super(key: key);

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isLoading = false;
  Item? _item;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final fetchedItem = await repo.getByUuid(widget.itemUuid);
      if (fetchedItem != null) {
        await fetchedItem.category.load();
        await fetchedItem.brand.load();
        await fetchedItem.unit.load();
      }
      setState(() {
        _item = fetchedItem;
      });
    } catch (e) {
      logger.error('Failed to load item detail', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${_item?.itemName}"? This can be undone later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && _item != null) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(itemRepositoryProvider);
        await repo.delete(_item!.id);
        ref.invalidate(filteredItemsProvider);
        ref.invalidate(lowStockAlertProvider);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${_item?.itemName}" deleted.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        logger.error('Failed to delete item', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete product: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _adjustStockDialog() async {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    var isStockIn = true;
    final formKey = GlobalKey<FormState>();

    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: const Text('Adjust Inventory Stock'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stock In / Stock Out toggle
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Stock In (+)'),
                            icon: Icon(Icons.add),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Stock Out (-)'),
                            icon: Icon(Icons.remove),
                          ),
                        ],
                        selected: {isStockIn},
                        onSelectionChanged: (val) {
                          setDialogState(() {
                            isStockIn = val.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val <= 0) return 'Enter value > 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Adjustment',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. Purchase, Damage, Audit audit...',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true && _item != null) {
      setState(() => _isLoading = true);
      try {
        final stockService = ref.read(stockServiceProvider);
        final adjustment = double.parse(qtyController.text);
        final finalQty = isStockIn ? adjustment : -adjustment;
        
        await stockService.adjustStock(
          _item!,
          finalQty,
          reasonController.text.trim(),
        );

        // Reload data
        await _loadItem();
        ref.invalidate(filteredItemsProvider);
        ref.invalidate(lowStockAlertProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock levels adjusted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        logger.error('Failed to adjust stock', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Adjustment failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockService = ref.watch(stockServiceProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found.')),
      );
    }

    final item = _item!;
    final isLow = stockService.isLowStock(item);
    final isOut = stockService.isOutOfStock(item);
    final historyLogs = stockService.getStockHistory(item);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.itemName ?? 'Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              // Navigate to edit screen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditItemScreen(itemUuid: item.uuid),
                ),
              );
              _loadItem();
            },
            tooltip: 'Edit Product',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteItem,
            tooltip: 'Delete Product',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Carousel / Thumbnail Header
            _buildImageHeader(item, theme),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title, Code, & Stock Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName ?? '',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${item.itemCode ?? "N/A"} | SKU: ${item.sku ?? item.skuCode ?? "N/A"}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      _buildStockBadge(isOut, isLow, theme, item),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stock adjustment CTA card
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2, color: theme.colorScheme.primary, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Stock Level: ${item.currentStock ?? 0.0} ${item.unit.value?.shortName ?? "PCS"}',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Reorder Level: ${item.reorderLevel ?? 0.0} | Min: ${item.minimumStock ?? 0.0}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.swap_vert),
                            label: const Text('Adjust'),
                            onPressed: _adjustStockDialog,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pricing Info Table
                  _buildSectionTitle('Pricing & Taxation', theme),
                  const SizedBox(height: 12),
                  _buildDetailTable([
                    _DetailRow('Selling Price (Retail)', '₹${item.sellRate?.toStringAsFixed(2) ?? "0.00"}', isBold: true),
                    _DetailRow('Wholesale Price', '₹${item.wholesaleRate?.toStringAsFixed(2) ?? "N/A"}'),
                    _DetailRow('Min Selling Price', '₹${item.minimumSellingPrice?.toStringAsFixed(2) ?? "N/A"}'),
                    _DetailRow('MRP', '₹${item.mrp?.toStringAsFixed(2) ?? "N/A"}'),
                    _DetailRow('Buy/Purchase Price', '₹${item.buyRate?.toStringAsFixed(2) ?? "N/A"}'),
                    _DetailRow('GST Status', item.gstApplicable ? 'Applicable (${item.gstRate ?? 0.0}%)' : 'Exempt / Non-GST'),
                    _DetailRow('CESS Rate', '${item.cessRate ?? 0.0}%'),
                    _DetailRow('HSN Code', item.hsnCode ?? 'N/A'),
                  ], theme),
                  const SizedBox(height: 24),

                  // Categorization & Specs
                  _buildSectionTitle('Categorization & Specs', theme),
                  const SizedBox(height: 12),
                  _buildDetailTable([
                    _DetailRow('Category', item.category.value?.categoryName ?? 'N/A'),
                    _DetailRow('Brand', item.brand.value?.brandName ?? 'N/A'),
                    _DetailRow('Primary Unit', item.unit.value?.unitName ?? 'N/A'),
                    _DetailRow('Secondary Unit', item.secondaryUnit ?? 'N/A'),
                    _DetailRow('Conversion Factor', item.conversionFactor != null ? '1 ${item.secondaryUnit} = ${item.conversionFactor} ${item.unit.value?.shortName}' : 'N/A'),
                    _DetailRow('Weight', item.weight != null ? '${item.weight} KG' : 'N/A'),
                    _DetailRow('Dimensions', item.dimensions ?? 'N/A'),
                  ], theme),
                  const SizedBox(height: 24),

                  // Stock Logs / History
                  _buildSectionTitle('Stock Movement History', theme),
                  const SizedBox(height: 12),
                  historyLogs.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('No stock adjustments recorded yet.'),
                          ),
                        )
                      : Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: historyLogs.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final log = historyLogs[index];
                              return ListTile(
                                dense: true,
                                title: Text(log),
                                leading: Icon(
                                  log.contains('STOCK_IN') ? Icons.add_circle : Icons.remove_circle,
                                  color: log.contains('STOCK_IN') ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                              );
                            },
                          ),
                        ),
                  if (item.notes != null && item.notes!.isNotEmpty && historyLogs.isEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Notes', theme),
                    const SizedBox(height: 8),
                    Text(item.notes!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(Item item, ThemeData theme) {
    final images = item.imagePaths ?? [];
    if (images.isEmpty) {
      return Container(
        height: 200,
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        child: Icon(
          Icons.image_outlined,
          size: 72,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          final file = File(images[index]);
          return FutureBuilder<bool>(
            future: file.exists(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Image.file(
                  file,
                  fit: BoxFit.contain,
                );
              } else {
                return Container(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  child: const Center(child: Text('Image file not found locally.')),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildStockBadge(bool isOut, bool isLow, ThemeData theme, Item item) {
    Color color = Colors.green;
    String label = 'In Stock';
    if (isOut) {
      color = Colors.red;
      label = 'Out of Stock';
    } else if (isLow) {
      color = Colors.orange;
      label = 'Low Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildDetailTable(List<_DetailRow> rows, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row.label,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  row.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: row.isBold ? FontWeight.bold : FontWeight.normal,
                    color: row.isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  final bool isBold;
  _DetailRow(this.label, this.value, {this.isBold = false});
}
