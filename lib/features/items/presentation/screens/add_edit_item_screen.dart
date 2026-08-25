import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/hsn_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/core/widgets/modern_form_section.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final String? itemUuid;

  const AddEditItemScreen({Key? key, this.itemUuid}) : super(key: key);

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _shortNameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _skuCodeController = TextEditingController();

  final TextEditingController _buyRateController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _sellRateController = TextEditingController();
  final TextEditingController _wholesaleRateController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();

  final TextEditingController _openingStockController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _reorderLevelController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _conversionController = TextEditingController();
  final TextEditingController _secToTerConversionController = TextEditingController();

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _hsnController = TextEditingController();

  // Selections
  Category? _selectedCategory;
  Brand? _selectedBrand;
  Unit? _selectedUnit;
  Unit? _selectedSecUnit;
  Unit? _selectedTertiaryUnit;
  String _rateUnitType = 'Primary'; // 'Primary' or 'Secondary'
  String _buyRateTaxType = 'Without Tax'; // 'Without Tax' or 'With Tax'
  String _sellRateTaxType = 'With Tax'; // 'With Tax' or 'Without Tax'
  String _wholesaleRateTaxType = 'With Tax'; // 'With Tax' or 'Without Tax'
  double _gstRate = 18.0;
  double _cessRate = 0.0;
  bool _gstApplicable = true;

  bool _isLoading = false;
  Item? _existingItem;
  List<HsnModel> _suggestedHsnCodes = [];
  Timer? _debounceTimer;

  static const List<Map<String, String>> _commonUnits = [
    {'name': 'Pieces', 'code': 'PCS'},
    {'name': 'Boxes', 'code': 'BOX'},
    {'name': 'Kilograms', 'code': 'KGS'},
    {'name': 'Litres', 'code': 'LTR'},
    {'name': 'Meters', 'code': 'MTR'},
    {'name': 'Bags', 'code': 'BAG'},
    {'name': 'Numbers', 'code': 'NOS'},
    {'name': 'Dozen', 'code': 'DOZ'},
    {'name': 'Bottles', 'code': 'BTL'},
    {'name': 'Cans', 'code': 'CAN'},
    {'name': 'Cartons', 'code': 'CRT'},
    {'name': 'Grams', 'code': 'GMS'},
    {'name': 'Packs', 'code': 'PAC'},
    {'name': 'Rolls', 'code': 'ROL'},
    {'name': 'Sets', 'code': 'SET'},
    {'name': 'Tablets', 'code': 'TBS'},
    {'name': 'Tubes', 'code': 'TUB'},
    {'name': 'Units', 'code': 'UNT'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onItemNameChanged);
    
    _checkAndSeedCommonUnits();

    if (widget.itemUuid != null) {
      _loadItem();
    } else {
      _loadNextCode();
    }

    // Pre-populate HSN suggestions
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hsnService = ref.read(hsnServiceProvider);
      await hsnService.fetchOnlineHsnCodes();
      if (mounted) {
        setState(() {
          _suggestedHsnCodes = hsnService.getCommonHsnCodes();
        });
      }
    });
  }

  Future<void> _checkAndSeedCommonUnits() async {
    try {
      final repo = ref.read(unitRepositoryProvider);
      final list = await repo.getAll();
      if (list.isEmpty) {
        for (var unitData in _commonUnits) {
          final u = Unit()
            ..unitName = unitData['name']
            ..shortName = unitData['code'];
          await repo.create(u);
        }
        ref.invalidate(unitsListProvider);
      }
    } catch (e) {
      logger.error('Failed to seed common units', e);
    }
  }

  void _onItemNameChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        final hsnService = ref.read(hsnServiceProvider);
        final results = await hsnService.searchOnlineHsn(name);
        if (mounted) {
          setState(() {
            _suggestedHsnCodes = results;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _suggestedHsnCodes = ref.read(hsnServiceProvider).getCommonHsnCodes();
          });
        }
      }
    });
  }

  Future<void> _loadNextCode() async {
    try {
      final repo = ref.read(itemRepositoryProvider);
      final nextCode = await repo.generateNextItemCode();
      setState(() {
        _codeController.text = nextCode;
      });
    } catch (e) {
      logger.error('Failed to pre-fill item code', e);
    }
  }

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final item = await repo.getByUuid(widget.itemUuid!);
      if (item != null) {
        try { await item.category.load(); } catch (_) {}
        try { await item.brand.load(); } catch (_) {}
        try { await item.unit.load(); } catch (_) {}

        _existingItem = item;
        _nameController.text = item.itemName ?? '';
        _codeController.text = item.itemCode ?? '';
        _shortNameController.text = item.shortName ?? '';
        _descController.text = item.description ?? '';
        _barcodeController.text = item.barcode ?? '';
        _skuController.text = item.sku ?? '';
        _skuCodeController.text = item.skuCode ?? '';

        _buyRateController.text = item.buyRate?.toString() ?? '';
        _mrpController.text = item.mrp?.toString() ?? '';
        _sellRateController.text = item.sellRate?.toString() ?? '';
        _wholesaleRateController.text = item.wholesaleRate?.toString() ?? '';
        _minPriceController.text = item.minimumSellingPrice?.toString() ?? '';

        _openingStockController.text = item.openingStock?.toString() ?? '';
        _currentStockController.text = item.currentStock?.toString() ?? '';
        _reorderLevelController.text = item.reorderLevel?.toString() ?? '';
        _minStockController.text = item.minimumStock?.toString() ?? '';
        _conversionController.text = item.conversionFactor?.toString() ?? '';
        _secToTerConversionController.text = item.secondaryToTertiaryConversion?.toString() ?? '';

        _weightController.text = item.weight?.toString() ?? '';
        _dimensionsController.text = item.dimensions ?? '';
        _notesController.text = item.notes ?? '';
        _hsnController.text = item.hsnCode ?? '';

        _gstRate = item.gstRate ?? 18.0;
        _cessRate = item.cessRate ?? 0.0;
        _gstApplicable = item.gstApplicable;

        // Load DB collections to match selected objects
        final categories = await ref.read(categoryRepositoryProvider).getAll();
        final brands = await ref.read(brandRepositoryProvider).getAll();
        final units = await ref.read(unitRepositoryProvider).getAll();

        if (item.category.value != null) {
          _selectedCategory = categories.firstWhere((c) => c.id == item.category.value!.id);
        }
        if (item.brand.value != null) {
          _selectedBrand = brands.firstWhere((b) => b.id == item.brand.value!.id);
        }
        if (item.primaryUnitName != null && item.primaryUnitName!.isNotEmpty) {
          _selectedUnit = units.where((u) => (u.shortName?.trim().toLowerCase() == item.primaryUnitName!.trim().toLowerCase() || u.unitName?.trim().toLowerCase() == item.primaryUnitName!.trim().toLowerCase())).firstOrNull;
        }
        if (_selectedUnit == null && item.unit.value != null) {
          _selectedUnit = units.where((u) => u.id == item.unit.value!.id).firstOrNull;
        }
        if (_selectedUnit == null && item.primaryUnitName != null && item.primaryUnitName!.isNotEmpty) {
          _selectedUnit = Unit()
            ..shortName = item.primaryUnitName
            ..unitName = item.primaryUnitName;
        }

        if (item.secondaryUnit != null && item.secondaryUnit!.isNotEmpty) {
          try {
            _selectedSecUnit = units.firstWhere((u) => u.shortName?.trim().toLowerCase() == item.secondaryUnit!.trim().toLowerCase() || u.unitName?.trim().toLowerCase() == item.secondaryUnit!.trim().toLowerCase());
          } catch (_) {
            _selectedSecUnit = Unit()
              ..shortName = item.secondaryUnit
              ..unitName = item.secondaryUnit;
          }
        }

        if (item.tertiaryUnit != null && item.tertiaryUnit!.isNotEmpty) {
          try {
            _selectedTertiaryUnit = units.firstWhere((u) => u.shortName?.trim().toLowerCase() == item.tertiaryUnit!.trim().toLowerCase() || u.unitName?.trim().toLowerCase() == item.tertiaryUnit!.trim().toLowerCase());
          } catch (_) {
            _selectedTertiaryUnit = Unit()
              ..shortName = item.tertiaryUnit
              ..unitName = item.tertiaryUnit;
          }
        }
      }
    } catch (e) {
      logger.error('Failed to load item for edit', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onItemNameChanged);
    _debounceTimer?.cancel();
    _nameController.dispose();
    _codeController.dispose();
    _shortNameController.dispose();
    _descController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _skuCodeController.dispose();
    _buyRateController.dispose();
    _mrpController.dispose();
    _sellRateController.dispose();
    _wholesaleRateController.dispose();
    _minPriceController.dispose();
    _openingStockController.dispose();
    _currentStockController.dispose();
    _reorderLevelController.dispose();
    _minStockController.dispose();
    _conversionController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _notesController.dispose();
    _hsnController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcodeService = ref.read(barcodeServiceProvider);
    final code = await barcodeService.scanBarcode(context);
    if (code != null) {
      setState(() {
        _barcodeController.text = code;
        if (_skuCodeController.text.isEmpty) {
          _skuCodeController.text = code;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned code: $code')),
      );
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final TextEditingController nameCont = TextEditingController();
    final TextEditingController descCont = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create New Category'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCont,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCont,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = nameCont.text.trim();
                  final desc = descCont.text.trim();
                  
                  final category = Category()
                    ..categoryName = name
                    ..description = desc;
                  
                  try {
                    await ref.read(categoryRepositoryProvider).create(category);
                    ref.invalidate(categoriesListProvider);
                    
                    final list = await ref.read(categoryRepositoryProvider).getAll();
                    final created = list.firstWhere((c) => c.categoryName == name, orElse: () => category);
                    
                    setState(() {
                      _selectedCategory = created;
                    });
                    
                    if (mounted) Navigator.pop(ctx);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating category: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateBrandDialog() async {
    final TextEditingController nameCont = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create New Brand'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameCont,
              decoration: const InputDecoration(
                labelText: 'Brand Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = nameCont.text.trim();
                  final brand = Brand()..brandName = name;
                  
                  try {
                    await ref.read(brandRepositoryProvider).create(brand);
                    ref.invalidate(brandsListProvider);
                    
                    final list = await ref.read(brandRepositoryProvider).getAll();
                    final created = list.firstWhere((b) => b.brandName == name, orElse: () => brand);
                    
                    setState(() {
                      _selectedBrand = created;
                    });
                    
                    if (mounted) Navigator.pop(ctx);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating brand: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateUnitDialog({bool isSecondary = false}) async {
    final TextEditingController nameCont = TextEditingController();
    final TextEditingController shortCont = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create New Unit'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCont,
                  decoration: const InputDecoration(
                    labelText: 'Unit Name (e.g. Pieces) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: shortCont,
                  decoration: const InputDecoration(
                    labelText: 'Unit Code (e.g. PCS) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = nameCont.text.trim();
                  final short = shortCont.text.trim().toUpperCase();
                  
                  final unit = Unit()
                    ..unitName = name
                    ..shortName = short;
                  
                  try {
                    await ref.read(unitRepositoryProvider).create(unit);
                    ref.invalidate(unitsListProvider);
                    
                    final list = await ref.read(unitRepositoryProvider).getAll();
                    final created = list.firstWhere((u) => u.shortName == short, orElse: () => unit);
                    
                    setState(() {
                      if (isSecondary) {
                        _selectedSecUnit = created;
                      } else {
                        _selectedUnit = created;
                      }
                    });
                    
                    if (mounted) Navigator.pop(ctx);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating unit: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct errors in the form.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(itemRepositoryProvider);

      final item = _existingItem ?? Item();
      item.itemName = _nameController.text.trim();
      item.itemCode = _codeController.text.trim();
      item.shortName = _shortNameController.text.trim();
      item.description = _descController.text.trim();
      item.barcode = _barcodeController.text.trim();
      item.sku = _skuController.text.trim().isEmpty ? null : _skuController.text.trim();
      item.skuCode = _skuCodeController.text.trim().isEmpty ? null : _skuCodeController.text.trim();

      final conv = double.tryParse(_conversionController.text.trim()) ?? 1.0;
      final isPerSecondary = _rateUnitType == 'Secondary' && conv > 0 && conv != 1.0;

      double? rawBuy = double.tryParse(_buyRateController.text.trim());
      double? rawMrp = double.tryParse(_mrpController.text.trim());
      double? rawSell = double.tryParse(_sellRateController.text.trim());
      double? rawWholesale = double.tryParse(_wholesaleRateController.text.trim());
      double? rawMinPrice = double.tryParse(_minPriceController.text.trim());

      item.buyRate = (rawBuy != null && isPerSecondary) ? (rawBuy * conv) : rawBuy;
      item.mrp = (rawMrp != null && isPerSecondary) ? (rawMrp * conv) : rawMrp;
      item.sellRate = (rawSell != null && isPerSecondary) ? (rawSell * conv) : rawSell;
      item.wholesaleRate = (rawWholesale != null && isPerSecondary) ? (rawWholesale * conv) : rawWholesale;
      item.minimumSellingPrice = (rawMinPrice != null && isPerSecondary) ? (rawMinPrice * conv) : rawMinPrice;

      item.openingStock = double.tryParse(_openingStockController.text.trim()) ?? 0.0;
      item.currentStock = double.tryParse(_currentStockController.text.trim()) ?? 
          double.tryParse(_openingStockController.text.trim()) ?? 0.0;
      item.reorderLevel = double.tryParse(_reorderLevelController.text.trim()) ?? 0.0;
      item.minimumStock = double.tryParse(_minStockController.text.trim()) ?? 0.0;
      item.primaryUnitName = _selectedUnit?.shortName ?? _selectedUnit?.unitName ?? item.primaryUnitName ?? 'PCS';
      item.secondaryUnit = _selectedSecUnit?.shortName ?? _selectedSecUnit?.unitName;
      item.tertiaryUnit = _selectedTertiaryUnit?.shortName ?? _selectedTertiaryUnit?.unitName;
      item.conversionFactor = double.tryParse(_conversionController.text.trim());
      item.secondaryToTertiaryConversion = double.tryParse(_secToTerConversionController.text.trim());

      item.gstApplicable = _gstApplicable;
      item.gstRate = _gstRate;
      item.cessRate = _cessRate;
      item.hsnCode = _hsnController.text.trim();

      item.weight = double.tryParse(_weightController.text.trim());
      item.dimensions = _dimensionsController.text.trim();
      item.notes = _notesController.text.trim();
      item.imagePaths = _existingItem?.imagePaths ?? [];

      item.category.value = _selectedCategory;
      item.brand.value = _selectedBrand;
      if (_selectedUnit != null) {
        item.unit.value = _selectedUnit;
        item.primaryUnitName = _selectedUnit?.shortName ?? _selectedUnit?.unitName;
      } else if (item.primaryUnitName == null || item.primaryUnitName!.isEmpty) {
        item.primaryUnitName = item.unit.value?.shortName ?? item.unit.value?.unitName ?? 'PCS';
      }

      if (_existingItem == null) {
        await repo.create(item);
      } else {
        await repo.update(item);
        if (item.uuid != null && item.itemName != null) {
          await ref.read(databaseServiceProvider).cascadeRenameItem(item.uuid!, item.itemName!);
        }
      }

      ref.invalidate(filteredItemsProvider);
      ref.invalidate(lowStockAlertProvider);

      if (mounted) {
        Navigator.pop(context, item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "${item.itemName}" saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Quiet background sync after screen pops
      Future.microtask(() {
        try {
          ref.read(syncServiceProvider).syncPendingChangesQuietly();
        } catch (_) {}
      });
    } catch (e) {
      logger.error('Failed to save item', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSearchableUnitPicker({required bool isSecondary, required List<Unit> unitsList}) {
    showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final filtered = unitsList.where((u) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              final name = u.unitName?.toLowerCase() ?? '';
              final short = u.shortName?.toLowerCase() ?? '';
              return name.contains(q) || short.contains(q);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isSecondary ? 'Select Secondary Unit' : 'Select Primary Unit',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                height: 480,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search unit (e.g. PCS, BOX, KGS, LTR)...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() => query = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('+ Add New Custom Unit'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreateUnitDialog(isSecondary: isSecondary);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (isSecondary) ...[
                      ListTile(
                        leading: const Icon(Icons.close, color: Colors.grey),
                        title: const Text('None (Remove Secondary Unit)'),
                        onTap: () {
                          setState(() => _selectedSecUnit = null);
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(),
                    ],
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No units found.'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final unit = filtered[index];
                                final isSelected = isSecondary
                                    ? (_selectedSecUnit?.id == unit.id)
                                    : (_selectedUnit?.id == unit.id);
                                return ListTile(
                                  selected: isSelected,
                                  title: Text(
                                    '${unit.unitName ?? ""} (${unit.shortName ?? ""})',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                  onTap: () {
                                    setState(() {
                                      if (isSecondary) {
                                        _selectedSecUnit = unit;
                                      } else {
                                        _selectedUnit = unit;
                                      }
                                    });
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ModernFormSection(
        title: title,
        icon: icon,
        iconColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final brandsAsync = ref.watch(brandsListProvider);
    final unitsAsync = ref.watch(unitsListProvider);
    final hsnService = ref.watch(hsnServiceProvider);

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: Text(widget.itemUuid == null ? 'Create Product Master' : 'Edit Product Master'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000), // beautiful desktop card constraint
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title header row directly at the top of the form body
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.add_shopping_cart, color: theme.colorScheme.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.itemUuid == null ? 'Create Product Master' : 'Edit Product Master',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Register and configure product specifications, pricing, tax rates, and inventory units',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        _buildBasicInfoSection(categoriesAsync, brandsAsync),
                        _buildIdentificationSection(),
                        _buildPricingSection(),
                        _buildTaxationSection(hsnService),
                        _buildInventoryUnitsSection(unitsAsync),
                        _buildSpecsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;
                  if (isNarrow) {
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Cancel'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 18),
                                SizedBox(width: 8),
                                Text('Save'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Save Product Master'),
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection(
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<Brand>> brandsAsync,
  ) {
    final theme = Theme.of(context);
    return _buildSectionCard(
      context: context,
      title: 'Basic Information',
      icon: Icons.info_outline,
      color: Colors.indigo,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Product Code *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Product code is required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _shortNameController,
                decoration: const InputDecoration(
                  labelText: 'Short Name / Alias',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: categoriesAsync.when(
                data: (list) {
                  final exists = _selectedCategory != null && list.any((c) => c.id == _selectedCategory!.id);
                  final dropdownItems = exists ? list : [...list, if (_selectedCategory != null) _selectedCategory!];
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: dropdownItems.map((cat) {
                            return DropdownMenuItem<Category>(
                              value: cat,
                              child: Text(cat.categoryName ?? ''),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Category',
                        onPressed: _showCreateCategoryDialog,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => const Icon(Icons.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: brandsAsync.when(
                data: (list) {
                  final exists = _selectedBrand != null && list.any((b) => b.id == _selectedBrand!.id);
                  final dropdownItems = exists ? list : [...list, if (_selectedBrand != null) _selectedBrand!];
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Brand>(
                          value: _selectedBrand,
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            border: OutlineInputBorder(),
                          ),
                          items: dropdownItems.map((br) {
                            return DropdownMenuItem<Brand>(
                              value: br,
                              child: Text(br.brandName ?? ''),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedBrand = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Brand',
                        onPressed: _showCreateBrandDialog,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentificationSection() {
    final isMobile = ResponsiveLayout.isMobile(context);
    final barcodeField = Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _barcodeController,
            decoration: const InputDecoration(
              labelText: 'Barcode (UPC/EAN)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.camera_alt),
          tooltip: 'Scan Barcode',
          onPressed: _scanBarcode,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );

    final skuField = TextFormField(
      controller: _skuController,
      decoration: const InputDecoration(
        labelText: 'SKU Code',
        border: OutlineInputBorder(),
      ),
    );

    final extSkuField = TextFormField(
      controller: _skuCodeController,
      decoration: const InputDecoration(
        labelText: 'Catalog / Ext SKU Code',
        border: OutlineInputBorder(),
      ),
    );

    return _buildSectionCard(
      context: context,
      title: 'Identifiers & Barcodes',
      icon: Icons.qr_code_scanner,
      color: Colors.purple,
      children: [
        if (isMobile) ...[
          barcodeField,
          const SizedBox(height: 12),
          skuField,
          const SizedBox(height: 12),
          extSkuField,
        ] else
          Row(
            children: [
              Expanded(child: barcodeField),
              const SizedBox(width: 16),
              Expanded(child: skuField),
              const SizedBox(width: 16),
              Expanded(child: extSkuField),
            ],
          ),
      ],
    );
  }

  Widget _buildPricingSection() {
    final primaryName = _selectedUnit != null ? '${_selectedUnit!.unitName} (${_selectedUnit!.shortName})' : 'Primary Unit';
    final secondaryName = _selectedSecUnit != null ? '${_selectedSecUnit!.unitName} (${_selectedSecUnit!.shortName})' : 'Secondary Unit';

    return _buildSectionCard(
      context: context,
      title: 'Pricing Details (INR)',
      icon: Icons.payments_outlined,
      color: Colors.green,
      children: [
        if (_selectedSecUnit != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.teal),
                const SizedBox(width: 8),
                const Text('Rates entered below are per: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButton<String>(
                  value: _rateUnitType,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: 'Primary', child: Text('Primary Unit ($primaryName)')),
                    DropdownMenuItem(value: 'Secondary', child: Text('Secondary Unit ($secondaryName)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _rateUnitType = val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 1. Purchase Rate & MRP Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Purchase Price + Tax Mode Selector
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _buyRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Purchase Rate (Buy)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _buyRateTaxType,
                            isDense: true,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Without Tax', child: Text('Without Tax')),
                              DropdownMenuItem(value: 'With Tax', child: Text('With Tax')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _buyRateTaxType = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_buyRateController.text.isNotEmpty && _gstApplicable && _gstRate > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                      child: Builder(builder: (ctx) {
                        final val = double.tryParse(_buyRateController.text) ?? 0.0;
                        if (val <= 0) return const SizedBox.shrink();
                        if (_buyRateTaxType == 'Without Tax') {
                          final tax = val * (_gstRate / 100);
                          final gross = val + tax;
                          return Text('₹${gross.toStringAsFixed(2)} With Tax (GST: ₹${tax.toStringAsFixed(2)})',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold));
                        } else {
                          final net = val / (1 + (_gstRate / 100));
                          final tax = val - net;
                          return Text('₹${net.toStringAsFixed(2)} Without Tax (GST: ₹${tax.toStringAsFixed(2)})',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold));
                        }
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // MRP Input
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _mrpController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'MRP (Max Retail Price)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                  helperText: 'Max printed price',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 2. Retail Selling Price & Wholesale Price Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Retail Selling Price + Tax Mode Selector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Retail Selling Price *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Selling rate is required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _sellRateTaxType,
                            isDense: true,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'With Tax', child: Text('With Tax')),
                              DropdownMenuItem(value: 'Without Tax', child: Text('Without Tax')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _sellRateTaxType = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_sellRateController.text.isNotEmpty && _gstApplicable && _gstRate > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                      child: Builder(builder: (ctx) {
                        final val = double.tryParse(_sellRateController.text) ?? 0.0;
                        if (val <= 0) return const SizedBox.shrink();
                        if (_sellRateTaxType == 'With Tax') {
                          final net = val / (1 + (_gstRate / 100));
                          final tax = val - net;
                          return Text('Base: ₹${net.toStringAsFixed(2)} | GST: ₹${tax.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold));
                        } else {
                          final tax = val * (_gstRate / 100);
                          final gross = val + tax;
                          return Text('Final: ₹${gross.toStringAsFixed(2)} (GST: ₹${tax.toStringAsFixed(2)})',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold));
                        }
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Wholesale Price + Tax Mode Selector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _wholesaleRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Wholesale Price',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _wholesaleRateTaxType,
                            isDense: true,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'With Tax', child: Text('With Tax')),
                              DropdownMenuItem(value: 'Without Tax', child: Text('Without Tax')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _wholesaleRateTaxType = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_wholesaleRateController.text.isNotEmpty && _gstApplicable && _gstRate > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                      child: Builder(builder: (ctx) {
                        final val = double.tryParse(_wholesaleRateController.text) ?? 0.0;
                        if (val <= 0) return const SizedBox.shrink();
                        if (_wholesaleRateTaxType == 'With Tax') {
                          final net = val / (1 + (_gstRate / 100));
                          final tax = val - net;
                          return Text('Base: ₹${net.toStringAsFixed(2)} | GST: ₹${tax.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold));
                        } else {
                          final tax = val * (_gstRate / 100);
                          final gross = val + tax;
                          return Text('Final: ₹${gross.toStringAsFixed(2)} (GST: ₹${tax.toStringAsFixed(2)})',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold));
                        }
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. Minimum Selling Price Threshold Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Minimum Selling Price Threshold',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                  helperText: 'Prevents staff from discounting below this price threshold',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaxationSection(HsnService hsnService) {
    final theme = Theme.of(context);
    return _buildSectionCard(
      context: context,
      title: 'Taxation Details (GST & HSN)',
      icon: Icons.receipt_long,
      color: Colors.amber,
      children: [
        SwitchListTile(
          title: const Text('GST Applicable'),
          subtitle: const Text('Is tax applied to this item during sales/purchase?'),
          value: _gstApplicable,
          onChanged: (v) => setState(() => _gstApplicable = v),
        ),
        if (_gstApplicable) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<double>(
                  value: _gstRate,
                  decoration: const InputDecoration(
                    labelText: 'GST Percentage',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                    DropdownMenuItem(value: 5.0, child: Text('5%')),
                    DropdownMenuItem(value: 12.0, child: Text('12%')),
                    DropdownMenuItem(value: 18.0, child: Text('18%')),
                    DropdownMenuItem(value: 28.0, child: Text('28%')),
                  ],
                  onChanged: (v) => setState(() => _gstRate = v ?? 18.0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RawAutocomplete<HsnModel>(
                  textEditingController: _hsnController,
                  focusNode: FocusNode(),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();
                    final hsnService = ref.read(hsnServiceProvider);
                    return hsnService.searchHsnCodes(query);
                  },
                  displayStringForOption: (HsnModel option) => option.hsnCode,
                  onSelected: (HsnModel selection) {
                    setState(() {
                      _hsnController.text = selection.hsnCode;
                      _gstRate = selection.gstRate;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected HSN ${selection.hsnCode} (GST ${selection.gstRate}%)'), backgroundColor: Colors.green),
                    );
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: const InputDecoration(
                        labelText: 'HSN / SAC Code (Auto Suggest)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.history_edu),
                        hintText: 'e.g. 8471, 6109, 1006',
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 320,
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text('${option.hsnCode} - GST ${option.gstRate}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(option.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _nameController.text.trim().isEmpty 
                        ? 'Common Indian HSN Code Suggestions:' 
                        : 'Suggested HSN Codes for "${_nameController.text.trim()}":',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _suggestedHsnCodes.isEmpty
                      ? const Text('Type product name above to auto-suggest matching HSN codes', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestedHsnCodes.take(10).map((hsn) {
                            return ActionChip(
                              avatar: const Icon(Icons.bolt, size: 14, color: Colors.amber),
                              label: Text('${hsn.hsnCode} (${hsn.description.split(" ").first}) - ${hsn.gstRate}% GST'),
                              backgroundColor: theme.colorScheme.surface,
                              onPressed: () {
                                setState(() {
                                  _hsnController.text = hsn.hsnCode;
                                  _gstRate = hsn.gstRate;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Selected HSN ${hsn.hsnCode} with ${hsn.gstRate}% GST rate!'), backgroundColor: Colors.green),
                                );
                              },
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInventoryUnitsSection(AsyncValue<List<Unit>> unitsAsync) {
    return _buildSectionCard(
      context: context,
      title: 'Inventory & Units',
      icon: Icons.inventory_2_outlined,
      color: Colors.teal,
      children: [
        Flex(
          direction: ResponsiveLayout.isMobile(context) ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(
              flex: ResponsiveLayout.isMobile(context) ? 0 : 1,
              child: TextFormField(
                controller: _openingStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Opening Stock',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: ResponsiveLayout.isMobile(context) ? 0 : 16, height: ResponsiveLayout.isMobile(context) ? 12 : 0),
            Expanded(
              flex: ResponsiveLayout.isMobile(context) ? 0 : 1,
              child: TextFormField(
                controller: _currentStockController,
                enabled: widget.itemUuid == null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Current Stock',
                  border: const OutlineInputBorder(),
                  helperText: widget.itemUuid != null ? 'Adjust stock in stock logs' : null,
                ),
              ),
            ),
            SizedBox(width: ResponsiveLayout.isMobile(context) ? 0 : 16, height: ResponsiveLayout.isMobile(context) ? 12 : 0),
            Expanded(
              flex: ResponsiveLayout.isMobile(context) ? 0 : 1,
              child: TextFormField(
                controller: _reorderLevelController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Reorder Level',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: ResponsiveLayout.isMobile(context) ? 0 : 16, height: ResponsiveLayout.isMobile(context) ? 12 : 0),
            Expanded(
              flex: ResponsiveLayout.isMobile(context) ? 0 : 1,
              child: TextFormField(
                controller: _minStockController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Minimum Stock Warning',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Flex(
          direction: ResponsiveLayout.isMobile(context) ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(
              flex: ResponsiveLayout.isMobile(context) ? 0 : 1,
              child: unitsAsync.when(
                data: (list) {
                  final exists = _selectedUnit != null && list.any((u) => u.id == _selectedUnit!.id);
                  final dropdownItems = exists ? list : [...list, if (_selectedUnit != null) _selectedUnit!];
                  return Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showSearchableUnitPicker(isSecondary: false, unitsList: dropdownItems),
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Primary Unit *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _selectedUnit != null 
                                  ? '${_selectedUnit!.unitName} (${_selectedUnit!.shortName})' 
                                  : 'Select Primary Unit *',
                              style: TextStyle(
                                color: _selectedUnit == null ? Colors.grey : null,
                                fontWeight: _selectedUnit != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Unit',
                        onPressed: () => _showCreateUnitDialog(isSecondary: false),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => const Icon(Icons.error),
              ),
            ),
            SizedBox(width: ResponsiveLayout.isMobile(context) ? 0 : 16, height: ResponsiveLayout.isMobile(context) ? 12 : 0),
            Expanded(
              flex: ResponsiveLayout.isMobile(context) ? 0 : 1,
              child: unitsAsync.when(
                data: (list) {
                  final exists = _selectedSecUnit != null && list.any((u) => u.id == _selectedSecUnit!.id);
                  final dropdownItems = exists ? list : [...list, if (_selectedSecUnit != null) _selectedSecUnit!];
                  return Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showSearchableUnitPicker(isSecondary: true, unitsList: dropdownItems),
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Secondary Unit',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _selectedSecUnit != null 
                                  ? '${_selectedSecUnit!.unitName} (${_selectedSecUnit!.shortName})' 
                                  : 'None (Optional)',
                              style: TextStyle(
                                color: _selectedSecUnit == null ? Colors.grey : null,
                                fontWeight: _selectedSecUnit != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Unit',
                        onPressed: () => _showCreateUnitDialog(isSecondary: true),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (e, _) => const Icon(Icons.error),
              ),
            ),
            if (_selectedSecUnit != null) ...[
              SizedBox(width: ResponsiveLayout.isMobile(context) ? 0 : 16, height: ResponsiveLayout.isMobile(context) ? 12 : 0),
              Expanded(
                flex: ResponsiveLayout.isMobile(context) ? 0 : 1,
                child: TextFormField(
                  controller: _conversionController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Conversion Factor',
                    border: OutlineInputBorder(),
                    helperText: 'E.g. If 1 BOX = 10 PCS, enter 10.0',
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSpecsSection() {
    return _buildSectionCard(
      context: context,
      title: 'Physical Specs & Notes',
      icon: Icons.description_outlined,
      color: Colors.blue,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (KG)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Dimensions (L x W x H)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Operational Notes / Custom Specs',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
