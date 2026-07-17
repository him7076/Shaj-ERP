import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/providers/expense_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:isar/isar.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final String? expenseUuid;
  const AddEditExpenseScreen({Key? key, this.expenseUuid}) : super(key: key);

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedCategory = 'Office Expense';
  String _selectedPaymentMode = 'Cash';
  DateTime _expenseDate = DateTime.now();

  Expense? _existingExpense;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
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
        _amountController.text = expense.amount?.toString() ?? '';
        _remarksController.text = expense.remarks ?? '';
        _selectedCategory = expense.category ?? 'Office Expense';
        _selectedPaymentMode = expense.paymentMode ?? 'Cash';
        _expenseDate = expense.expenseDate ?? DateTime.now();
      }
    }
    setState(() {});
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
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _saveExpense() async {
    if (_formKey.currentState?.validate() ?? false) {
      final amt = double.tryParse(_amountController.text) ?? 0.0;
      if (amt <= 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid expense amount.')),
        );
        return;
      }

      final expense = _existingExpense ?? Expense();
      expense
        ..category = _selectedCategory
        ..amount = amt
        ..expenseDate = _expenseDate
        ..paymentMode = _selectedPaymentMode
        ..remarks = _remarksController.text.trim();

      if (_existingExpense == null) {
        expense.uuid = '${DateTime.now().millisecondsSinceEpoch}';
      }

      final success = await ref
          .read(expenseNotifierProvider.notifier)
          .saveExpense(expense);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_existingExpense == null ? 'Expense logged successfully.' : 'Expense updated successfully.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Record Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveExpense,
            tooltip: 'Save',
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
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
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
                            icon: const Icon(Icons.add),
                            tooltip: 'Add Category',
                            onPressed: _showAddCategoryDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Amount field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (INR)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter expense amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid decimal value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Payment Mode
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

                          // Safety fallback check to prevent dropdown value crash
                          if (_selectedPaymentMode != null && !dropdownItems.any((item) => item.value == _selectedPaymentMode)) {
                            dropdownItems.add(DropdownMenuItem(value: _selectedPaymentMode, child: Text(_selectedPaymentMode)));
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedPaymentMode,
                            decoration: const InputDecoration(
                              labelText: 'Payment Method',
                              prefixIcon: Icon(Icons.payment_rounded),
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
                      const SizedBox(height: 20),

                      // Expense Date
                      InkWell(
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
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_expenseDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Remarks
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Details',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveExpense,
                child: const Text('SAVE EXPENSE LOG'),
              ),
            ],
          ),
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
            labelText: 'Expense Category',
            prefixIcon: Icon(Icons.category_outlined),
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }
}
