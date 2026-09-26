import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/features/fixed_assets/presentation/providers/fixed_asset_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/fixed_asset_transaction_collection.dart';
import 'package:intl/intl.dart';

class SellFixedAssetScreen extends ConsumerStatefulWidget {
  final FixedAsset asset;
  const SellFixedAssetScreen({super.key, required this.asset});

  @override
  ConsumerState<SellFixedAssetScreen> createState() => _SellFixedAssetScreenState();
}

class _SellFixedAssetScreenState extends ConsumerState<SellFixedAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime _sellDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sellAmount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (sellAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid sell amount')));
      return;
    }

    final txn = FixedAssetTransaction()
      ..transactionDate = _sellDate
      ..amount = sellAmount
      ..remarks = _remarksController.text;

    try {
      await ref.read(fixedAssetRepositoryProvider).sellAsset(widget.asset, txn);
      if (mounted) {
        final gainLoss = sellAmount - widget.asset.bookValue;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Asset sold! ${gainLoss >= 0 ? "Gain" : "Loss"}: ₹${gainLoss.abs().toStringAsFixed(2)}'),
        ));
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
      appBar: AppBar(title: const Text('Sell / Dispose Fixed Asset')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Asset: ${widget.asset.assetName}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Current Book Value: ₹${widget.asset.bookValue.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Sell Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_sellDate)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                onTap: () async {
                  final dt = await showDatePicker(
                    context: context,
                    initialDate: _sellDate,
                    firstDate: widget.asset.purchaseDate ?? DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (dt != null) setState(() => _sellDate = dt);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Sell Amount (₹)', ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Remarks', ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
            child: const Text('Record Disposal'),
          ),
        ),
      ),
    );
  }
}
