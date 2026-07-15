import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/providers/purchase_providers.dart';

class AddEditPurchaseScreen extends ConsumerStatefulWidget {
  const AddEditPurchaseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEditPurchaseScreen> createState() => _AddEditPurchaseScreenState();
}

class _AddEditPurchaseScreenState extends ConsumerState<AddEditPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _billNumberController = TextEditingController();
  
  Party? _selectedParty;
  List<PurchaseItem> _draftItems = [];
  DateTime _purchaseDate = DateTime.now();

  double _subtotal = 0.0;
  double _discountAmount = 0.0;
  double _taxableAmount = 0.0;
  double _totalGST = 0.0;
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  void _initValues() async {
    // Generate draft purchase number
    final repo = ref.read(purchaseRepositoryProvider);
    final numStr = await repo.generateNextPurchaseNumber();
    setState(() {
      _billNumberController.text = numStr;
    });
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _billNumberController.dispose();
    super.dispose();
  }

  void _recalculateTotals() {
    double sub = 0.0;
    double tax = 0.0;

    for (var item in _draftItems) {
      final double qty = item.quantity ?? 0.0;
      final double rate = item.rate ?? 0.0;
      final double itemDisc = item.discount ?? 0.0;
      
      final lineSub = qty * rate;
      final lineTaxable = lineSub - itemDisc;
      final lineTax = lineTaxable * ((item.gstRate ?? 0.0) / 100.0);
      
      item.taxableAmount = lineTaxable;
      item.gstAmount = lineTax;
      item.totalAmount = lineTaxable + lineTax;

      sub += lineSub;
      tax += lineTax;
    }

    setState(() {
      _subtotal = sub;
      _taxableAmount = sub - _discountAmount;
      _totalGST = tax;
      _grandTotal = _taxableAmount + _totalGST;
    });
  }

  void _addItemLine(Item item, double qty, double rate, double gstRate) {
    final newItem = PurchaseItem()
      ..itemId = item.id
      ..itemName = item.itemName
      ..hsnCode = item.hsnCode
      ..quantity = qty
      ..rate = rate
      ..discount = 0.0
      ..gstRate = gstRate;
      
    newItem.item.value = item;

    setState(() {
      _draftItems.add(newItem);
    });
    _recalculateTotals();
  }

  void _saveBill() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier party.')),
      );
      return;
    }

    if (_draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to purchase.')),
      );
      return;
    }

    final purchase = Purchase()
      ..purchaseNumber = _billNumberController.text.trim()
      ..purchaseDate = _purchaseDate
      ..partyId = _selectedParty!.id
      ..partyName = _selectedParty!.partyName
      ..gstNumber = _selectedParty!.gstNumber
      ..address = _selectedParty!.addressLine1
      ..subtotal = _subtotal
      ..discountAmount = _discountAmount
      ..taxableAmount = _taxableAmount
      ..totalGST = _totalGST
      ..grandTotal = _grandTotal
      ..remarks = _remarksController.text.trim();

    purchase.party.value = _selectedParty;

    final success = await ref
        .read(purchaseNotifierProvider.notifier)
        .savePurchase(purchase, _draftItems);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase invoice saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partiesAsync = ref.watch(filteredPartiesProvider);
    final itemsAsync = ref.watch(filteredItemsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('New Purchase Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveBill,
            tooltip: 'Save Purchase',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Form Fields
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Supplier dropdown
                      partiesAsync.when(
                        data: (parties) {
                          final suppliers = parties.where((p) => p.partyType != 'Retailer').toList();
                          return DropdownButtonFormField<Party>(
                            value: _selectedParty,
                            decoration: const InputDecoration(
                              labelText: 'Select Supplier Party',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: suppliers.map((p) {
                              return DropdownMenuItem<Party>(
                                value: p,
                                child: Text('${p.partyName} (${p.partyType ?? "Supplier"})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedParty = val;
                              });
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('Error loading suppliers: $err'),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _billNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Purchase Bill Number',
                                prefixIcon: Icon(Icons.receipt_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _purchaseDate,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) {
                                  setState(() {
                                    _purchaseDate = d;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Bill Date',
                                  prefixIcon: Icon(Icons.calendar_today_outlined),
                                ),
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(_purchaseDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Purchase Line Items',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddItemDialog(theme, itemsAsync);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items Table Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: _draftItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No items added to this purchase bill yet.\nClick "Add Item" above to add products.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _draftItems.length,
                        itemBuilder: (context, index) {
                          final item = _draftItems[index];
                          return ListTile(
                            title: Text(item.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${item.quantity?.toInt()} Units  x  ₹${item.rate?.toStringAsFixed(2)}  (Tax: ${item.gstRate}%)',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${item.totalAmount?.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _draftItems.removeAt(index);
                                    });
                                    _recalculateTotals();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),

              // Summary Calculations
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', _subtotal, theme),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Discount (Draft)', _discountAmount, theme),
                      const SizedBox(height: 8),
                      _buildSummaryRow('GST Input Tax', _totalGST, theme),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${_grandTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Remarks
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Internal Notes',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveBill,
                child: const Text('SAVE PURCHASE BILL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showAddItemDialog(ThemeData theme, AsyncValue<List<Item>> itemsAsync) {
    Item? tempItem;
    final qtyController = TextEditingController(text: '1');
    final rateController = TextEditingController(text: '0.00');
    double tempGst = 18.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product to Bill'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              itemsAsync.when(
                data: (items) {
                  return DropdownButtonFormField<Item>(
                    decoration: const InputDecoration(labelText: 'Choose Product'),
                    items: items.map((i) {
                      return DropdownMenuItem<Item>(
                        value: i,
                        child: Text(i.itemName ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      tempItem = val;
                      if (val != null) {
                        rateController.text = (val.buyRate ?? 0.0).toStringAsFixed(2);
                      }
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading catalog: $err'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity (Units)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Purchase Rate (₹)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                value: tempGst,
                decoration: const InputDecoration(labelText: 'GST Rate (%)'),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('0% (Exempt)')),
                  DropdownMenuItem(value: 5.0, child: Text('5%')),
                  DropdownMenuItem(value: 12.0, child: Text('12%')),
                  DropdownMenuItem(value: 18.0, child: Text('18%')),
                  DropdownMenuItem(value: 28.0, child: Text('28%')),
                ],
                onChanged: (val) {
                  if (val != null) tempGst = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempItem != null) {
                final qty = double.tryParse(qtyController.text) ?? 1.0;
                final rate = double.tryParse(rateController.text) ?? 0.0;
                _addItemLine(tempItem!, qty, rate, tempGst);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
