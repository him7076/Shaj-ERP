import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/settings/presentation/providers/settings_providers.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddEditFixedAssetScreen extends ConsumerStatefulWidget {
  final String? prefilledName;

  const AddEditFixedAssetScreen({Key? key, this.prefilledName}) : super(key: key);

  @override
  ConsumerState<AddEditFixedAssetScreen> createState() => _AddEditFixedAssetScreenState();
}

class _AddEditFixedAssetScreenState extends ConsumerState<AddEditFixedAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _hsnController = TextEditingController();
  final _qtyController = TextEditingController(text: '1.0');
  final _priceController = TextEditingController();
  DateTime _asOfDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledName != null) {
      _nameController.text = widget.prefilledName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _hsnController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOfDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _asOfDate = picked);
    }
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final db = ref.read(databaseServiceProvider).isar;
      
      // Ensure "Fixed Assets" category exists
      var category = await db.categorys.filter().categoryNameEqualTo('Fixed Assets').findFirst();
      if (category == null) {
        category = Category()
          ..uuid = const Uuid().v4()
          ..categoryName = 'Fixed Assets'
          ..isSynced = false
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await db.writeTxn(() async {
          await db.categorys.put(category!);
        });
      }

      // Ensure "PCS" unit exists as default
      var unit = await db.units.filter().shortNameEqualTo('PCS').findFirst();
      if (unit == null) {
        unit = Unit()
          ..uuid = const Uuid().v4()
          ..shortName = 'PCS'
          ..unitName = 'Pieces'
          ..isSynced = false
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await db.writeTxn(() async {
          await db.units.put(unit!);
        });
      }

      final item = Item()
        ..uuid = const Uuid().v4()
        ..itemName = _nameController.text.trim()
        ..itemCode = _codeController.text.trim()
        ..hsnCode = _hsnController.text.trim()
        ..openingStock = double.tryParse(_qtyController.text) ?? 1.0
        ..currentStock = double.tryParse(_qtyController.text) ?? 1.0
        ..buyRate = double.tryParse(_priceController.text) ?? 0.0
        ..sellRate = double.tryParse(_priceController.text) ?? 0.0
        ..asOfDate = _asOfDate
        ..itemType = 'Product'
        ..isSynced = false
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
        
      item.category.value = category;
      item.unit.value = unit;

      await db.writeTxn(() async {
        final id = await db.items.put(item);
        item.id = id;
        await item.category.save();
        await item.unit.save();
      });

      ref.invalidate(itemsListProvider);
      if (mounted) {
        Navigator.pop(context, item);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fixed Asset'),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white))
          else
            TextButton(
              onPressed: _saveAsset,
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeuCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Asset Name *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(labelText: 'Asset Code', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hsnController,
                        decoration: const InputDecoration(labelText: 'HSN Code', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              NeuCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Opening Qty *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'At Price / Unit', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'As of Date', border: OutlineInputBorder()),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd-MMM-yyyy').format(_asOfDate)),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAsset,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('SAVE FIXED ASSET'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
