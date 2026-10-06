import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/widgets/hsn_search_modal.dart';

final fixedAssetListProvider = FutureProvider<List<FixedAssetItem>>((ref) async {
  final isar = ref.watch(databaseServiceProvider).isar;
  return await isar.collection<FixedAssetItem>().filter().isDeletedEqualTo(false).findAll();
});

class AddEditFixedAssetSheet extends ConsumerStatefulWidget {
  final FixedAssetItem? asset;

  const AddEditFixedAssetSheet({Key? key, this.asset}) : super(key: key);

  static Future<bool?> show(BuildContext context, {FixedAssetItem? asset}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditFixedAssetSheet(asset: asset),
    );
  }

  @override
  ConsumerState<AddEditFixedAssetSheet> createState() => _AddEditFixedAssetSheetState();
}

class _AddEditFixedAssetSheetState extends ConsumerState<AddEditFixedAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _assetCodeController = TextEditingController();
  final _hsnController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _depreciationRateController = TextEditingController(text: '10.0');
  final _quantityController = TextEditingController(text: '1.0');
  final _notesController = TextEditingController();

  String _selectedAssetType = 'Furniture & Fixtures';
  String _selectedUnit = 'PCS';
  double _gstRate = 18.0;
  bool _isSaving = false;

  final List<String> _assetTypes = [
    'Furniture & Fixtures',
    'Plant & Machinery',
    'Vehicles',
    'Computers & IT',
    'Buildings & Land',
    'Office Equipment',
    'Tools & Implements',
    'Electricals',
    'Other Fixed Assets',
  ];

  final List<String> _units = ['PCS', 'NOS', 'SET', 'UNIT', 'KG', 'MTR', 'BOX'];

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _assetNameController.text = widget.asset!.assetName ?? '';
      _assetCodeController.text = widget.asset!.assetCode ?? '';
      _selectedAssetType = widget.asset!.assetType ?? 'Furniture & Fixtures';
      _hsnController.text = widget.asset!.hsnCode ?? '';
      _purchasePriceController.text = widget.asset!.purchasePrice?.toString() ?? '';
      _serialNumberController.text = widget.asset!.serialNumber ?? '';
      _locationController.text = widget.asset!.location ?? '';
      _depreciationRateController.text = widget.asset!.depreciationRate?.toString() ?? '10.0';
      _quantityController.text = widget.asset!.quantity?.toString() ?? '1.0';
      _notesController.text = widget.asset!.notes ?? '';
      _selectedUnit = widget.asset!.unit ?? 'PCS';
      _gstRate = widget.asset!.gstRate ?? 18.0;
    } else {
      _generateNextAssetCode();
    }
  }

  Future<void> _generateNextAssetCode() async {
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final count = await isar.collection<FixedAssetItem>().count();
      _assetCodeController.text = 'FA-${(count + 1).toString().padLeft(4, '0')}';
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _assetCodeController.dispose();
    _hsnController.dispose();
    _purchasePriceController.dispose();
    _serialNumberController.dispose();
    _locationController.dispose();
    _depreciationRateController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openHsnSearch() async {
    final query = _assetNameController.text.trim();
    final result = await HsnSearchModal.show(context, initialQuery: query);
    if (result != null && mounted) {
      setState(() {
        _hsnController.text = result.hsnCode;
        _gstRate = result.gstRate;
      });
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;
      final asset = widget.asset ?? FixedAssetItem();

      asset
        ..uuid ??= Uuid().v4()
        ..assetCode = _assetCodeController.text.trim()
        ..assetName = _assetNameController.text.trim()
        ..assetType = _selectedAssetType
        ..hsnCode = _hsnController.text.trim()
        ..gstRate = _gstRate
        ..purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0.0
        ..serialNumber = _serialNumberController.text.trim()
        ..location = _locationController.text.trim()
        ..depreciationRate = double.tryParse(_depreciationRateController.text) ?? 10.0
        ..quantity = double.tryParse(_quantityController.text) ?? 1.0
        ..unit = _selectedUnit
        ..notes = _notesController.text.trim()
        ..updatedAt = DateTime.now()
        ..isSynced = false
        ..isDeleted = false;

      await isar.writeTxn(() async {
        await isar.collection<FixedAssetItem>().put(asset);
      });

      ref.invalidate(fixedAssetListProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.asset != null ? 'Fixed Asset updated successfully!' : 'Fixed Asset created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Fixed Asset: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.precision_manufacturing_rounded, color: Colors.purple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.asset != null ? 'Edit Fixed Asset Item' : 'Add New Fixed Asset Item',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Asset Name
              TextFormField(
                controller: _assetNameController,
                decoration: const InputDecoration(
                  labelText: 'Fixed Asset Name *',
                  hintText: 'e.g. Office Laptop Dell XPS, Generator 5KV, Office Desk',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Asset Name is required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _assetCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Asset Code',
                        prefixIcon: Icon(Icons.qr_code),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAssetType,
                      decoration: const InputDecoration(
                        labelText: 'Asset Category',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _assetTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAssetType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // HSN / SAC Code Input with Search Button
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _hsnController,
                      decoration: InputDecoration(
                        labelText: 'HSN / SAC Code',
                        prefixIcon: const Icon(Icons.tag),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.blue),
                          tooltip: 'Search HSN Online',
                          onPressed: _openHsnSearch,
                        ),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<double>(
                      value: _gstRate,
                      decoration: const InputDecoration(
                        labelText: 'GST %',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: const [0.0, 5.0, 12.0, 18.0, 28.0]
                          .map((r) => DropdownMenuItem(value: r, child: Text('$r%')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _gstRate = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price (₹)',
                        prefixIcon: Icon(Icons.currency_rupee),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Serial / Model / Tag #',
                        prefixIcon: Icon(Icons.numbers),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / Room',
                        prefixIcon: Icon(Icons.place_outlined),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _depreciationRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Depreciation % / Year',
                        prefixIcon: Icon(Icons.trending_down),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Initial Quantity',
                        prefixIcon: Icon(Icons.numbers_outlined),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Asset Specification',
                  prefixIcon: Icon(Icons.notes),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAsset,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(widget.asset != null ? 'Update Fixed Asset' : 'Save Fixed Asset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
