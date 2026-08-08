import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/providers/expense_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:isar/isar.dart';

class ExpenseLineItem {
  String name;
  double quantity;
  double rate;

  ExpenseLineItem({
    required this.name,
    this.quantity = 1.0,
    this.rate = 0.0,
  });

  double get amount => quantity * rate;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'rate': rate,
        'amount': amount,
      };

  factory ExpenseLineItem.fromJson(Map<String, dynamic> json) => ExpenseLineItem(
        name: json['name'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
        rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      );
}

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final String? expenseUuid;
  const AddEditExpenseScreen({Key? key, this.expenseUuid}) : super(key: key);

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _voucherNoController = TextEditingController();
  final _partyNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  // Line item add inputs
  final _itemNameController = TextEditingController();
  final _itemQtyController = TextEditingController(text: '1');
  final _itemRateController = TextEditingController();

  String _selectedCategory = 'Office Expense';
  String _selectedPaymentMode = 'Cash';
  DateTime _expenseDate = DateTime.now();
  double? _customRoundOff;

  Expense? _existingExpense;
  List<String> _categories = [];
  List<ExpenseLineItem> _lineItems = [];

  // Repeatable expense templates
  final List<Map<String, dynamic>> _expenseTemplates = [
    {'name': 'Tea & Refreshment', 'defaultRate': 50.0},
    {'name': 'Office Stationery / Paper', 'defaultRate': 250.0},
    {'name': 'Courier & Transport Charges', 'defaultRate': 150.0},
    {'name': 'Vehicle Fuel / Petrol', 'defaultRate': 500.0},
    {'name': 'Cleaning & Sanitation', 'defaultRate': 200.0},
    {'name': 'Electricity / Utility Bill', 'defaultRate': 1000.0},
    {'name': 'Repair & Maintenance', 'defaultRate': 500.0},
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final repo = ref.read(expenseRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    
    List<String>? cats = prefs.getStringList('expense_categories');
    if (cats == null || cats.isEmpty) {
      cats = ['Rent', 'Salaries', 'Utilities', 'Tea & Snacks', 'Office Expense', 'Other'];
      await prefs.setStringList('expense_categories', cats);
    }
    _categories = cats;

    if (widget.expenseUuid != null) {
      final isar = ref.read(databaseServiceProvider).isar;
      final expense = await isar.expenses.filter().uuidEqualTo(widget.expenseUuid).findFirst();
      if (expense != null) {
        _existingExpense = expense;
        _voucherNoController.text = expense.voucherNo ?? '';
        _partyNameController.text = expense.partyName ?? '';
        _amountController.text = (expense.amount ?? 0.0).toStringAsFixed(2);
        _remarksController.text = expense.remarks ?? '';
        _selectedCategory = expense.category ?? 'Office Expense';
        _selectedPaymentMode = expense.paymentMode ?? 'Cash';
        _expenseDate = expense.expenseDate ?? DateTime.now();
        _customRoundOff = expense.roundOff;

        if (expense.itemsJson != null && expense.itemsJson!.isNotEmpty) {
          try {
            final List<dynamic> decoded = jsonDecode(expense.itemsJson!);
            _lineItems = decoded.map((e) => ExpenseLineItem.fromJson(e)).toList();
          } catch (_) {}
        }
      }
    } else {
      final nextVoucher = await repo.generateNextVoucherNumber();
      _voucherNoController.text = nextVoucher;
    }
    setState(() {});
  }

  double get _subtotal {
    if (_lineItems.isNotEmpty) {
      return _lineItems.fold(0.0, (sum, item) => sum + item.amount);
    }
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  double get _rawGrandTotal => _subtotal;

  double get _grandTotal {
    if (_customRoundOff != null) {
      return _rawGrandTotal + _customRoundOff!;
    }
    return _rawGrandTotal.roundToDouble();
  }

  double get _roundOff {
    return _customRoundOff ?? (_grandTotal - _rawGrandTotal);
  }

  void _addLineItem() {
    final name = _itemNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name.')),
      );
      return;
    }

    final qty = double.tryParse(_itemQtyController.text) ?? 1.0;
    final rate = double.tryParse(_itemRateController.text) ?? 0.0;

    setState(() {
      _lineItems.add(ExpenseLineItem(name: name, quantity: qty, rate: rate));
      _itemNameController.clear();
      _itemQtyController.text = '1';
      _itemRateController.clear();
      _amountController.text = _subtotal.toStringAsFixed(2);
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
      _amountController.text = _subtotal.toStringAsFixed(2);
    });
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final newCat = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Expense Category'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter category name';
                }
                if (_categories.any((c) => c.toLowerCase() == val.trim().toLowerCase())) {
                  return 'Category already exists';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newCat != null && newCat.isNotEmpty) {
      setState(() {
        _categories.add(newCat);
        _selectedCategory = newCat;
      });
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList('expense_categories', _categories);
    }
  }

  @override
  void dispose() {
    _voucherNoController.dispose();
    _partyNameController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    _itemNameController.dispose();
    _itemQtyController.dispose();
    _itemRateController.dispose();
    super.dispose();
  }

  void _saveExpense() async {
    if (_formKey.currentState?.validate() ?? false) {
      final totalAmt = _grandTotal;
      if (totalAmt <= 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid expense amount or add line items.')),
        );
        return;
      }

      final expense = _existingExpense ?? Expense();
      expense
        ..voucherNo = _voucherNoController.text.trim()
        ..partyName = _partyNameController.text.trim()
        ..category = _selectedCategory
        ..subtotal = _subtotal
        ..roundOff = _roundOff
        ..amount = totalAmt
        ..expenseDate = _expenseDate
        ..paymentMode = _selectedPaymentMode
        ..remarks = _remarksController.text.trim()
        ..itemsJson = _lineItems.isNotEmpty
            ? jsonEncode(_lineItems.map((e) => e.toJson()).toList())
            : null;

      if (_existingExpense == null) {
        expense.uuid = '${DateTime.now().millisecondsSinceEpoch}';
      }

      final success = await ref
          .read(expenseNotifierProvider.notifier)
          .saveExpense(expense);

      if (success && mounted) {
        // Quiet background sync for newly saved expense
        Future.microtask(() {
          try {
            ref.read(syncServiceProvider).syncPendingChangesQuietly();
          } catch (_) {}
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_existingExpense == null ? 'Expense voucher logged successfully.' : 'Expense voucher updated successfully.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_existingExpense == null ? 'New Expense Voucher' : 'Edit Expense Voucher'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            onPressed: _saveExpense,
            tooltip: 'Save Expense Voucher',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Voucher Header & Basic Details Card
              _buildHeaderCard(theme, isMobile, isDark),
              const SizedBox(height: 16),

              // 2. Repeatable Expense Items Section Card
              _buildLineItemsCard(theme, isMobile, isDark),
              const SizedBox(height: 16),

              // 3. Payment & Totals Summary Card
              _buildSummaryCard(theme, isMobile, isDark),
              const SizedBox(height: 24),

              // Save Action Button
              ElevatedButton.icon(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'SAVE EXPENSE VOUCHER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, bool isMobile, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Voucher & Category Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Text(
                    _voucherNoController.text.isEmpty ? 'EXP-1001' : _voucherNoController.text,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (isMobile) ...[
              TextFormField(
                controller: _voucherNoController,
                decoration: const InputDecoration(
                  labelText: 'Voucher No. *',
                  prefixIcon: Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _buildCategorySelector(),
              const SizedBox(height: 14),
              _buildDatePicker(context),
              const SizedBox(height: 14),
              TextFormField(
                controller: _partyNameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor / Payee Name (Optional)',
                  prefixIcon: Icon(Icons.storefront_rounded),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _voucherNoController,
                      decoration: const InputDecoration(
                        labelText: 'Voucher No. *',
                        prefixIcon: Icon(Icons.numbers_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCategorySelector()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildDatePicker(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _partyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Vendor / Payee Name (Optional)',
                        prefixIcon: Icon(Icons.storefront_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Row(
      children: [
        Expanded(
          child: SearchableCategoryDropdown(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add Category',
          onPressed: _showAddCategoryDialog,
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _expenseDate,
          firstDate: DateTime(2025),
          lastDate: DateTime(2030),
        );
        if (d != null) {
          setState(() {
            _expenseDate = d;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Expense Date',
          prefixIcon: Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          DateFormat('dd MMM yyyy').format(_expenseDate),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLineItemsCard(ThemeData theme, bool isMobile, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeatable Expense Items',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Itemized breakdown (No inventory stock impact)',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Quick Preset Template Chips
            const Text('Quick Repeatable Templates:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _expenseTemplates.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF6366F1)),
                      label: Text(t['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      onPressed: () {
                        setState(() {
                          _itemNameController.text = t['name'];
                          _itemRateController.text = (t['defaultRate'] as double).toStringAsFixed(0);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Add Item Input Form Row
            if (isMobile) ...[
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return _expenseTemplates.map((e) => e['name'] as String);
                  final query = textEditingValue.text.toLowerCase();
                  return _expenseTemplates.map((e) => e['name'] as String).where((name) => name.toLowerCase().contains(query));
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Sync controller with _itemNameController
                  controller.text = _itemNameController.text;
                  controller.selection = _itemNameController.selection;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Expense Item Description *',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      _itemNameController.text = val;
                    },
                  );
                },
                onSelected: (selection) {
                  _itemNameController.text = selection;
                  final matched = _expenseTemplates.firstWhere((t) => t['name'] == selection, orElse: () => {});
                  if (matched.isNotEmpty) {
                    _itemRateController.text = (matched['defaultRate'] as double).toStringAsFixed(0);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemQtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _itemRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rate (₹)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addLineItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return _expenseTemplates.map((e) => e['name'] as String);
                        final query = textEditingValue.text.toLowerCase();
                        return _expenseTemplates.map((e) => e['name'] as String).where((name) => name.toLowerCase().contains(query));
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        controller.text = _itemNameController.text;
                        controller.selection = _itemNameController.selection;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Expense Item Description *',
                            prefixIcon: Icon(Icons.shopping_bag_outlined),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            _itemNameController.text = val;
                          },
                        );
                      },
                      onSelected: (selection) {
                        _itemNameController.text = selection;
                        final matched = _expenseTemplates.firstWhere((t) => t['name'] == selection, orElse: () => {});
                        if (matched.isNotEmpty) {
                          _itemRateController.text = (matched['defaultRate'] as double).toStringAsFixed(0);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _itemQtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _itemRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rate (₹)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addLineItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Line', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Line Items List / Table
            if (_lineItems.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'No line items added. Enter direct total amount below or add items above.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lineItems.length,
                separatorBuilder: (context, index) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final item = _lineItems[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${item.quantity} Qty × ₹${item.rate.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${item.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => _removeLineItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isMobile, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_rounded, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment & Round Off Summary',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // Direct Amount input if no line items added
            if (_lineItems.isEmpty) ...[
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Expense Total Amount (INR) *',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                onChanged: (val) {
                  setState(() {});
                },
                validator: (v) {
                  if (_lineItems.isEmpty && (v == null || v.trim().isEmpty || double.tryParse(v) == null)) {
                    return 'Please enter valid total expense amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Payment Mode selector
            ref.watch(bankAccountsListProvider).when(
              data: (accounts) {
                final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                final dropdownItems = <DropdownMenuItem<String>>[
                  const DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  const DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  const DropdownMenuItem(value: 'Card', child: Text('Card')),
                  const DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  ...activeAccounts.map((acc) => DropdownMenuItem(
                    value: acc.accountName,
                    child: Text(acc.accountName ?? ''),
                  )),
                ];

                if (_selectedPaymentMode != null && !dropdownItems.any((item) => item.value == _selectedPaymentMode)) {
                  dropdownItems.add(DropdownMenuItem(value: _selectedPaymentMode, child: Text(_selectedPaymentMode)));
                }

                return DropdownButtonFormField<String>(
                  value: _selectedPaymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment_rounded),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: dropdownItems,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPaymentMode = val;
                      });
                    }
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => DropdownButtonFormField<String>(
                value: _selectedPaymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment_rounded),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPaymentMode = val;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Round Off Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Round Off:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (_customRoundOff != null)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.blue),
                        tooltip: 'Reset to Auto Round Off',
                        onPressed: () {
                          setState(() {
                            _customRoundOff = null;
                          });
                        },
                      ),
                  ],
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: _roundOff.toStringAsFixed(2),
                    key: ValueKey('roundoff_${_customRoundOff}_$_roundOff'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() {
                          _customRoundOff = parsed;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Grand Total Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FINAL PAYABLE TOTAL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                  ),
                  Text(
                    '₹${_grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Remarks field
            TextFormField(
              controller: _remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks / Notes (Optional)',
                prefixIcon: Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchableCategoryDropdown extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const SearchableCategoryDropdown({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SearchableCategoryDropdown> createState() => _SearchableCategoryDropdownState();
}

class _SearchableCategoryDropdownState extends State<SearchableCategoryDropdown> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedCategory);
  }

  @override
  void didUpdateWidget(covariant SearchableCategoryDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _controller.text = widget.selectedCategory;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (cat) => cat,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return widget.categories;
        }
        final query = textEditingValue.text.toLowerCase();
        return widget.categories.where((c) => c.toLowerCase().contains(query));
      },
      onSelected: (cat) {
        widget.onChanged(cat);
        FocusScope.of(context).unfocus();
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final cat = options.elementAt(index);
                  return ListTile(
                    title: Text(cat),
                    onTap: () => onSelected(cat),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Expense Category *',
            prefixIcon: Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );
      },
    );
  }
}
