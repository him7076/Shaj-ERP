import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';

class GstReportScreen extends ConsumerStatefulWidget {
  const GstReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GstReportScreen> createState() => _GstReportScreenState();
}

class _GstReportScreenState extends ConsumerState<GstReportScreen> {
  ReportDatePreset _datePreset = ReportDatePreset.thisMonth;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  void _setDatePreset(ReportDatePreset preset) {
    final filter = ReportDateFilter.fromPreset(preset);
    setState(() {
      _datePreset = preset;
      _startDate = filter.startDate;
      _endDate = filter.endDate;
    });
  }

  void _exportPDF(GSTReportSummary summary) async {
    final exportService = ref.read(exportServiceProvider);

    final headers = ['HSN Code', 'Qty Sold', 'Taxable Amt', 'GST Rate', 'GST Amt'];
    final rows = summary.hsnSummaries.map((hsn) {
      return [
        hsn.hsnCode,
        hsn.quantity.toStringAsFixed(0),
        currencyFormat.format(hsn.taxableAmount),
        '${hsn.gstRate.toStringAsFixed(0)}%',
        currencyFormat.format(hsn.gstAmount),
      ];
    }).toList();

    final totals = [
      'Total Taxable: ${currencyFormat.format(summary.taxableAmount)}',
      'Total CGST: ${currencyFormat.format(summary.cgstAmount)}',
      'Total SGST: ${currencyFormat.format(summary.sgstAmount)}',
      'Total IGST: ${currencyFormat.format(summary.igstAmount)}',
      'Total GST: ${currencyFormat.format(summary.totalGST)}',
    ];

    await exportService.exportToPDF(
      title: 'GST Filings HSN Summary',
      subtitle: 'Date Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
      headers: headers,
      rows: rows,
      totals: totals,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = (start: _startDate, end: _endDate);
    final reportAsync = ref.watch(gstReportProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Filings & HSN Summary'),
        actions: [
          reportAsync.when(
            data: (summary) => IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              tooltip: 'Export GST Summary PDF',
              onPressed: () => _exportPDF(summary),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Date preset
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ReportDatePreset>(
                      value: _datePreset,
                      decoration: const InputDecoration(
                        labelText: 'Filing Period Preset',
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
                ],
              ),
            ),
          ),

          // Aggregates grid and HSN list
          Expanded(
            child: reportAsync.when(
              data: (summary) {
                return Column(
                  children: [
                    // GST Tax splits grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.8,
                        children: [
                          _buildTaxCard('CGST (Central)', summary.cgstAmount, Colors.indigo, theme),
                          _buildTaxCard('SGST (State)', summary.sgstAmount, Colors.teal, theme),
                          _buildTaxCard('IGST (Integrated)', summary.igstAmount, Colors.orange, theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Totals bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Taxable: ${currencyFormat.format(summary.taxableAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'Total Tax: ${currencyFormat.format(summary.totalGST)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // HSN List Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HSN Summary Breakdown',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${summary.hsnSummaries.length} Codes',
                            style: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16),

                    // HSN List
                    Expanded(
                      child: summary.hsnSummaries.isEmpty
                          ? const Center(child: Text('No itemized tax details logged in this period.'))
                          : ListView.builder(
                              itemCount: summary.hsnSummaries.length,
                              itemBuilder: (context, index) {
                                final hsn = summary.hsnSummaries[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.secondaryContainer,
                                      child: Text(
                                        '${hsn.gstRate.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'HSN: ${hsn.hsnCode}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          currencyFormat.format(hsn.gstAmount),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Qty: ${hsn.quantity.toStringAsFixed(0)} units'),
                                          Text('Taxable: ${currencyFormat.format(hsn.taxableAmount)}'),
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
              error: (err, _) => Center(child: Text('Error loading GST report: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxCard(String label, double amount, Color color, ThemeData theme) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
