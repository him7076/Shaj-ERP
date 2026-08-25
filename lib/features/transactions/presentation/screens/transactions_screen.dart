import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_transaction_dialog.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_credit_note_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_debit_note_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/add_edit_order_screen.dart';
import 'package:business_sahaj_erp/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/receipt_excel_import_service.dart';
import 'package:business_sahaj_erp/core/utils/excel_download_helper.dart';
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? lockedType;
  final bool createImmediately;
  const TransactionsScreen({Key? key, this.lockedType, this.createImmediately = false}) : super(key: key);

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _showSearch = false;
  bool _showFilter = false;
  int _displayLimit = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionSearchFilterProvider.notifier).state =
          ref.read(transactionSearchFilterProvider).copyWith(transactionType: widget.lockedType ?? 'All');
      
      if (widget.createImmediately) {
        if (widget.lockedType == 'Credit Note') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditCreditNoteScreen()),
          ).then((_) => ref.invalidate(filteredTransactionsProvider));
        } else if (widget.lockedType == 'Debit Note') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditDebitNoteScreen()),
          ).then((_) => ref.invalidate(filteredTransactionsProvider));
        } else {
          AddEditTransactionDialog.show(context, initialType: widget.lockedType);
        }
      }
      
      // Ensure initial limit matches
      ref.read(transactionSearchFilterProvider.notifier).update((state) => state.copyWith(limit: _displayLimit));
    });
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lockedType != oldWidget.lockedType) {
      ref.read(transactionSearchFilterProvider.notifier).state =
          ref.read(transactionSearchFilterProvider).copyWith(transactionType: widget.lockedType ?? 'All');
    }
  }

  void _openTransaction(BuildContext context, Transaction txn) {
    if (txn.transactionType == 'Sales') {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoiceUuid: txn.uuid ?? txn.id.toString())),
      ).then((changed) {
        if (changed == true) ref.invalidate(filteredTransactionsProvider);
      });
    } else if (txn.transactionType == 'Sales Order') {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => OrderDetailScreen(orderUuid: txn.uuid ?? txn.id.toString())),
      ).then((changed) {
        if (changed == true) ref.invalidate(filteredTransactionsProvider);
      });
    } else if (txn.transactionType == 'Purchase') {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => AddEditPurchaseScreen(purchaseUuid: txn.uuid)),
      ).then((changed) {
        if (changed == true) ref.invalidate(filteredTransactionsProvider);
      });
    } else if (txn.transactionType == 'Credit Note') {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AddEditCreditNoteScreen()),
      ).then((changed) {
        if (changed == true) ref.invalidate(filteredTransactionsProvider);
      });
    } else if (txn.transactionType == 'Debit Note') {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AddEditDebitNoteScreen()),
      ).then((changed) {
        if (changed == true) ref.invalidate(filteredTransactionsProvider);
      });
    } else if (txn.transactionType == 'Receipt' || txn.transactionType == 'Payment' || txn.transactionType == 'Other Income') {
      _showReceiptDetailModal(context, txn);
    } else {
      AddEditTransactionDialog.show(context, transaction: txn);
    }
  }

  void _showReceiptDetailModal(BuildContext context, Transaction txn) {
    final theme = Theme.of(context);
    final isIncoming = txn.transactionType == 'Receipt' || txn.transactionType == 'Other Income';
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateStr = txn.transactionDate != null ? DateFormat('dd MMMM yyyy').format(txn.transactionDate!) : 'N/A';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isIncoming ? Colors.green : Colors.red).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isIncoming ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${txn.transactionType ?? "Voucher"} Details',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Voucher No: ${txn.transactionNumber ?? "N/A"}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        currencyFormat.format(txn.amount ?? 0.0),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isIncoming ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Party Name'),
                  subtitle: Text(
                    (txn.partyName != null && txn.partyName!.trim().isNotEmpty
                        ? txn.partyName!
                        : (() {
                            try {
                              txn.party.loadSync();
                            } catch (_) {}
                            return txn.party.value?.partyName;
                          })() ??
                          'General Party'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Transaction Date'),
                  subtitle: Text(dateStr),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.payment_outlined),
                  title: const Text('Payment Mode'),
                  subtitle: Text(txn.paymentMode ?? 'Cash'),
                ),
                if (txn.referenceNumber != null && txn.referenceNumber!.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.numbers),
                    title: const Text('Reference / Ref No'),
                    subtitle: Text(txn.referenceNumber!),
                  ),
                if (txn.linkedBillNumber != null && txn.linkedBillNumber!.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.link),
                    title: const Text('Linked Invoice / Bill'),
                    subtitle: Text(txn.linkedBillNumber!),
                  ),
                if (txn.remarks != null && txn.remarks!.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.notes),
                    title: const Text('Remarks'),
                    subtitle: Text(txn.remarks!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: const Text('Are you sure you want to delete this voucher? Outstanding balance will be updated.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(transactionRepositoryProvider).deleteTransaction(txn);
                  ref.invalidate(filteredTransactionsProvider);
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Voucher'),
              onPressed: () {
                Navigator.pop(dialogContext);
                AddEditTransactionDialog.show(context, transaction: txn);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadReceiptSampleExcel() async {
    try {
      final sampleBytes = ReceiptExcelImportService.generateSampleTemplate();
      if (sampleBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate sample template.')),
        );
        return;
      }

      await ExcelDownloadHelper.downloadExcel(
        sampleBytes,
        'Receipts_Import_Sample_Template.xlsx',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📥 Sample Receipt Excel Template downloaded! Fill details and click Import Excel.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating sample Excel: $e')),
      );
    }
  }

  Future<void> _importReceiptExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null || fileBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected Excel file.')),
        );
        return;
      }

      final progressController = StreamController<ImportProgressState>.broadcast();
      BuildContext? progressDialogContext;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            progressDialogContext = ctx;
            return ImportProgressModal(
              title: 'Importing Receipts (Payment In)',
              progressStream: progressController.stream,
            );
          },
        );
      }

      final dbService = ref.read(databaseServiceProvider);
      final importResult = await ReceiptExcelImportService.importReceiptsFromBytes(
        fileBytes,
        dbService,
        onProgress: (current, total, statusMessage) {
          progressController.add(ImportProgressState(
            current: current,
            total: total,
            statusMessage: statusMessage,
          ));
        },
      );

      await progressController.close();
      if (progressDialogContext != null && progressDialogContext!.mounted) {
        Navigator.of(progressDialogContext!).pop();
      }

      ref.read(syncServiceProvider).syncAll();
      ref.invalidate(filteredTransactionsProvider);
      ref.invalidate(filteredPartiesProvider);
      ref.invalidate(dashboardAnalyticsProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  importResult.totalReceiptsImported > 0 ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: importResult.totalReceiptsImported > 0 ? Colors.green : Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Receipts Excel Import', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✨ Receipts Imported: ${importResult.totalReceiptsImported}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (importResult.errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Warnings / Errors:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...importResult.errors.map((e) => Text('• $e', style: const TextStyle(color: Colors.red, fontSize: 12))),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import Excel file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(transactionSearchFilterProvider);
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final totalsAsync = ref.watch(transactionTotalsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        toolbarHeight: isMobile ? 44 : 56,
        title: Text(
          widget.lockedType == 'Receipt'
              ? 'Receipts'
              : widget.lockedType == 'Payment'
                  ? 'Payments'
                  : widget.lockedType == 'Credit Note'
                      ? 'Credit Notes'
                      : widget.lockedType == 'Debit Note'
                          ? 'Debit Notes'
                          : widget.lockedType == 'Transfer'
                              ? 'Party Transfers'
                              : widget.lockedType == 'Other Income'
                                  ? 'Other Income'
                                  : 'Transactions',
          style: TextStyle(
            fontSize: isMobile ? 15 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Search Toggle Icon
          IconButton(
            tooltip: 'Search Transactions',
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              size: isMobile ? 20 : 22,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
          // Filter Toggle Icon
          IconButton(
            tooltip: 'Filter Types',
            icon: Icon(
              _showFilter ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
              size: isMobile ? 20 : 22,
              color: _showFilter ? theme.colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _showFilter = !_showFilter;
              });
            },
          ),
          if (widget.lockedType == 'Receipt' || widget.lockedType == null) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              tooltip: 'Receipt Tools',
              onSelected: (value) {
                if (value == 'sample') {
                  _downloadReceiptSampleExcel();
                } else if (value == 'import') {
                  _importReceiptExcel();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sample',
                  child: Row(
                    children: [
                      Icon(Icons.file_download_outlined, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Sample Excel Sheet'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_rounded, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Import Excel Receipts'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Metrics Row
          totalsAsync.when(
            data: (totals) {
              if (widget.lockedType != null) {
                Color typeColor = Colors.grey;
                IconData typeIcon = Icons.info_outline;
                String metricTitle = '';

                if (widget.lockedType == 'Receipt') {
                  typeColor = Colors.green;
                  typeIcon = Icons.arrow_downward;
                  metricTitle = 'Total Receipts Received';
                } else if (widget.lockedType == 'Payment') {
                  typeColor = Colors.red;
                  typeIcon = Icons.arrow_upward;
                  metricTitle = 'Total Payments Paid';
                } else if (widget.lockedType == 'Credit Note') {
                  typeColor = Colors.indigo;
                  typeIcon = Icons.assignment_return_rounded;
                  metricTitle = 'Total Credit Note Amount';
                } else if (widget.lockedType == 'Debit Note') {
                  typeColor = Colors.orange;
                  typeIcon = Icons.assignment_returned_rounded;
                  metricTitle = 'Total Debit Note Amount';
                } else if (widget.lockedType == 'Transfer') {
                  typeColor = Colors.teal;
                  typeIcon = Icons.swap_horiz;
                  metricTitle = 'Total Transferred Amount';
                } else if (widget.lockedType == 'Other Income') {
                  typeColor = Colors.blue;
                  typeIcon = Icons.monetization_on;
                  metricTitle = 'Total Other Income';
                } else if (widget.lockedType == 'Sales Order') {
                  typeColor = Colors.purple;
                  typeIcon = Icons.shopping_cart;
                  metricTitle = 'Total Order Amount';
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildMetricCard(
                    theme: theme,
                    title: metricTitle,
                    value: currencyFormat.format(totals.totalAmount),
                    icon: typeIcon,
                    color: typeColor,
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              theme: theme,
                              title: 'Inflow',
                              value: currencyFormat.format(totals.totalIn),
                              icon: Icons.arrow_downward,
                              color: Colors.green,
                              isMobile: true,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildMetricCard(
                              theme: theme,
                              title: 'Outflow',
                              value: currencyFormat.format(totals.totalOut),
                              icon: Icons.arrow_upward,
                              color: Colors.red,
                              isMobile: true,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildMetricCard(
                              theme: theme,
                              title: 'Net Flow',
                              value: currencyFormat.format((totals.totalIn - totals.totalOut).abs()),
                              icon: Icons.account_balance_wallet,
                              color: (totals.totalIn - totals.totalOut) >= 0 ? Colors.blue : Colors.orange,
                              isMobile: true,
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            theme: theme,
                            title: 'Total Inflow (Receipts & Sales)',
                            value: currencyFormat.format(totals.totalIn),
                            icon: Icons.arrow_downward,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            theme: theme,
                            title: 'Total Outflow (Payments & Expenses)',
                            value: currencyFormat.format(totals.totalOut),
                            icon: Icons.arrow_upward,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            theme: theme,
                            title: 'Net Cash Flow',
                            value: currencyFormat.format((totals.totalIn - totals.totalOut).abs()),
                            icon: Icons.account_balance_wallet,
                            color: (totals.totalIn - totals.totalOut) >= 0 ? Colors.blue : Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Collapsible Search & Filter Panel
          if (_showSearch || _showFilter || !isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: isMobile
                      ? Column(
                          children: [
                            if (_showSearch)
                              TextField(
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Search transaction no, party, remarks...',
                                  prefixIcon: Icon(Icons.search, size: 18),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  ref.read(transactionSearchFilterProvider.notifier).state =
                                      filter.copyWith(query: val);
                                },
                              ),
                            if (_showFilter) ...[
                              if (_showSearch) const Divider(height: 1),
                              
                              // Show All History Toggle
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Show All History (All Time)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: const Text('Default is 90 days for speed', style: TextStyle(fontSize: 11)),
                                value: filter.showAllHistory,
                                dense: true,
                                onChanged: (val) {
                                  ref.read(transactionSearchFilterProvider.notifier).state =
                                      filter.copyWith(showAllHistory: val);
                                },
                              ),

                              if (widget.lockedType == null) ...[
                                const Divider(height: 1),
                                DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: filter.transactionType,
                                    items: const [
                                      DropdownMenuItem(value: 'All', child: Text('All Types')),
                                      DropdownMenuItem(value: 'Sales', child: Text('Sales Invoice')),
                                      DropdownMenuItem(value: 'Sales Order', child: Text('Sales Order')),
                                      DropdownMenuItem(value: 'Purchase', child: Text('Purchase Bill')),
                                      DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                                      DropdownMenuItem(value: 'Receipt', child: Text('Received Payment (Receipt)')),
                                      DropdownMenuItem(value: 'Payment', child: Text('Made Payment (Payment)')),
                                      DropdownMenuItem(value: 'Credit Note', child: Text('Credit Note')),
                                      DropdownMenuItem(value: 'Debit Note', child: Text('Debit Note')),
                                      DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                                      DropdownMenuItem(value: 'Other Income', child: Text('Other Income')),
                                    ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(transactionSearchFilterProvider.notifier).state =
                                          filter.copyWith(transactionType: val);
                                    }
                                  },
                                ),
                              ),
                              ],
                            ],
                          ],
                        )
                    : Row(
                        children: [
                          // Search Query
                          Expanded(
                            flex: 3,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search transaction no, party, remarks...',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                ref.read(transactionSearchFilterProvider.notifier).state =
                                    filter.copyWith(query: val);
                              },
                            ),
                          ),
                          if (_showFilter || widget.lockedType == null) ...[
                            const VerticalDivider(),
                            
                            if (_showFilter)
                              Expanded(
                                flex: 2,
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('All Time History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  value: filter.showAllHistory,
                                  dense: true,
                                  onChanged: (val) {
                                    ref.read(transactionSearchFilterProvider.notifier).state =
                                        filter.copyWith(showAllHistory: val ?? false);
                                  },
                                ),
                              ),
                              
                            if (widget.lockedType == null) ...[
                              const VerticalDivider(),
                              
                              // Transaction Type filter
                              Expanded(
                              flex: 2,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: filter.transactionType,
                                    items: const [
                                      DropdownMenuItem(value: 'All', child: Text('All Types')),
                                      DropdownMenuItem(value: 'Receipt', child: Text('Received Payment (Receipt)')),
                                      DropdownMenuItem(value: 'Payment', child: Text('Made Payment (Payment)')),
                                      DropdownMenuItem(value: 'Sales', child: Text('Sales Invoice')),
                                      DropdownMenuItem(value: 'Sales Order', child: Text('Sales Order')),
                                      DropdownMenuItem(value: 'Purchase', child: Text('Purchase Bill')),
                                      DropdownMenuItem(value: 'Credit Note', child: Text('Credit Note')),
                                      DropdownMenuItem(value: 'Debit Note', child: Text('Debit Note')),
                                      DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                                      DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                                      DropdownMenuItem(value: 'Other Income', child: Text('Other Income')),
                                    ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(transactionSearchFilterProvider.notifier).state =
                                          filter.copyWith(transactionType: val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            ],
                          ],
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Data list
          Expanded(
            child: transactionsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Record Transaction" to add your first payment or receipt entry.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final visibleList = list.take(_displayLimit).toList();
                final hasMore = list.length >= _displayLimit;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleList.length + (hasMore ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                              ref.read(transactionSearchFilterProvider.notifier).update(
                                    (state) => state.copyWith(limit: _displayLimit),
                                  );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.arrow_downward_rounded),
                            label: Text(
                              'Load More Transactions (Showing ${_displayLimit} of ${list.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }

                    final txn = visibleList[index];
                    final isIncoming = txn.transactionType == 'Receipt' ||
                        txn.transactionType == 'Sales' ||
                        txn.transactionType == 'Other Income';
                    final isOutgoing = txn.transactionType == 'Payment' ||
                        txn.transactionType == 'Purchase' ||
                        txn.transactionType == 'Expense';

                    Color badgeColor = Colors.grey;
                    if (isIncoming) badgeColor = Colors.green;
                    if (isOutgoing) badgeColor = Colors.red;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 6,
                                color: badgeColor,
                              ),
                              Expanded(
                                child: ListTile(
                                  onTap: () => _openTransaction(context, txn),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: badgeColor.withOpacity(0.12),
                                    child: Text(
                                      (txn.partyName?.isNotEmpty == true) ? txn.partyName![0].toUpperCase() : 'T',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 16),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        txn.transactionNumber ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          txn.transactionType ?? '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Status Badge (PAID / UNPAID / PARTIALLY PAID / LINKED)
                                      Builder(
                                        builder: (context) {
                                          final statusStr = txn.paymentStatus ?? 
                                              (txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty ? 'LINKED' : 'CLEARED');
                                          
                                          Color statusBg = Colors.blue.withOpacity(0.12);
                                          Color statusFg = Colors.blue.shade800;

                                          if (statusStr.toUpperCase() == 'PAID' || statusStr.toUpperCase() == 'LINKED') {
                                            statusBg = Colors.green.withOpacity(0.15);
                                            statusFg = Colors.green.shade800;
                                          } else if (statusStr.toUpperCase() == 'PARTIALLY PAID') {
                                            statusBg = Colors.orange.withOpacity(0.15);
                                            statusFg = Colors.orange.shade900;
                                          } else if (statusStr.toUpperCase() == 'UNPAID') {
                                            statusBg = Colors.red.withOpacity(0.15);
                                            statusFg = Colors.red.shade800;
                                          } else if (statusStr.toUpperCase() == 'PENDING') {
                                            statusBg = Colors.amber.withOpacity(0.15);
                                            statusFg = Colors.amber.shade900;
                                          }

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              statusStr.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: statusFg,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Text(
                                        txn.partyName ?? (txn.transactionType == 'Expense' ? 'General Expense' : 'Other Income Ledger'),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      if (txn.remarks != null && txn.remarks!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(txn.remarks!, style: theme.textTheme.bodySmall),
                                      ],
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            'Date: ${txn.transactionDate != null ? DateFormat('dd MMM yyyy').format(txn.transactionDate!) : "N/A"}',
                                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Mode: ${txn.paymentMode ?? "Cash"}',
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurface,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (txn.transactionType == 'Receipt' || txn.transactionType == 'Payment') ...[
                                            InkWell(
                                              onTap: () => AddEditTransactionDialog.show(context, transaction: txn),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty
                                                      ? Colors.green.withOpacity(0.12)
                                                      : Colors.orange.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty
                                                        ? Colors.green
                                                        : Colors.orange,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty
                                                          ? Icons.link
                                                          : Icons.link_off,
                                                      size: 10,
                                                      color: txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty
                                                          ? Colors.green[800]
                                                          : Colors.orange[800],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty
                                                          ? 'Linked: ${txn.linkedBillNumber ?? "Yes"}'
                                                          : 'Tap to Link Bills',
                                                      style: TextStyle(
                                                        color: txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty
                                                            ? Colors.green[800]
                                                            : Colors.orange[800],
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currencyFormat.format(txn.amount ?? 0.0),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        onSelected: (action) async {
                                          if (action == 'edit') {
                                             _openTransaction(context, txn);
                                           } else if (action == 'link') {
                                             AddEditTransactionDialog.show(context, transaction: txn);
                                           } else if (action == 'receive_payment') {
                                             AddEditTransactionDialog.show(
                                               context,
                                               initialType: 'Receipt',
                                               initialPartyName: txn.partyName,
                                               initialPartyUuid: txn.partyUuid,
                                               initialBillUuid: txn.uuid,
                                               initialBillNumber: txn.transactionNumber,
                                               initialAmount: (txn.amount ?? 0.0) - (txn.amount != null ? 0.0 : 0.0), // Need pending amount, but txn doesn't have it directly. I'll just pass full amount.
                                             );
                                           } else if (action == 'make_payment') {
                                             AddEditTransactionDialog.show(
                                               context,
                                               initialType: 'Payment',
                                               initialPartyName: txn.partyName,
                                               initialPartyUuid: txn.partyUuid,
                                               initialBillUuid: txn.uuid,
                                               initialBillNumber: txn.transactionNumber,
                                               initialAmount: txn.amount ?? 0.0,
                                             );
                                           } else if (action == 'delete') {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Transaction'),
                                                content: const Text('Are you sure you want to delete this transaction? This will revert any changes made to the outstanding balances and invoice payments.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await ref.read(transactionRepositoryProvider).deleteTransaction(txn);
                                              ref.invalidate(filteredTransactionsProvider);
                                              ref.invalidate(dashboardAnalyticsProvider);
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit, size: 20),
                                              title: Text('Edit'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          if (txn.transactionType == 'Receipt' || txn.transactionType == 'Payment')
                                            const PopupMenuItem(
                                              value: 'link',
                                              child: ListTile(
                                                leading: Icon(Icons.link, size: 20),
                                                title: Text('Link to Bills'),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          if (txn.transactionType == 'Sales')
                                            const PopupMenuItem(
                                              value: 'receive_payment',
                                              child: ListTile(
                                                leading: Icon(Icons.download_rounded, size: 20, color: Colors.green),
                                                title: Text('Receive Payment', style: TextStyle(color: Colors.green)),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          if (txn.transactionType == 'Purchase')
                                            const PopupMenuItem(
                                              value: 'make_payment',
                                              child: ListTile(
                                                leading: Icon(Icons.upload_rounded, size: 20, color: Colors.red),
                                                title: Text('Make Payment', style: TextStyle(color: Colors.red)),
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(Icons.delete, color: Colors.red, size: 20),
                                              title: Text('Delete', style: TextStyle(color: Colors.red)),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading transactions: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (widget.lockedType == 'Credit Note') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEditCreditNoteScreen()),
            ).then((_) => ref.invalidate(filteredTransactionsProvider));
          } else if (widget.lockedType == 'Debit Note') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEditDebitNoteScreen()),
            ).then((_) => ref.invalidate(filteredTransactionsProvider));
          } else {
            AddEditTransactionDialog.show(context, initialType: widget.lockedType);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(widget.lockedType == 'Receipt'
            ? 'Record Receipt'
            : widget.lockedType == 'Payment'
                ? 'Record Payment'
                : widget.lockedType == 'Credit Note'
                    ? 'New Credit Note'
                    : widget.lockedType == 'Debit Note'
                        ? 'New Debit Note'
                        : widget.lockedType == 'Transfer'
                            ? 'New Transfer'
                            : widget.lockedType == 'Other Income'
                                ? 'Record Income'
                                : 'New Entry'),
      ),
    );
  }

  Widget _buildMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isMobile = false,
  }) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onBackground,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: () => AddEditTransactionDialog.show(context, initialType: type),
      backgroundColor: color.withOpacity(0.06),
      side: BorderSide(color: color.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
