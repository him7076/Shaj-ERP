import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/widgets/calculator_dialog.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';
import 'package:isar/isar.dart';

class AddEditPersonalTransactionDialog extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final String? initialType; // 'Expense', 'Receipt' (Income), 'Transfer'

  const AddEditPersonalTransactionDialog({
    Key? key,
    this.transaction,
    this.initialType,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {Transaction? transaction, String? initialType}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        child: AddEditPersonalTransactionDialog(
          transaction: transaction,
          initialType: initialType,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddEditPersonalTransactionDialog> createState() => _AddEditPersonalTransactionDialogState();
}

class _AddEditPersonalTransactionDialogState extends ConsumerState<AddEditPersonalTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _remarksController = TextEditingController();
  final _tagsController = TextEditingController();

  String _type = 'Expense';
  DateTime _date = DateTime.now();

  Category? _selectedCategory;
  Category? _selectedSubCategory;
  
  BankAccount? _selectedAccount;
  BankAccount? _fromAccount; // For Transfer
  BankAccount? _toAccount; // For Transfer

  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final txn = widget.transaction!;
      _type = txn.transactionType ?? 'Expense';
      if (_type == 'Receipt' || _type == 'Other Income') _type = 'Income';
      
      _amountController.text = (txn.amount ?? 0).toStringAsFixed(2);
      _remarksController.text = txn.remarks ?? '';
      _date = txn.transactionDate ?? DateTime.now();
      _tags = List.from(txn.tags ?? []);
      _feeController.text = (txn.transferFee ?? 0).toStringAsFixed(2);

      // Loading linked entities is tricky without async init, so we'll just match them in the build method 
      // or load them if needed. For simplicity, we just rely on future builders or drop-downs to set them.
    } else {
      if (widget.initialType != null) {
        _type = widget.initialType == 'Receipt' ? 'Income' : widget.initialType!;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _remarksController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _openCalculator(TextEditingController controller) async {
    final val = double.tryParse(controller.text);
    final result = await CalculatorDialog.show(context, initialValue: val);
    if (result != null) {
      setState(() {
        controller.text = result.toStringAsFixed(2);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final txn = widget.transaction ?? Transaction();
    
    // Type mapping back to core app standard
    if (_type == 'Income') {
      txn.transactionType = 'Other Income';
    } else {
      txn.transactionType = _type;
    }
    
    txn.amount = double.tryParse(_amountController.text) ?? 0.0;
    txn.transactionDate = _date;
    txn.remarks = _remarksController.text.trim();
    txn.tags = _tags;
    txn.isPersonalVault = true;

    if (_type == 'Transfer') {
      txn.transferFee = double.tryParse(_feeController.text) ?? 0.0;
      txn.partyUuid = _fromAccount?.uuid;
      txn.partyName = _fromAccount?.accountName;
      txn.targetPartyUuid = _toAccount?.uuid;
      txn.targetPartyName = _toAccount?.accountName;
    } else {
      txn.partyUuid = _selectedAccount?.uuid;
      txn.partyName = _selectedAccount?.accountName;
      txn.categoryUuid = _selectedCategory?.uuid;
      txn.categoryName = _selectedCategory?.categoryName;
      txn.subCategoryUuid = _selectedSubCategory?.uuid;
      txn.subCategoryName = _selectedSubCategory?.categoryName;
    }
    
    // Need a transaction number if new
    if (txn.id == Isar.autoIncrement || txn.transactionNumber == null) {
      txn.transactionNumber = 'PV-${DateTime.now().millisecondsSinceEpoch}';
      txn.uuid ??= const Uuid().v4();
    }
    
    if (widget.transaction == null) {
      await ref.read(transactionRepositoryProvider).insertTransaction(txn);
    } else {
      await ref.read(transactionRepositoryProvider).updateTransaction(txn);
    }
    
    ref.invalidate(transactionListProvider);
    ref.invalidate(transactionTotalsProvider);
    ref.invalidate(recentTransactionsProvider);
    
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addCategory(String parentUuid) async {
    // A quick way to add category without leaving the screen
    final tc = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(parentUuid.isEmpty ? 'New Category' : 'New Sub-Category'),
        content: TextField(
          controller: tc,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (tc.text.trim().isEmpty) return;
              final newCat = Category()
                ..uuid = const Uuid().v4()
                ..categoryName = tc.text.trim()
                ..categoryType = _type == 'Income' ? 'Income' : 'Expense'
                ..isPersonalVault = true;
              
              if (parentUuid.isNotEmpty) {
                 // In a real app we'd link to parent. We will rely on categoryType and maybe description hack for now.
              }
              await ref.read(categoryRepositoryProvider).insertCategory(newCat);
              ref.invalidate(categoriesListProvider);
              Navigator.pop(ctx, true);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
    if (added == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color headerColor = Colors.grey;
    if (_type == 'Income') headerColor = Colors.green.shade700;
    if (_type == 'Expense') headerColor = Colors.red.shade700;
    if (_type == 'Transfer') headerColor = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'New $_type' : 'Edit $_type'),
        backgroundColor: headerColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selector
              Row(
                children: ['Income', 'Expense', 'Transfer'].map((t) {
                  final isSelected = _type == t;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Center(child: Text(t)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _type = t);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text(DateFormat('dd MMM yyyy, hh:mm a').format(_date)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null && mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_date),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _date = DateTime(
                          pickedDate.year, pickedDate.month, pickedDate.day,
                          pickedTime.hour, pickedTime.minute
                        );
                      });
                    }
                  }
                },
              ),
              const Divider(),
              
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.currency_rupee, size: 32),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calculate, color: Colors.blue, size: 32),
                    onPressed: () => _openCalculator(_amountController),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const Divider(),

              if (_type != 'Transfer') ...[
                // Category
                _buildCategoryDropdown('Category', isSub: false),
                const Divider(),
                // Sub Category
                _buildCategoryDropdown('Sub-Category', isSub: true),
                const Divider(),
                // Account
                _buildAccountDropdown('Account', (acc) => setState(() => _selectedAccount = acc), _selectedAccount),
                const Divider(),
              ] else ...[
                _buildAccountDropdown('From Account', (acc) => setState(() => _fromAccount = acc), _fromAccount),
                const Divider(),
                _buildAccountDropdown('To Account', (acc) => setState(() => _toAccount = acc), _toAccount),
                const Divider(),
                TextFormField(
                  controller: _feeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Transfer Fee (₹)',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.money_off),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calculate, color: Colors.blue),
                      onPressed: () => _openCalculator(_feeController),
                    ),
                  ),
                ),
                const Divider(),
              ],

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const Divider(),

              // Tags
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.label),
                title: Wrap(
                  spacing: 8,
                  children: _tags.map((t) => Chip(
                    label: Text(t),
                    onDeleted: () => setState(() => _tags.remove(t)),
                  )).toList(),
                ),
                subtitle: TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    hintText: 'Add tag...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_tagsController.text.trim().isNotEmpty) {
                          setState(() {
                            if (!_tags.contains(_tagsController.text.trim())) {
                              _tags.add(_tagsController.text.trim());
                            }
                            _tagsController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  onFieldSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        if (!_tags.contains(val.trim())) _tags.add(val.trim());
                        _tagsController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(String label, {required bool isSub}) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    return categoriesAsync.when(
      data: (categories) {
        // Filter for personal vault and type
        final filtered = categories.where((c) => c.isPersonalVault && c.categoryType == (_type == 'Income' ? 'Income' : 'Expense')).toList();
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(isSub ? Icons.subdirectory_arrow_right : Icons.category),
          title: DropdownButtonHideUnderline(
            child: DropdownButton<Category>(
              isExpanded: true,
              hint: Text('Select $label'),
              value: isSub ? _selectedSubCategory : _selectedCategory,
              items: filtered.map((c) => DropdownMenuItem(value: c, child: Text(c.categoryName ?? ''))).toList(),
              onChanged: (val) {
                setState(() {
                  if (isSub) {
                    _selectedSubCategory = val;
                  } else {
                    _selectedCategory = val;
                  }
                });
              },
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _addCategory(isSub ? 'sub' : ''),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading categories'),
    );
  }

  Widget _buildAccountDropdown(String label, Function(BankAccount) onChanged, BankAccount? selected) {
    final accountsAsync = ref.watch(bankAccountsListProvider);
    return accountsAsync.when(
      data: (accounts) {
        final filtered = accounts.where((a) => a.isPersonalVault).toList();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_balance),
          title: DropdownButtonHideUnderline(
            child: DropdownButton<BankAccount>(
              isExpanded: true,
              hint: Text('Select $label'),
              value: selected,
              items: filtered.map((a) => DropdownMenuItem(value: a, child: Text(a.accountName ?? ''))).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
               // In real app, route to add account, but for now we'll notify user to add via bank accounts screen.
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add accounts from the Bank Accounts menu.')));
            },
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading accounts'),
    );
  }
}
