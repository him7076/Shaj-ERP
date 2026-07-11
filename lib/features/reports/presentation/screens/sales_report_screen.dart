import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  ReportDatePreset _datePreset = ReportDatePreset.thisMonth;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  String? _selectedPartyUuid;
  String _selectedStatus = 'All'; // All, Paid, Unpaid, Partially Paid

  List<Party> _partiesList = [];
  bool _loadingParties = false;

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    setState(() => _loadingParties = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final parties = await db.isar.partys.filter().isDeletedEqualTo(false).findAll();
      setState(() {
        _partiesList = parties;
      });
    } catch (_) {}
    setState(() => _loadingParties = false);
  }

  void _setDatePreset(ReportDatePreset preset) {
    final filter = ReportDateFilter.fromPreset(preset);
    setState(() {
      _datePreset = preset;
      _startDate = filter.startDate;
      _endDate = filter.endDate;
    });
  }

  void _exportPDF(SalesReportSummary summary) async {
    final exportService = ref.read(exportServiceProvider);
    
    final headers = ['Invoice No', 'Date', 'Party Name', 'Taxable Amt', 'GST Amt', 'Grand Total', 'Status'];
    final rows = summary.invoices.map((inv) {
      final date = inv.invoiceDate != null ? DateFormat('yyyy-MM-dd').format(inv.invoiceDate!) : 'N/A';
      return [
        inv.invoiceNumber ?? 'N/A',
        date,
        inv.partyName ?? 'Walk-In',
        currencyFormat.format(inv.taxableAmount ?? 0.0),
        currencyFormat.format(inv.totalGST ?? 0.0),
        currencyFormat.format(inv.grandTotal ?? 0.0),
        inv.paymentStatus ?? 'N/A',
      ];
    }).toList();

    final totals = [
      'Total Sales: ${currencyFormat.format(summary.totalSales)}',
      'Total GST: ${currencyFormat.format(summary.totalGST)}',
      'Net: ${currencyFormat.format(summary.netSales)}',
    ];

    await exportService.exportToPDF(
      title: 'Sales Register Report',
      subtitle: 'Date Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
      headers: headers,
      rows: rows,
      totals: totals,
    );
  }

  void _exportExcel(SalesReportSummary summary) async {
    final exportService = ref.read(exportServiceProvider);
    final theme = Theme.of(context);

    final headers = ['Invoice Number', 'Invoice Date', 'Party Name', 'Taxable Amount', 'GST Amount', 'Discount', 'Grand Total', 'Payment Status'];
    final rows = summary.invoices.map((inv) {
      final date = inv.invoiceDate != null ? DateFormat('yyyy-MM-dd').format(inv.invoiceDate!) : 'N/A';
      return [
        inv.invoiceNumber ?? 'N/A',
        date,
        inv.partyName ?? 'Walk-In',
        inv.taxableAmount ?? 0.0,
        inv.totalGST ?? 0.0,
        inv.discountAmount ?? 0.0,
        inv.grandTotal ?? 0.0,
        inv.paymentStatus ?? 'N/A',
      ];
    }).toList();

    try {
      final path = await exportService.exportToExcel(
        title: 'Sales Register Report',
        headers: headers,
        rows: rows,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.primaryContainer,
            content: Text(
              'Excel Exported Successfully! File saved in Documents.',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Riverpod query arguments
    final args = (
      start: _startDate,
      end: _endDate,
      partyUuid: _selectedPartyUuid,
      paymentStatus: _selectedStatus,
      offset: 0,
      limit: 200,
    );

    final reportAsync = ref.watch(salesReportProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Register Report'),
        actions: [
          reportAsync.when(
            data: (summary) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  tooltip: 'Share PDF Report',
                  onPressed: () => _exportPDF(summary),
                ),
                IconButton(
                  icon: const Icon(Icons.grid_on_rounded),
                  tooltip: 'Export Excel Spreadsheet',
                  onPressed: () => _exportExcel(summary),
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Panel Card
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Date Preset
                      Expanded(
                        child: DropdownButtonFormField<ReportDatePreset>(
                          value: _datePreset,
                          decoration: const InputDecoration(
                            labelText: 'Date Preset',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: ReportDatePreset.values.map((preset) {
                            final filter = ReportDateFilter.fromPreset(preset);
                            return DropdownMenuItem(
                              value: preset,
                              child: Text(filter.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) _setDatePreset(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Payment Status
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Payment Status',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Payments')),
                            DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                            DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                            DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatus = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Party Selector Dropdown
                      Expanded(
                        child: _loadingParties
                            ? const Center(child: LinearProgressIndicator())
                            : DropdownButtonFormField<String?>(
                                value: _selectedPartyUuid,
                                decoration: const InputDecoration(
                                  labelText: 'Select Party',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All Parties / Customers'),
                                  ),
                                  ..._partiesList.map((p) {
                                    return DropdownMenuItem<String?>(
                                      value: p.uuid,
                                      child: Text(p.partyName ?? 'Walk-In'),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedPartyUuid = val);
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Invoices Table List
          Expanded(
            child: reportAsync.when(
              data: (summary) {
                if (summary.invoices.isEmpty) {
                  return const Center(child: Text('No invoice logs found matching filters.'));
                }

                return Column(
                  children: [
                    // Summary KPIs Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryText('Total Sales', currencyFormat.format(summary.totalSales), theme),
                          _buildSummaryText('Total Tax', currencyFormat.format(summary.totalGST), theme),
                          _buildSummaryText('Net Sales', currencyFormat.format(summary.netSales), theme),
                        ],
                      ),
                    ),

                    // Table
                    Expanded(
                      child: ListView.builder(
                        itemCount: summary.invoices.length,
                        itemBuilder: (context, index) {
                          final inv = summary.invoices[index];
                          final dateStr = inv.invoiceDate != null
                              ? DateFormat('yyyy-MM-dd').format(inv.invoiceDate!)
                              : 'N/A';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                            ),
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    inv.invoiceNumber ?? 'INV-N/A',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    currencyFormat.format(inv.grandTotal ?? 0.0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Customer: ${inv.partyName ?? "Walk-In"}'),
                                        Text('Date: $dateStr • Tax: ${currencyFormat.format(inv.totalGST ?? 0.0)}'),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(inv.paymentStatus).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _getStatusColor(inv.paymentStatus).withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        inv.paymentStatus ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(inv.paymentStatus),
                                        ),
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
              error: (err, _) => Center(child: Text('Error loading sales report: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Paid': return Colors.green[700]!;
      case 'Unpaid': return Colors.red[700]!;
      case 'Partially Paid': return Colors.orange[700]!;
      default: return Colors.grey;
    }
  }

  Widget _buildSummaryText(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
