import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({Key? key}) : super(key: key);

  static Future<Item?> show(BuildContext context) {
    return showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddItemSheet(),
    );
  }

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _sellRateController = TextEditingController();
  
  Category? _selectedCategory;
  Unit? _selectedUnit;
  double _selectedGstRate = 18.0;
  bool _isLoading = false;

  final List<double> _gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  void initState() {
    super.initState();
    _loadNextCode();
  }

  Future<void> _loadNextCode() async {
    try {
      final repo = ref.read(itemRepositoryProvider);
      final nextCode = await repo.generateNextItemCode();
      if (mounted) {
        setState(() {
          _codeController.text = nextCode;
        });
      }
    } catch (e) {
      logger.error('Failed to generate item code in sheet', e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sellRateController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(itemRepositoryProvider);
      
      final newItem = Item()
        ..itemName = _nameController.text.trim()
        ..itemCode = _codeController.text.trim()
        ..sellRate = double.tryParse(_sellRateController.text.trim()) ?? 0.0
        ..gstApplicable = _selectedGstRate > 0
        ..gstRate = _selectedGstRate
        ..currentStock = 0.0
        ..reorderLevel = 0.0
        ..openingStock = 0.0;

      if (_selectedCategory != null) {
        newItem.category.value = _selectedCategory;
      }
      if (_selectedUnit != null) {
        newItem.unit.value = _selectedUnit;
      }

      await repo.create(newItem);
      
      // Refresh the lists
      ref.invalidate(filteredItemsProvider);
      ref.invalidate(lowStockAlertProvider);

      if (mounted) {
        Navigator.pop(context, newItem);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item "${newItem.itemName}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to quick-create item', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final unitsAsync = ref.watch(unitsListProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Add Product',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Item Code & Name row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pricing and GST
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sellRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Sell Price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<double>(
                      value: _selectedGstRate,
                      decoration: const InputDecoration(
                        labelText: 'GST Rate',
                        border: OutlineInputBorder(),
                      ),
                      items: _gstRates.map((rate) {
                        return DropdownMenuItem<double>(
                          value: rate,
                          child: Text('${rate.toInt()}%'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedGstRate = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unit & Category Row
              Row(
                children: [
                  // Unit Selection
                  Expanded(
                    child: unitsAsync.when(
                      data: (units) {
                        // Pre-select first unit if available
                        if (_selectedUnit == null && units.isNotEmpty) {
                          _selectedUnit = units.first;
                        }
                        return DropdownButtonFormField<Unit>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          items: units.map((u) {
                            return DropdownMenuItem<Unit>(
                              value: u,
                              child: Text(u.shortName ?? u.unitName ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedUnit = val);
                          },
                        );
                      },
                      loading: () => const Center(child: LinearProgressIndicator()),
                      error: (e, _) => const Icon(Icons.error_outline),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category Selection
                  Expanded(
                    child: categoriesAsync.when(
                      data: (categories) {
                        return DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: categories.map((c) {
                            return DropdownMenuItem<Category>(
                              value: c,
                              child: Text(c.categoryName ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedCategory = val);
                          },
                        );
                      },
                      loading: () => const Center(child: LinearProgressIndicator()),
                      error: (e, _) => const Icon(Icons.error_outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    onPressed: _isLoading ? null : _saveItem,
                    child: const Text('Save Product'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
