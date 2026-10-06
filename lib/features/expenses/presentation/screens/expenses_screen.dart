import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_item_collection.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/providers/expense_providers.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/screens/add_edit_expense_screen.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/widgets/expense_category_dialog.dart';
import 'package:business_sahaj_erp/core/services/expense_excel_import_service.dart';
import 'package:business_sahaj_erp/core/services/expense_excel_export_service.dart';
import 'package:business_sahaj_erp/core/utils/excel_download_helper.dart';
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  final bool createImmediately;
  const ExpensesScreen({Key? key, this.createImmediately = false}) : super(key: key);

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  String _selectedCategoryFilter = 'All';
  bool _showSearch = false;
  int _displayLimit = 50;

  bool _isSelectionMode = false;
  final Set<int> _selectedExpenseIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.createImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditExpenseScreen(),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.single.bytes == null) {
        return;
      }

      final bytes = result.files.single.bytes!;
      final dbService = ref.read(databaseServiceProvider);

      final importResult = await ImportProgressModal.show<ImportExpenseResult>(
        context: context,
        title: 'Importing Operating Expenses',
        task: (onProgress) => ExpenseExcelImportService.importExpensesFromBytes(
          bytes,
          dbService,
          onProgress: onProgress,
        ),
      );

      if (importResult != null && mounted) {
        ref.invalidate(expenseListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${importResult.totalExpensesImported} expenses!'
              '${importResult.errors.isNotEmpty ? " (${importResult.errors.length} errors)" : ""}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import expenses: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadSampleTemplate() async {
    try {
      final bytes = ExpenseExcelImportService.generateSampleTemplate();
      if (bytes != null) {
        await ExcelDownloadHelper.downloadExcel(
          bytes,
          'Expense_Import_Template.xlsx',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense Excel template downloaded successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating template: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExpensesExcel() async {
    try {
      final expenses = await ref.read(expenseRepositoryProvider).getAll();
      final bytes = ExpenseExcelExportService.exportExpensesToExcel(expenses);
      if (bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate export file.')));
        return;
      }
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await ExcelDownloadHelper.downloadExcel(bytes, 'Expenses_Export_$dateStr.xlsx');
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expenses Exported Successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting expenses: $e')),
      );
    }
  }

  Future<void> _deleteSelectedExpenses() async {
    if (_selectedExpenseIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Expenses?'),
        content: Text('Are you sure you want to delete ${_selectedExpenseIds.length} expenses?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(expenseNotifierProvider.notifier);
      for (final id in _selectedExpenseIds) {
        await notifier.deleteExpense(id);
      }
      setState(() {
        _isSelectionMode = false;
        _selectedExpenseIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected expenses deleted.')));
      }
    }
  }

  void _handleBack() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/dashboard');
    }
  }

  // Item detailed transaction modal
  void _showItemDetailModal(BuildContext context, String itemName, List<Expense> allExpenses) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> itemTransactions = [];
    double totalSpent = 0.0;

    for (var exp in allExpenses) {
      if (exp.itemsJson != null && exp.itemsJson!.isNotEmpty) {
        try {
          final List<dynamic> items = jsonDecode(exp.itemsJson!);
          for (var item in items) {
            final name = (item['name'] ?? item['itemName'] ?? '').toString();
            if (name.toLowerCase() == itemName.toLowerCase()) {
              final qty = (item['quantity'] as num?)?.toDouble() ?? (item['qty'] as num?)?.toDouble() ?? 1.0;
              final rate = (item['rate'] as num?)?.toDouble() ?? (item['price'] as num?)?.toDouble() ?? 0.0;
              final amt = (item['amount'] as num?)?.toDouble() ?? (qty * rate);
              totalSpent += amt;

              itemTransactions.add({
                'expense': exp,
                'qty': qty,
                'rate': rate,
                'amount': amt,
              });
            }
          }
        } catch (_) {}
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx2, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(itemName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${itemTransactions.length} Transactions Found', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Spent', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(currencyFormat.format(totalSpent), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: itemTransactions.isEmpty
                  ? const Center(child: Text('No transactions recorded for this item yet.'))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: itemTransactions.length,
                      itemBuilder: (ctx3, idx) {
                        final tx = itemTransactions[idx];
                        final Expense exp = tx['expense'];
                        final dateStr = exp.expenseDate != null ? DateFormat('dd MMM yyyy').format(exp.expenseDate!) : 'N/A';
                        return NeuCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(exp.voucherNo ?? 'Voucher #${exp.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(currencyFormat.format(tx['amount']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Qty: ${tx['qty']} | Rate: ₹${tx['rate']} | Category: ${exp.category ?? "General"}\nDate: $dateStr • Party: ${exp.partyName ?? "N/A"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditExpenseScreen(expenseUuid: exp.uuid),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Category detailed transaction modal
  void _showCategoryDetailModal(BuildContext context, String categoryName, List<Expense> allExpenses) {
    final theme = Theme.of(context);
    final categoryExpenses = allExpenses.where((e) => (e.category ?? '').toLowerCase() == categoryName.toLowerCase()).toList();
    final double totalSpent = categoryExpenses.fold(0.0, (sum, e) => sum + (e.amount ?? 0.0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx2, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: $categoryName', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${categoryExpenses.length} Expense Logs Found', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Category Total', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(currencyFormat.format(totalSpent), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: categoryExpenses.isEmpty
                  ? const Center(child: Text('No expense logs for this category.'))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: categoryExpenses.length,
                      itemBuilder: (ctx3, idx) {
                        final exp = categoryExpenses[idx];
                        final dateStr = exp.expenseDate != null ? DateFormat('dd MMM yyyy').format(exp.expenseDate!) : 'N/A';
                        return NeuCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(exp.voucherNo ?? 'Voucher #${exp.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(currencyFormat.format(exp.amount ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Payee: ${exp.partyName ?? "N/A"} • Payment Mode: ${exp.paymentMode ?? "Cash"}\nDate: $dateStr • Remarks: ${exp.remarks ?? "None"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditExpenseScreen(expenseUuid: exp.uuid),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expenseListProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    List<Expense> displayList = [];
    expensesAsync.whenData((list) {
      if (_selectedCategoryFilter != 'All') {
        displayList = list.where((e) => e.category?.toLowerCase() == _selectedCategoryFilter.toLowerCase()).toList();
      } else {
        displayList = list;
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: theme.colorScheme.background,
          appBar: _isSelectionMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedExpenseIds.clear();
                      });
                    },
                  ),
                  title: Text('${_selectedExpenseIds.length} Selected'),
                  actions: [
                    IconButton(
                      tooltip: 'Select All',
                      icon: const Icon(Icons.select_all),
                      onPressed: () {
                        setState(() {
                          if (_selectedExpenseIds.length == displayList.length) {
                            _selectedExpenseIds.clear();
                          } else {
                            _selectedExpenseIds.addAll(displayList.map((e) => e.id));
                          }
                        });
                      },
                    ),
                    if (_selectedExpenseIds.isNotEmpty)
                      IconButton(
                        tooltip: 'Delete Selected',
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: _deleteSelectedExpenses,
                      ),
                  ],
                )
              : AppBar(
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _handleBack,
                    tooltip: 'Back',
                  ),
                  toolbarHeight: isMobile ? 44 : 52,
                  title: _showSearch
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search remarks or category...',
                            isDense: true,
                          ),
                          onChanged: (val) {
                            ref.read(expenseSearchQueryProvider.notifier).state = val;
                          },
                        )
                      : Text(
                          'Operating Expenses',
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  actions: [
                    // 🔍 Search Toggle Button
                    IconButton(
                      tooltip: 'Search Expenses',
                      icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, size: 20),
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            ref.read(expenseSearchQueryProvider.notifier).state = '';
                          }
                        });
                      },
                    ),
                    // 3-dot menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      tooltip: 'Excel & Options',
                      onSelected: (val) {
                        if (val == 'import_excel') {
                          _importFromExcel();
                        } else if (val == 'download_template') {
                          _downloadSampleTemplate();
                        } else if (val == 'export_excel') {
                          _exportExpensesExcel();
                        } else if (val == 'select_delete') {
                          setState(() {
                            _isSelectionMode = true;
                          });
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'import_excel',
                          child: Row(
                            children: [
                              Icon(Icons.file_upload_outlined, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Import Expenses from Excel'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'download_template',
                          child: Row(
                            children: [
                              Icon(Icons.download_rounded, color: Colors.blue, size: 18),
                              SizedBox(width: 8),
                              Text('Download Sample Excel Template'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export_excel',
                          child: Row(
                            children: [
                              Icon(Icons.ios_share_rounded, color: Colors.purple, size: 18),
                              SizedBox(width: 8),
                              Text('Export Expenses to Excel'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'select_delete',
                          child: Row(
                            children: [
                              Icon(Icons.checklist_rounded, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text('Select and Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Transactions', icon: Icon(Icons.receipt_long_outlined, size: 18)),
                      Tab(text: 'Items', icon: Icon(Icons.shopping_bag_outlined, size: 18)),
                      Tab(text: 'Categories', icon: Icon(Icons.category_outlined, size: 18)),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditExpenseScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Record Expense'),
          ),
          body: TabBarView(
            children: [
              // TAB 1: TRANSACTIONS LIST VIEW
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Horizontal Category Chip filters
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: [
                        'All',
                        'Rent',
                        'Salaries',
                        'Utilities',
                        'Tea & Snacks',
                        'Office Expense',
                        'Other'
                      ].map((cat) {
                        final isSelected = _selectedCategoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryFilter = selected ? cat : 'All';
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Expanded(
                    child: expensesAsync.when(
                      data: (list) {
                        if (displayList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No expenses logged matching filters.',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddEditExpenseScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Record Expense'),
                                ),
                              ],
                            ),
                          );
                        }

                        // Compute total
                        final double totalExp = displayList.fold(0.0, (sum, e) => sum + (e.amount ?? 0.0));
                        final visibleList = displayList.take(_displayLimit).toList();
                        final hasMore = displayList.length > _displayLimit;

                        return Column(
                          children: [
                            // Total Summary Banner
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Operational Outflow',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(totalExp),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // List
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: visibleList.length + (hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == visibleList.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _displayLimit += 50;
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.arrow_downward_rounded),
                                          label: Text(
                                            'Load More Expenses (Showing ${_displayLimit} of ${displayList.length})',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final expense = visibleList[index];
                                  final dateStr = expense.expenseDate != null
                                      ? DateFormat('dd MMM yyyy').format(expense.expenseDate!)
                                      : 'N/A';
                                  
                                  final isSelected = _selectedExpenseIds.contains(expense.id);

                                  return NeuCard(
                                    elevation: isSelected ? 2 : 0,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outlineVariant.withOpacity(0.4),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              width: 6,
                                              color: theme.colorScheme.error,
                                            ),
                                            Expanded(
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.all(16),
                                                leading: _isSelectionMode
                                                    ? Checkbox(
                                                        value: isSelected,
                                                        onChanged: (val) {
                                                          setState(() {
                                                            if (val == true) {
                                                              _selectedExpenseIds.add(expense.id);
                                                            } else {
                                                              _selectedExpenseIds.remove(expense.id);
                                                            }
                                                          });
                                                        },
                                                      )
                                                    : CircleAvatar(
                                                        backgroundColor: theme.colorScheme.error.withOpacity(0.08),
                                                        child: Icon(Icons.arrow_outward_rounded, color: theme.colorScheme.error, size: 20),
                                                      ),
                                                title: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      expense.category ?? 'Uncategorised',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                    Text(
                                                      currencyFormat.format(expense.amount ?? 0.0),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.colorScheme.error,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Wrap(
                                                    spacing: 8,
                                                    runSpacing: 4,
                                                    alignment: WrapAlignment.spaceBetween,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                      Text(
                                                        '${expense.remarks ?? "No remarks"}  •  $dateStr',
                                                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          expense.paymentMode ?? 'Cash',
                                                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                onTap: () {
                                                  if (_isSelectionMode) {
                                                    setState(() {
                                                      if (isSelected) {
                                                        _selectedExpenseIds.remove(expense.id);
                                                      } else {
                                                        _selectedExpenseIds.add(expense.id);
                                                      }
                                                    });
                                                  } else {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => AddEditExpenseScreen(
                                                          expenseUuid: expense.uuid,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                onLongPress: () {
                                                  if (!_isSelectionMode) {
                                                    setState(() {
                                                      _isSelectionMode = true;
                                                      _selectedExpenseIds.add(expense.id);
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(
                        child: Text('Failed to load expenses: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ],
              ),

              // TAB 2: EXPENSE ITEMS VIEW
              expensesAsync.when(
                data: (allExpenses) {
                  return FutureBuilder<List<ExpenseItem>>(
                    future: ref.read(databaseServiceProvider).isar.collection<ExpenseItem>().filter().isDeletedEqualTo(false).findAll(),
                    builder: (context, snapshot) {
                      final masterItems = snapshot.data ?? [];

                      // Aggregate totals per item name
                      final Map<String, double> itemSpentMap = {};
                      final Map<String, int> itemCountMap = {};

                      for (var exp in allExpenses) {
                        if (exp.itemsJson != null && exp.itemsJson!.isNotEmpty) {
                          try {
                            final List<dynamic> jsonItems = jsonDecode(exp.itemsJson!);
                            for (var item in jsonItems) {
                              final name = (item['name'] ?? item['itemName'] ?? '').toString().trim();
                              if (name.isNotEmpty) {
                                final qty = (item['quantity'] as num?)?.toDouble() ?? (item['qty'] as num?)?.toDouble() ?? 1.0;
                                final rate = (item['rate'] as num?)?.toDouble() ?? (item['price'] as num?)?.toDouble() ?? 0.0;
                                final amt = (item['amount'] as num?)?.toDouble() ?? (qty * rate);

                                itemSpentMap[name] = (itemSpentMap[name] ?? 0.0) + amt;
                                itemCountMap[name] = (itemCountMap[name] ?? 0) + 1;
                              }
                            }
                          } catch (_) {}
                        }
                      }

                      // Build merged items list (Master items + items from expense transactions)
                      final Set<String> allItemNames = {
                        ...masterItems.map((e) => e.itemName ?? '').where((n) => n.isNotEmpty),
                        ...itemSpentMap.keys,
                      };

                      if (allItemNames.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text('No Expense Items created yet.', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Expense Record'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddEditExpenseScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      final itemList = allItemNames.toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: itemList.length,
                        itemBuilder: (context, index) {
                          final itemName = itemList[index];
                          final totalSpent = itemSpentMap[itemName] ?? 0.0;
                          final txCount = itemCountMap[itemName] ?? 0;
                          final masterItem = masterItems.firstWhere(
                            (m) => (m.itemName ?? '').toLowerCase() == itemName.toLowerCase(),
                            orElse: () => ExpenseItem()..itemName = itemName,
                          );

                          return NeuCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(Icons.shopping_bag, color: theme.colorScheme.primary, size: 20),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      itemName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(totalSpent),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Default Rate: ₹${(masterItem.defaultRate ?? 0.0).toStringAsFixed(2)}  •  $txCount Transactions',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _showItemDetailModal(context, itemName, allExpenses),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              // TAB 3: EXPENSE CATEGORIES VIEW
              expensesAsync.when(
                data: (allExpenses) {
                  // Aggregate total per category
                  final Map<String, double> categorySpentMap = {};
                  final Map<String, int> categoryCountMap = {};

                  for (var exp in allExpenses) {
                    final cat = (exp.category ?? 'Uncategorised').trim();
                    categorySpentMap[cat] = (categorySpentMap[cat] ?? 0.0) + (exp.amount ?? 0.0);
                    categoryCountMap[cat] = (categoryCountMap[cat] ?? 0) + 1;
                  }

                  // Default preset categories + active categories
                  final Set<String> allCategories = {
                    'Rent',
                    'Salaries',
                    'Utilities',
                    'Tea & Snacks',
                    'Office Expense',
                    'Other',
                    ...categorySpentMap.keys,
                  };

                  final catList = allCategories.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: catList.length,
                    itemBuilder: (context, index) {
                      final catName = catList[index];
                      final totalSpent = categorySpentMap[catName] ?? 0.0;
                      final count = categoryCountMap[catName] ?? 0;

                      return NeuCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.15),
                            child: const Icon(Icons.category_rounded, color: Colors.orange, size: 20),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                currencyFormat.format(totalSpent),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: totalSpent > 0 ? Colors.red : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '$count Expense Logs Recorded',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showCategoryDetailModal(context, catName, allExpenses),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
