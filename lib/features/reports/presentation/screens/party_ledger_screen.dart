import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';

class PartyLedgerScreen extends ConsumerStatefulWidget {
  const PartyLedgerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends ConsumerState<PartyLedgerScreen> {
  String? _selectedPartyUuid;
  List<Party> _partiesList = [];
  bool _loadingParties = false;

  ReportDatePreset _datePreset = ReportDatePreset.thisMonth;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

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
        if (parties.isNotEmpty) {
          _selectedPartyUuid = parties.first.uuid;
        }
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

  void _exportPDF(PartyLedgerSummary summary) async {
    final exportService = ref.read(exportServiceProvider);

    final partyName = _partiesList.firstWhere((p) => p.uuid == _selectedPartyUuid).partyName ?? 'Customer';

    final headers = ['Date', 'Voucher Number', 'Voucher Type', 'Debit (+)', 'Credit (-)', 'Running Bal'];
    final rows = summary.entries.map((entry) {
      final date = DateFormat('yyyy-MM-dd').format(entry.date);
      return <String>[
        date,
        entry.voucherNo,
        entry.voucherType,
        entry.debit > 0 ? currencyFormat.format(entry.debit) : '-',
        entry.credit > 0 ? currencyFormat.format(entry.credit) : '-',
        currencyFormat.format(entry.balance),
      ];
    }).toList();

    final totals = [
      'Opening Bal: ${currencyFormat.format(summary.openingBalance)}',
      'Closing Bal: ${currencyFormat.format(summary.closingBalance)}',
    ];

    await exportService.exportToPDF(
      title: '$partyName - Statement of Account',
      subtitle: 'Date Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
      headers: headers,
      rows: rows,
      totals: totals,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch ledger provider
    final ledgerArgs = (
      partyUuid: _selectedPartyUuid ?? '',
      start: _startDate,
      end: _endDate,
    );
    
    final ledgerAsync = _selectedPartyUuid != null
        ? ref.watch(partyLedgerProvider(ledgerArgs))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger Account'),
        actions: [
          if (ledgerAsync != null)
            ledgerAsync.when(
              data: (summary) => IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                tooltip: 'Export Ledger PDF',
                onPressed: () => _exportPDF(summary),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Select Customer and Date preset
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
                  _loadingParties
                      ? const Center(child: LinearProgressIndicator())
                      : DropdownButtonFormField<String?>(
                          value: _selectedPartyUuid,
                          decoration: const InputDecoration(
                            labelText: 'Select Customer Account',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: _partiesList.map((p) {
                            return DropdownMenuItem<String?>(
                              value: p.uuid,
                              child: Text(p.partyName ?? 'Unnamed Party'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPartyUuid = val);
                            }
                          },
                        ),
                  const SizedBox(height: 12),
                  Row(
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
                ],
              ),
            ),
          ),

          // Ledger Table
          Expanded(
            child: _selectedPartyUuid == null
                ? const Center(child: Text('Please select a customer account first.'))
                : ledgerAsync == null
                    ? const Center(child: CircularProgressIndicator())
                    : ledgerAsync.when(
                        data: (summary) {
                          return Column(
                            children: [
                              // Balances Banner
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Opening Balance', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                        Text(
                                          currencyFormat.format(summary.openingBalance),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Closing Balance', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                        Text(
                                          currencyFormat.format(summary.closingBalance),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Table
                              Expanded(
                                child: summary.entries.isEmpty
                                    ? const Center(child: Text('No ledger entries recorded in this period.'))
                                    : ListView.builder(
                                        itemCount: summary.entries.length,
                                        itemBuilder: (context, index) {
                                          final entry = summary.entries[index];
                                          final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);

                                          final isDebit = entry.debit > 0;
                                          final valueText = isDebit
                                              ? '+${currencyFormat.format(entry.debit)}'
                                              : '-${currencyFormat.format(entry.credit)}';
                                          final color = isDebit ? Colors.red[700] : Colors.green[700];

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
                                                    entry.voucherType,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                  Text(
                                                    valueText,
                                                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text('Date: $dateStr • Ref: ${entry.voucherNo}', style: const TextStyle(fontSize: 11)),
                                                    Text(
                                                      'Balance: ${currencyFormat.format(entry.balance)}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                        error: (err, _) => Center(child: Text('Error loading ledger: $err')),
                      ),
          ),
        ],
      ),
    );
  }
}
