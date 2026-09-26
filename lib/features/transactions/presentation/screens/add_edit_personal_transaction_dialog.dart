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
import 'package:business_sahaj_erp/core/widgets/searchable_bottom_sheet.dart';
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
      await ref.read(transactionRepositoryProvider).saveTransaction(txn);
    } else {
      await ref.read(transactionRepositoryProvider).saveTransaction(txn);
    }
    
    ref.invalidate(filteredTransactionsProvider);
    ref.invalidate(transactionTotalsProvider);
    ref.invalidate(recentTransactionsProvider);
    
    if (mounted) Navigator.pop(context);
  }

  Future<Category?> _addCategory(String parentUuid, {bool isTag = false}) async {
    final tc = TextEditingController();
    final addedCat = await showDialog<Category?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTag ? 'New Tag' : (parentUuid.isEmpty ? 'New Category' : 'New Sub-Category')),
        content: TextField(
          controller: tc,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (tc.text.trim().isEmpty) return;
              final newCat = Category()
                ..uuid = const Uuid().v4()
                ..categoryName = tc.text.trim()
                ..categoryType = isTag ? 'Tag' : (_type == 'Income' ? 'Income' : 'Expense')
                ..isPersonalVault = true;
              
              if (parentUuid.isNotEmpty && _selectedCategory != null) {
                 newCat.parentCategory.value = _selectedCategory;
              }
              await ref.read(categoryRepositoryProvider).create(newCat);
              if (parentUuid.isNotEmpty && _selectedCategory != null) {
                 final isar = ref.read(databaseServiceProvider).isar;
                 await isar.writeTxn(() async {
                   await newCat.parentCategory.save();
                 });
              }
              ref.invalidate(categoriesListProvider);
              Navigator.pop(ctx, newCat);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
    if (addedCat != null) setState(() {});
    return addedCat;
  }

  Future<BankAccount?> _addAccount() async {
    final tcName = TextEditingController();
    final tcBal = TextEditingController();
    final addedAcc = await showDialog<BankAccount?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tcName,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Account Name (e.g. HDFC Bank)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tcBal,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Opening Balance (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (tcName.text.trim().isEmpty) return;
              final newAcc = BankAccount()
                ..uuid = const Uuid().v4()
                ..accountName = tcName.text.trim()
                ..openingBalance = double.tryParse(tcBal.text.trim()) ?? 0.0
                ..currentBalance = double.tryParse(tcBal.text.trim()) ?? 0.0
                ..isPersonalVault = true;
              
              await ref.read(bankAccountRepositoryProvider).create(newAcc);
              ref.invalidate(bankAccountsListProvider);
              Navigator.pop(ctx, newAcc);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
    if (addedAcc != null) setState(() {});
    return addedAcc;
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
                subtitle: const Text('Tap to add/manage tags', style: TextStyle(color: Colors.blue)),
                onTap: _openTagsSelector,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTagsSelector() async {
    final categoriesAsync = ref.read(categoriesListProvider);
    categoriesAsync.whenData((categories) async {
      final tagCategories = categories.where((c) => c.isPersonalVault && c.categoryType == 'Tag').toList();
      
      final selectedTags = await SearchableBottomSheet.showMulti<Category>(
        context: context,
        title: 'Select Tags',
        items: tagCategories,
        itemAsString: (c) => c.categoryName ?? '',
        initialSelectedItems: tagCategories.where((c) => _tags.contains(c.categoryName)).toList(),
        onAddPressed: () async {
          final newTag = await _addCategory('', isTag: true);
          if (newTag != null && mounted) {
            Navigator.pop(context); // Close current sheet
            setState(() {
              if (newTag.categoryName != null && !_tags.contains(newTag.categoryName)) {
                 _tags.add(newTag.categoryName!);
              }
            });
            _openTagsSelector(); // Reopen updated sheet
          }
        },
      );
      
      if (selectedTags != null) {
        setState(() {
          _tags = selectedTags.map((c) => c.categoryName ?? '').toList();
        });
      }
    });
  }

  Widget _buildCategoryDropdown(String label, {required bool isSub}) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    return categoriesAsync.when(
      data: (categories) {
        List<Category> filtered = [];
        if (isSub) {
           filtered = categories.where((c) => c.isPersonalVault && c.categoryType == (_type == 'Income' ? 'Income' : 'Expense') && c.parentCategory.value?.uuid == _selectedCategory?.uuid).toList();
        } else {
           // Parent categories shouldn't have a parent assigned
           filtered = categories.where((c) => c.isPersonalVault && c.categoryType == (_type == 'Income' ? 'Income' : 'Expense') && c.parentCategory.value == null).toList();
        }
        
        final selectedVal = isSub ? _selectedSubCategory : _selectedCategory;
        
        return InkWell(
          onTap: () async {
            if (isSub && _selectedCategory == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Category first.')));
              return;
            }
            final res = await SearchableBottomSheet.showSingle<Category>(
              context: context,
              title: 'Select $label',
              items: filtered,
              selectedItem: selectedVal,
              itemAsString: (c) => c.categoryName ?? '',
              onAddPressed: () async {
                final newCat = await _addCategory(isSub ? 'sub' : '');
                if (newCat != null && mounted) {
                  Navigator.pop(context, newCat);
                }
              },
            );
            if (res != null) {
              setState(() {
                if (isSub) {
                  _selectedSubCategory = res;
                } else {
                  _selectedCategory = res;
                  _selectedSubCategory = null; // reset subcat on parent change
                }
              });
            }
          },
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(isSub ? Icons.subdirectory_arrow_right : Icons.category),
            title: Text(selectedVal?.categoryName ?? 'Select $label', style: TextStyle(color: selectedVal == null ? Colors.grey : null)),
            trailing: const Icon(Icons.arrow_drop_down),
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
        return InkWell(
          onTap: () async {
            final res = await SearchableBottomSheet.showSingle<BankAccount>(
              context: context,
              title: 'Select $label',
              items: filtered,
              selectedItem: selected,
              itemAsString: (a) => a.accountName ?? '',
              onAddPressed: () async {
                final newAcc = await _addAccount();
                if (newAcc != null && mounted) {
                  Navigator.pop(context, newAcc);
                }
              },
            );
            if (res != null) {
              onChanged(res);
            }
          },
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance),
            title: Text(selected?.accountName ?? 'Select $label', style: TextStyle(color: selected == null ? Colors.grey : null)),
            trailing: const Icon(Icons.arrow_drop_down),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading accounts'),
    );
  }
}
