import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/features/fixed_assets/presentation/providers/fixed_asset_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddFixedAssetScreen extends ConsumerStatefulWidget {
  const AddFixedAssetScreen({super.key});

  @override
  ConsumerState<AddFixedAssetScreen> createState() => _AddFixedAssetScreenState();
}

class _AddFixedAssetScreenState extends ConsumerState<AddFixedAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _descController = TextEditingController();
  String _assetType = 'Machinery';
  String _depreciationMethod = 'Straight Line';
  String _paymentMode = 'Bank';
  double _gstPercent = 0.0;
  DateTime _purchaseDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;
    
    final cost = double.tryParse(_costController.text) ?? 0.0;
    
    final asset = FixedAsset()
      ..assetName = _nameController.text
      ..assetType = _assetType
      ..description = _descController.text
      ..purchaseDate = _purchaseDate
      ..purchaseCost = cost
      ..accumulatedDepreciation = 0.0
      ..bookValue = cost
      ..depreciationRate = 0.0
      ..depreciationMethod = _depreciationMethod
      ..status = 'Active';
      
    final txn = FixedAssetTransaction()
      ..transactionDate = _purchaseDate
      ..amount = cost
      ..remarks = 'Initial Purchase';
      
    try {
      await ref.read(fixedAssetRepositoryProvider).purchaseAsset(asset, txn);
      
      // Additional transaction for GST if applicable
      if (_gstPercent > 0 && cost > 0) {
        final gstAmount = cost * (_gstPercent / 100);
        final isar = ref.read(databaseServiceProvider).isar;
        await isar.writeTxn(() async {
           final gstTxn = Transaction()
            ..uuid = Uuid().v4()
            ..transactionNumber = 'FA-GST-${DateTime.now().millisecondsSinceEpoch}'
            ..transactionDate = _purchaseDate
            ..transactionType = 'Expense' 
            ..amount = gstAmount
            ..paymentMode = _paymentMode
            ..remarks = 'GST for FA Purchase: ${asset.assetName}';
          
          await isar.transactions.put(gstTxn);
        });
      }

      // Update the payment mode of the main transaction
      final isar = ref.read(databaseServiceProvider).isar;
      await isar.writeTxn(() async {
         final mainTxns = await isar.transactions.filter().referenceNumberEqualTo(txn.uuid).findAll();
         for (var t in mainTxns) {
           t.paymentMode = _paymentMode;
           await isar.transactions.put(t);
         }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset purchased and recorded in ledger')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Fixed Asset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAsset,
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Asset Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _assetType,
                decoration: const InputDecoration(labelText: 'Asset Type', border: OutlineInputBorder()),
                items: ['Machinery', 'Vehicles', 'Computers', 'Furniture', 'Building', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _assetType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Purchase Cost (₹)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Purchase Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_purchaseDate)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                onTap: () async {
                  final dt = await showDatePicker(
                    context: context,
                    initialDate: _purchaseDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (dt != null) setState(() => _purchaseDate = dt);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _depreciationMethod,
                decoration: const InputDecoration(labelText: 'Depreciation Method', border: OutlineInputBorder()),
                items: ['Straight Line', 'Written Down Value (WDV)', 'None']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _depreciationMethod = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(labelText: 'Payment Account / Mode', border: OutlineInputBorder()),
                items: ['Bank', 'Cash', 'Credit', 'UPI']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMode = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                value: _gstPercent,
                decoration: const InputDecoration(labelText: 'GST Rate (%)', border: OutlineInputBorder()),
                items: [0.0, 5.0, 12.0, 18.0, 28.0]
                    .map((e) => DropdownMenuItem(value: e, child: Text('${e.toInt()}%')))
                    .toList(),
                onChanged: (v) => setState(() => _gstPercent = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Remarks / Description', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _saveAsset,
            child: const Text('Save & Book to Ledger'),
          ),
        ),
      ),
    );
  }
}
