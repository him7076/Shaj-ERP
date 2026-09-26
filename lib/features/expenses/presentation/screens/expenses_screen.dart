import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/providers/expense_providers.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/screens/add_edit_expense_screen.dart';
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

    return Scaffold(
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
          : AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
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
            tooltip: 'Excel Options',
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Horizontal Category Chip filters
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 8),

          // Expenses List
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
    );
  }
}
