import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/hsn_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final String? itemUuid;

  const AddEditItemScreen({Key? key, this.itemUuid}) : super(key: key);

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
  final TextEditingController _secUnitController = TextEditingController();
  final TextEditingController _conversionController = TextEditingController();

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _hsnController = TextEditingController();

  // Selections
  Category? _selectedCategory;
  Brand? _selectedBrand;
  Unit? _selectedUnit;
  double _gstRate = 18.0;
  double _cessRate = 0.0;
  bool _gstApplicable = true;

  List<String> _localImagePaths = [];
  bool _isLoading = false;
  Item? _existingItem;
  List<HsnModel> _suggestedHsnCodes = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _nameController.addListener(_onItemNameChanged);
    
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
        _secUnitController.text = item.secondaryUnit ?? '';
        _conversionController.text = item.conversionFactor?.toString() ?? '';

        _weightController.text = item.weight?.toString() ?? '';
        _dimensionsController.text = item.dimensions ?? '';
        _notesController.text = item.notes ?? '';
        _hsnController.text = item.hsnCode ?? '';

        _gstRate = item.gstRate ?? 18.0;
        _cessRate = item.cessRate ?? 0.0;
        _gstApplicable = item.gstApplicable;
        _localImagePaths = List<String>.from(item.imagePaths ?? []);

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
        if (item.unit.value != null) {
          _selectedUnit = units.firstWhere((u) => u.id == item.unit.value!.id);
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
    _tabController.dispose();
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
    _secUnitController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    final imageService = ref.read(imageServiceProvider);
    if (source == ImageSource.gallery) {
      final paths = await imageService.pickAndProcessMultipleImages();
      if (paths.isNotEmpty) {
        setState(() {
          _localImagePaths.addAll(paths);
        });
      }
    } else {
      final path = await imageService.pickAndProcessImage(source);
      if (path != null) {
        setState(() {
          _localImagePaths.add(path);
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct errors in form tabs.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final imageService = ref.read(imageServiceProvider);

      final item = _existingItem ?? Item();
      item.itemName = _nameController.text.trim();
      item.itemCode = _codeController.text.trim();
      item.shortName = _shortNameController.text.trim();
      item.description = _descController.text.trim();
      item.barcode = _barcodeController.text.trim();
      item.sku = _skuController.text.trim().isEmpty ? null : _skuController.text.trim();
      item.skuCode = _skuCodeController.text.trim().isEmpty ? null : _skuCodeController.text.trim();

      item.buyRate = double.tryParse(_buyRateController.text.trim());
      item.mrp = double.tryParse(_mrpController.text.trim());
      item.sellRate = double.tryParse(_sellRateController.text.trim());
      item.wholesaleRate = double.tryParse(_wholesaleRateController.text.trim());
      item.minimumSellingPrice = double.tryParse(_minPriceController.text.trim());

      item.openingStock = double.tryParse(_openingStockController.text.trim()) ?? 0.0;
      item.currentStock = double.tryParse(_currentStockController.text.trim()) ?? 
          double.tryParse(_openingStockController.text.trim()) ?? 0.0;
      item.reorderLevel = double.tryParse(_reorderLevelController.text.trim()) ?? 0.0;
      item.minimumStock = double.tryParse(_minStockController.text.trim()) ?? 0.0;
      item.secondaryUnit = _secUnitController.text.trim().isEmpty ? null : _secUnitController.text.trim();
      item.conversionFactor = double.tryParse(_conversionController.text.trim());

      item.gstApplicable = _gstApplicable;
      item.gstRate = _gstRate;
      item.cessRate = _cessRate;
      item.hsnCode = _hsnController.text.trim();

      item.weight = double.tryParse(_weightController.text.trim());
      item.dimensions = _dimensionsController.text.trim();
      item.notes = _notesController.text.trim();
      item.imagePaths = _localImagePaths;

      if (_localImagePaths.isNotEmpty && item.thumbnailImage == null) {
        final thumb = await imageService.createThumbnail(_localImagePaths.first);
        item.thumbnailImage = thumb;
      }

      item.category.value = _selectedCategory;
      item.brand.value = _selectedBrand;
      item.unit.value = _selectedUnit;

      if (_existingItem == null) {
        await repo.create(item);
      } else {
        await repo.update(item);
      }

      // Refresh list
      ref.invalidate(filteredItemsProvider);
      ref.invalidate(lowStockAlertProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "${item.itemName}" saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final brandsAsync = ref.watch(brandsListProvider);
    final unitsAsync = ref.watch(unitsListProvider);
    final hsnService = ref.watch(hsnServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemUuid == null ? 'Create Product Master' : 'Edit Product Master'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
              tooltip: 'Save Item',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Info', icon: Icon(Icons.info_outline)),
            Tab(text: 'Pricing & Tax', icon: Icon(Icons.payments_outlined)),
            Tab(text: 'Inventory & Unit', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Images', icon: Icon(Icons.photo_library_outlined)),
            Tab(text: 'Specs / Notes', icon: Icon(Icons.description_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(categoriesAsync, brandsAsync),
                  _buildPricingTab(hsnService),
                  _buildInventoryTab(unitsAsync),
                  _buildImagesTab(),
                  _buildSpecsTab(),
                ],
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Product'),
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<Brand>> brandsAsync,
  ) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item Code and Name
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Product Code *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.tag),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Product code is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Product Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_bag),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _shortNameController,
            decoration: const InputDecoration(
              labelText: 'Short Name / Alias',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Barcodes & SKU Codes',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Barcode with scanning capability
          Row(
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
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _skuCodeController,
                  decoration: const InputDecoration(
                    labelText: 'External SKU / Catalog Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Categorization',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Category
              Expanded(
                child: categoriesAsync.when(
                  data: (list) {
                    return DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: list.map((cat) {
                        return DropdownMenuItem<Category>(
                          value: cat,
                          child: Text(cat.categoryName ?? ''),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, _) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 12),
              // Brand
              Expanded(
                child: brandsAsync.when(
                  data: (list) {
                    return DropdownButtonFormField<Brand>(
                      value: _selectedBrand,
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        border: OutlineInputBorder(),
                      ),
                      items: list.map((br) {
                        return DropdownMenuItem<Brand>(
                          value: br,
                          child: Text(br.brandName ?? ''),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedBrand = v),
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, _) => const Icon(Icons.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingTab(HsnService hsnService) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Product Pricing Structure (INR)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _buyRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Rate (Buy)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _mrpController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'MRP (Max Retail Price)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sellRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Retail Selling Price *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Selling rate is required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _wholesaleRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Wholesale Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _minPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Minimum Selling Price Threshold',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_rupee),
              helperText: 'Prevents staff from discounting below this price',
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Taxation Details (GST & HSN)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('GST Applicable'),
            subtitle: const Text('Is tax applied to this item during sales/purchase?'),
            value: _gstApplicable,
            onChanged: (v) => setState(() => _gstApplicable = v),
          ),
          if (_gstApplicable) ...[
            const SizedBox(height: 12),
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
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _hsnController,
                    decoration: const InputDecoration(
                      labelText: 'HSN / SAC Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.history_edu),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Autocomplete / seeded lookup UI
            Card(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _nameController.text.trim().isEmpty 
                          ? 'Common HSN Codes Suggestions:' 
                          : 'Online HSN Suggestions for "${_nameController.text.trim()}":',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedHsnCodes.take(6).map((hsn) {
                        return ActionChip(
                          avatar: Text('${hsn.gstRate.toInt()}%', style: const TextStyle(fontSize: 9)),
                          label: Text('${hsn.hsnCode} (${hsn.description.split(' ').first})'),
                          onPressed: () {
                            setState(() {
                              _hsnController.text = hsn.hsnCode;
                              _gstRate = hsn.gstRate;
                              _cessRate = hsn.cessRate;
                            });
                            hsnService.addToRecent(hsn);
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
      ),
    );
  }

  Widget _buildInventoryTab(AsyncValue<List<Unit>> unitsAsync) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Stock Tracking Levels',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _openingStockController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Opening Stock',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _currentStockController,
                  enabled: widget.itemUuid == null, // edit stock via stock adjustments, not form
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Current Stock',
                    border: const OutlineInputBorder(),
                    helperText: widget.itemUuid != null ? 'Adjust stock in stock logs' : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _reorderLevelController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Reorder Level',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Unit Configurations',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Primary Unit Dropdown
              Expanded(
                child: unitsAsync.when(
                  data: (list) {
                    return DropdownButtonFormField<Unit>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Primary Unit *',
                        border: OutlineInputBorder(),
                      ),
                      items: list.map((u) {
                        return DropdownMenuItem<Unit>(
                          value: u,
                          child: Text('${u.unitName} (${u.shortName})'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v),
                      validator: (v) => v == null ? 'Primary unit is required' : null,
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, _) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 12),
              // Secondary Unit
              Expanded(
                child: TextFormField(
                  controller: _secUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Secondary Unit (e.g. BOX)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _conversionController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Conversion Factor',
              border: OutlineInputBorder(),
              helperText: 'E.g. If 1 BOX = 10 PCS, enter 10.0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesTab() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Product Images',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload compressed images. The first image will be used as the product card thumbnail.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take Photo'),
                  onPressed: () => _pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.image_search_outlined),
                  label: const Text('Add Gallery'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _localImagePaths.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text('No images added to this product yet.'),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _localImagePaths.length,
                    itemBuilder: (context, index) {
                      final path = _localImagePaths[index];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black.withOpacity(0.6),
                              child: IconButton(
                                icon: const Icon(Icons.delete, size: 12, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _localImagePaths.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ),
                          if (index == 0)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              right: 4,
                              child: Container(
                                color: Colors.black.withOpacity(0.65),
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: const Text(
                                  'Thumbnail',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight (KG)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dimensionsController,
            decoration: const InputDecoration(
              labelText: 'Dimensions (L x W x H)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Operational Notes / Custom Specs',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
