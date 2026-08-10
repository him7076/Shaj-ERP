import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:printing/printing.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/add_edit_invoice_screen.dart';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/core/services/sales_excel_import_service.dart';
import 'package:business_sahaj_erp/core/services/purchase_excel_import_service.dart';
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';

import 'package:business_sahaj_erp/core/utils/excel_download_helper.dart';

class SalesScreen extends ConsumerStatefulWidget {
  final bool createImmediately;
  const SalesScreen({Key? key, this.createImmediately = false}) : super(key: key);

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  bool _showSearch = false;
  int _displayLimit = 50;

  @override
  void initState() {
    super.initState();
    if (widget.createImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditInvoiceScreen(),
          ),
        ).then((_) => ref.invalidate(filteredInvoicesProvider));
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadSalesSampleExcel() async {
    try {
      final sampleBytes = SalesExcelImportService.generateSampleTemplate();
      if (sampleBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate sample template.')),
        );
        return;
      }

      await ExcelDownloadHelper.downloadExcel(
        sampleBytes,
        'Sales_Invoice_Import_Sample_Template.xlsx',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📥 Sample Sales Invoice Excel Template downloaded! Fill details in Sheet 1 & Sheet 2.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating sample Excel: $e')),
      );
    }
  }

  Future<void> _importSalesExcel() async {
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
              title: 'Importing Sales Invoices',
              progressStream: progressController.stream,
            );
          },
        );
      }

      progressController.add(const ImportProgressState(current: 0, total: 100, statusMessage: 'Reading Excel workbook...'));
      await Future.delayed(const Duration(milliseconds: 50));

      final dbService = ref.read(databaseServiceProvider);

      // Single-pass Excel decoding
      final excelDoc = Excel.decodeBytes(fileBytes);
      await Future.delayed(Duration.zero);

      // Check for existing duplicate invoices in database
      final duplicateInvoices = await SalesExcelImportService.checkForDuplicateInvoices(excelDoc, dbService);

      DuplicateBillAction selectedAction = DuplicateBillAction.overwrite;

      if (duplicateInvoices.isNotEmpty && mounted) {
        final choice = await showDialog<DuplicateBillAction>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('Existing Invoice Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The following sales invoice(s) already exist in your database:\n${duplicateInvoices.map((b) => '• $b').join('\n')}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 14),
                const Text(
                  'What would you like to do with these existing invoices?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, DuplicateBillAction.skip),
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: const Text('Skip Existing'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, DuplicateBillAction.overwrite),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Rewrite / Overwrite'),
              ),
            ],
          ),
        );

        if (choice == null) {
          if (progressDialogContext != null && progressDialogContext!.mounted) {
            Navigator.of(progressDialogContext!).pop();
          }
          await progressController.close();
          return;
        }
        selectedAction = choice;
      }

      final importResult = await SalesExcelImportService.importSalesInvoicesFromBytes(
        excelDoc,
        dbService,
        duplicateAction: selectedAction,
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
        Navigator.of(progressDialogContext!).pop(); // Close progress dialog safely
      }

      // Trigger cloud sync
      ref.read(syncServiceProvider).syncAll();

      ref.invalidate(filteredInvoicesProvider);
      ref.invalidate(filteredItemsProvider);
      ref.invalidate(dashboardAnalyticsProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  importResult.totalInvoicesImported > 0 ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: importResult.totalInvoicesImported > 0 ? Colors.green : Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Sales Excel Import', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Sales Invoices Imported: ${importResult.totalInvoicesImported}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('📦 Sales Items Recorded: ${importResult.totalItemsImported}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (importResult.skippedInvoices > 0) ...[
                    const SizedBox(height: 4),
                    Text('⏭️ Invoices Skipped: ${importResult.skippedInvoices}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 15)),
                  ],
                  if (importResult.errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Warnings / Logs:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
    final filter = ref.watch(invoiceSearchFilterProvider);
    final invoicesAsync = ref.watch(filteredInvoicesProvider);
    final partiesAsync = ref.watch(partiesListProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isMobile ? 44 : 52,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search invoice #, customer, GST...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (val) {
                  ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(query: val));
                },
              )
            : Text(
                'Sales Invoice Registry',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          // 🔍 Search Toggle Button
          IconButton(
            tooltip: 'Search Invoices',
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, size: 20),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(query: ''));
                }
              });
            },
          ),

          // ⚡ Filter Toggle Button
          IconButton(
            tooltip: 'Filter Invoices',
            icon: Icon(
              _showFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
              size: 20,
              color: _showFilters ? theme.colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),

          // ⋮ 3-Dot Tools Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            tooltip: 'Sales Tools',
            onSelected: (value) async {
              if (value == 'sample') {
                _downloadSalesSampleExcel();
              } else if (value == 'import') {
                _importSalesExcel();
              } else if (value == 'clean_duplicates') {
                final dbService = ref.read(databaseServiceProvider);
                await SalesExcelImportService.purgeDuplicateInvoices(dbService.isar);
                ref.read(syncServiceProvider).syncPendingChangesQuietly();
                ref.invalidate(filteredInvoicesProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🧹 Duplicate Invoices cleaned up locally & Cloud Delete queued!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else if (value == 'refresh') {
                ref.invalidate(filteredInvoicesProvider);
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
                    Text('Import Excel Invoices'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clean_duplicates',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_rounded, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Clean Duplicate Invoices'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Refresh List'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Filters panel
          if (_showFilters) _buildFilterPanel(theme, filter, partiesAsync),

          // Invoice List
          Expanded(
            child: invoicesAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No invoices found matching filters.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Record Direct Sales Invoice'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddEditInvoiceScreen(),
                              ),
                            ).then((_) => ref.invalidate(filteredInvoicesProvider));
                          },
                        ),
                      ],
                    ),
                  );
                }

                final totalCount = list.length;
                final totalSales = list.fold<double>(0.0, (sum, inv) => sum + (inv.grandTotal ?? 0.0));
                final totalBalanceDue = list.fold<double>(0.0, (sum, inv) => sum + (inv.pendingAmount ?? 0.0));

                final visibleList = list.take(_displayLimit).toList();
                final hasMore = list.length > _displayLimit;

                return Column(
                  children: [
                    _buildSummaryBanner(theme, totalCount, totalSales, totalBalanceDue),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                    'Load More Invoices (Showing ${_displayLimit} of ${list.length})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          }

                          final invoice = visibleList[index];
                          return _buildInvoiceCard(invoice, theme);
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load invoices: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Direct Invoice'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditInvoiceScreen(),
            ),
          ).then((_) => ref.invalidate(filteredInvoicesProvider));
        },
      ),
    );
  }

  Widget _buildFilterPanel(
    ThemeData theme,
    InvoiceSearchFilter filter,
    AsyncValue<List<Party>> partiesAsync,
  ) {
    final isMobile = ResponsiveLayout.isMobile(context);

    final paymentStatusDropdown = DropdownButtonFormField<String>(
      value: filter.paymentStatus,
      decoration: const InputDecoration(
        labelText: 'Payment Status',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Payments')),
        DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid (Credit)')),
        DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
        DropdownMenuItem(value: 'Paid', child: Text('Paid (Cash)')),
        DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
      ],
      onChanged: (v) {
        if (v != null) {
          ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(paymentStatus: v));
        }
      },
    );

    final sortByDropdown = DropdownButtonFormField<String>(
      value: filter.sortBy,
      decoration: const InputDecoration(
        labelText: 'Sort By',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Date', child: Text('Invoice Date')),
        DropdownMenuItem(value: 'Amount High-Low', child: Text('Amount (High-Low)')),
        DropdownMenuItem(value: 'Amount Low-High', child: Text('Amount (Low-High)')),
        DropdownMenuItem(value: 'Due Date', child: Text('Credit Due Date')),
      ],
      onChanged: (v) {
        if (v != null) {
          ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(sortBy: v));
        }
      },
    );

    final partyDropdown = partiesAsync.when(
      data: (parties) {
        return DropdownButtonFormField<int?>(
          value: filter.partyId,
          decoration: const InputDecoration(
            labelText: 'Customer Account',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All Customers')),
            ...parties.map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.partyName ?? ''))),
          ],
          onChanged: (v) {
            ref.read(invoiceSearchFilterProvider.notifier).update((state) => state.copyWith(partyId: v));
          },
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const Icon(Icons.error),
    );

    final resetFiltersButton = TextButton.icon(
      icon: const Icon(Icons.refresh),
      label: const Text('Reset'),
      onPressed: () {
        _searchController.clear();
        ref.read(invoiceSearchFilterProvider.notifier).state = const InvoiceSearchFilter();
      },
    );

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                paymentStatusDropdown,
                const SizedBox(height: 10),
                sortByDropdown,
                const SizedBox(height: 10),
                partyDropdown,
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: resetFiltersButton,
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: paymentStatusDropdown),
                    const SizedBox(width: 8),
                    Expanded(child: sortByDropdown),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: partyDropdown),
                    const SizedBox(width: 8),
                    resetFiltersButton,
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, ThemeData theme) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    switch (invoice.paymentStatus) {
      case 'Unpaid':
        statusColor = Colors.red;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'Partially Paid':
        statusColor = Colors.orange;
        statusIcon = Icons.payments_outlined;
        break;
      case 'Paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    final dateStr = invoice.invoiceDate?.toIso8601String().substring(0, 10) ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
                color: statusColor,
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceDetailScreen(invoiceUuid: invoice.uuid!),
                      ),
                    ).then((_) => ref.invalidate(filteredInvoicesProvider));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.08),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    invoice.invoiceNumber ?? 'N/A',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₹${invoice.grandTotal?.toStringAsFixed(2) ?? "0.00"}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                invoice.partyName ?? 'Unknown Party',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Date: $dateStr | Type: ${invoice.invoiceType ?? "Tax Invoice"}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      invoice.paymentStatus ?? 'Pending',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
                          onSelected: (val) async {
                            final dbService = ref.read(databaseServiceProvider);
                            final isar = dbService.isar;

                            if (val == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditInvoiceScreen(invoiceUuid: invoice.uuid),
                                ),
                              ).then((_) => ref.invalidate(filteredInvoicesProvider));
                            } else if (val == 'cancel') {
                              final newStatus = invoice.paymentStatus == 'Cancelled' ? 'Unpaid' : 'Cancelled';
                              await isar.writeTxn(() async {
                                invoice.paymentStatus = newStatus;
                                invoice.invoiceStatus = newStatus;
                                invoice.updatedAt = DateTime.now();
                                await isar.invoices.put(invoice);
                              });
                              ref.invalidate(filteredInvoicesProvider);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Invoice ${invoice.invoiceNumber} status set to $newStatus.'),
                                    backgroundColor: newStatus == 'Cancelled' ? Colors.orange : Colors.green,
                                  ),
                                );
                              }
                            } else if (val == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Invoice?'),
                                  content: Text('Are you sure you want to delete Invoice ${invoice.invoiceNumber}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await isar.writeTxn(() async {
                                  invoice.isDeleted = true;
                                  invoice.updatedAt = DateTime.now();
                                  await isar.invoices.put(invoice);
                                });
                                ref.invalidate(filteredInvoicesProvider);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invoice deleted successfully.')),
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit Invoice')]),
                            ),
                            PopupMenuItem(
                              value: 'cancel',
                              child: Row(children: [
                                Icon(invoice.paymentStatus == 'Cancelled' ? Icons.check_circle_outline : Icons.block_outlined, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(invoice.paymentStatus == 'Cancelled' ? 'Reactivate Invoice' : 'Cancel Invoice', style: const TextStyle(color: Colors.orange)),
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete Invoice', style: TextStyle(color: Colors.red))]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(ThemeData theme, int totalCount, double totalSales, double totalBalanceDue) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCardItem(
            theme: theme,
            title: 'No. of Txns',
            value: '$totalCount',
            icon: Icons.receipt_long_rounded,
            color: Colors.blue,
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          _buildSummaryCardItem(
            theme: theme,
            title: 'Total Sale',
            value: currencyFormat.format(totalSales),
            icon: Icons.point_of_sale_rounded,
            color: const Color(0xFF10B981),
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          _buildSummaryCardItem(
            theme: theme,
            title: 'Balance Due',
            value: currencyFormat.format(totalBalanceDue),
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardItem({
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
