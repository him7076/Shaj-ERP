import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:isar/isar.dart';

class DayBookReportScreen extends ConsumerStatefulWidget {
  const DayBookReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DayBookReportScreen> createState() => _DayBookReportScreenState();
}

class _DayBookReportScreenState extends ConsumerState<DayBookReportScreen> {
  DateTime _selectedDate = DateTime.now();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<List<_DayBookVoucher>> _loadDayVouchers() async {
    final isar = ref.read(databaseServiceProvider).isar;
    final List<_DayBookVoucher> vouchers = [];
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    // 1. Sales Invoices
    final invoices = await isar.invoices.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q.invoiceDateBetween(startOfDay, endOfDay).or().invoiceDateIsNull())
        .findAll();
    for (var inv in invoices) {
      if (_isSameDay(inv.invoiceDate, _selectedDate)) {
        final paid = inv.paidAmount ?? inv.grandTotal ?? 0.0;
        vouchers.add(_DayBookVoucher(
          date: inv.invoiceDate ?? DateTime.now(),
          voucherType: 'Sale Invoice',
          voucherNo: inv.invoiceNumber ?? 'N/A',
          partyName: inv.partyName ?? 'Customer',
          paymentMode: inv.paymentStatus ?? 'Cash',
          debit: paid,
          credit: 0.0,
          remarks: inv.remarks ?? '',
        ));
      }
    }

    // 2. Purchase Invoices
    final purchases = await isar.purchases.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q.purchaseDateBetween(startOfDay, endOfDay).or().purchaseDateIsNull())
        .findAll();
    for (var pur in purchases) {
      if (_isSameDay(pur.purchaseDate, _selectedDate)) {
        final paid = pur.paidAmount ?? pur.grandTotal ?? 0.0;
        vouchers.add(_DayBookVoucher(
          date: pur.purchaseDate ?? DateTime.now(),
          voucherType: 'Purchase Bill',
          voucherNo: pur.purchaseNumber ?? 'N/A',
          partyName: pur.partyName ?? 'Supplier',
          paymentMode: pur.paymentStatus ?? 'Cash',
          debit: 0.0,
          credit: paid,
          remarks: pur.remarks ?? '',
        ));
      }
    }

    // 3. Transactions (Receipts, Payments, Transfers, Other Income)
    final txns = await isar.transactions.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q.transactionDateBetween(startOfDay, endOfDay).or().transactionDateIsNull())
        .findAll();
    for (var t in txns) {
      if (_isSameDay(t.transactionDate, _selectedDate)) {
        final amt = t.amount ?? 0.0;
        final type = t.transactionType ?? 'Receipt';
        final isDebit = type == 'Receipt' || type == 'Other Income';
        final isCredit = type == 'Payment';

        vouchers.add(_DayBookVoucher(
          date: t.transactionDate ?? DateTime.now(),
          voucherType: type,
          voucherNo: t.transactionNumber ?? 'N/A',
          partyName: t.partyName ?? 'Account',
          paymentMode: t.paymentMode ?? 'Cash',
          debit: isDebit ? amt : 0.0,
          credit: isCredit ? amt : 0.0,
          remarks: t.remarks ?? '',
        ));
      }
    }

    // 4. Expenses
    final expenses = await isar.expenses.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q.expenseDateBetween(startOfDay, endOfDay).or().expenseDateIsNull())
        .findAll();
    for (var exp in expenses) {
      if (_isSameDay(exp.expenseDate, _selectedDate)) {
        vouchers.add(_DayBookVoucher(
          date: exp.expenseDate ?? DateTime.now(),
          voucherType: 'Expense',
          voucherNo: exp.voucherNo ?? 'N/A',
          partyName: exp.category ?? 'General Expense',
          paymentMode: exp.paymentMode ?? 'Cash',
          debit: 0.0,
          credit: exp.amount ?? 0.0,
          remarks: exp.remarks ?? '',
        ));
      }
    }

    // 5. Credit Notes
    final creditNotes = await isar.creditNotes.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q.creditNoteDateBetween(startOfDay, endOfDay).or().creditNoteDateIsNull())
        .findAll();
    for (var cn in creditNotes) {
      if (_isSameDay(cn.creditNoteDate, _selectedDate)) {
        vouchers.add(_DayBookVoucher(
          date: cn.creditNoteDate ?? DateTime.now(),
          voucherType: 'Credit Note',
          voucherNo: cn.creditNoteNumber ?? 'N/A',
          partyName: cn.partyName ?? 'Customer',
          paymentMode: 'Adjustment',
          debit: 0.0,
          credit: cn.grandTotal ?? 0.0,
          remarks: cn.remarks ?? '',
        ));
      }
    }

    // 6. Debit Notes
    final debitNotes = await isar.debitNotes.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q.debitNoteDateBetween(startOfDay, endOfDay).or().debitNoteDateIsNull())
        .findAll();
    for (var dn in debitNotes) {
      if (_isSameDay(dn.debitNoteDate, _selectedDate)) {
        vouchers.add(_DayBookVoucher(
          date: dn.debitNoteDate ?? DateTime.now(),
          voucherType: 'Debit Note',
          voucherNo: dn.debitNoteNumber ?? 'N/A',
          partyName: dn.partyName ?? 'Supplier',
          paymentMode: 'Adjustment',
          debit: dn.grandTotal ?? 0.0,
          credit: 0.0,
          remarks: dn.remarks ?? '',
        ));
      }
    }

    // Sort chronologically
    vouchers.sort((a, b) => a.date.compareTo(b.date));
    return vouchers;
  }

  void _exportPDF(List<_DayBookVoucher> vouchers) async {
    final exportService = ref.read(exportServiceProvider);
    final headers = ['Date', 'Type', 'Voucher #', 'Party / Account', 'Mode', 'Debit (₹)', 'Credit (₹)'];
    final rows = vouchers.map((v) {
      return [
        DateFormat('dd-MM-yyyy').format(v.date),
        v.voucherType,
        v.voucherNo,
        v.partyName,
        v.paymentMode,
        v.debit > 0 ? currencyFormat.format(v.debit) : '-',
        v.credit > 0 ? currencyFormat.format(v.credit) : '-',
      ];
    }).toList();

    double totalDebit = vouchers.fold(0.0, (s, v) => s + v.debit);
    double totalCredit = vouchers.fold(0.0, (s, v) => s + v.credit);

    final totals = [
      'Total Debit: ${currencyFormat.format(totalDebit)}',
      'Total Credit: ${currencyFormat.format(totalCredit)}',
      'Net Balance: ${currencyFormat.format(totalDebit - totalCredit)}',
    ];

    await exportService.exportToPDF(
      title: 'Day Book Journal Report',
      subtitle: 'Selected Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
      headers: headers,
      rows: rows,
      totals: totals,
    );
  }

  void _exportExcel(List<_DayBookVoucher> vouchers) async {
    final exportService = ref.read(exportServiceProvider);
    final headers = ['Date', 'Voucher Type', 'Voucher Number', 'Party Name', 'Payment Mode', 'Debit Amount', 'Credit Amount', 'Remarks'];
    final rows = vouchers.map((v) {
      return [
        DateFormat('yyyy-MM-dd').format(v.date),
        v.voucherType,
        v.voucherNo,
        v.partyName,
        v.paymentMode,
        v.debit,
        v.credit,
        v.remarks,
      ];
    }).toList();

    await exportService.exportToExcel(
      title: 'Day_Book_${DateFormat('yyyy_MM_dd').format(_selectedDate)}',
      headers: headers,
      rows: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Book Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Change Date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: FutureBuilder<List<_DayBookVoucher>>(
        future: _loadDayVouchers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading Day Book: ${snapshot.error}'));
          }

          final vouchers = snapshot.data ?? [];
          double totalDebit = vouchers.fold(0.0, (sum, v) => sum + v.debit);
          double totalCredit = vouchers.fold(0.0, (sum, v) => sum + v.credit);
          double netBalance = totalDebit - totalCredit;

          return Column(
            children: [
              // Header Date & Export Toolbar Card
              Card(
                margin: const EdgeInsets.all(16.0),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.event_note_rounded, color: theme.colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${vouchers.length} Journal Entries Logged Today',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        tooltip: 'Export PDF Report',
                        onPressed: vouchers.isEmpty ? null : () => _exportPDF(vouchers),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.table_chart_rounded),
                        tooltip: 'Export Excel Report',
                        onPressed: vouchers.isEmpty ? null : () => _exportExcel(vouchers),
                      ),
                    ],
                  ),
                ),
              ),

              // KPI Inflow/Outflow Overview Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Debit (Inflow)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(totalDebit), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Credit (Outflow)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(totalCredit), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net Cash Balance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(netBalance),
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: netBalance >= 0 ? Colors.indigo : Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Journal Voucher List
              Expanded(
                child: vouchers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.event_busy_rounded, size: 54, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No day book vouchers logged on this date.', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vouchers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final v = vouchers[index];
                          final isDebit = v.debit > 0;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (isDebit ? Colors.green : Colors.red).withOpacity(0.15),
                                child: Icon(
                                  isDebit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isDebit ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    v.partyName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    currencyFormat.format(isDebit ? v.debit : v.credit),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDebit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${v.voucherType} #${v.voucherNo} | Mode: ${v.paymentMode}',
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                    Text(
                                      isDebit ? 'DEBIT (IN)' : 'CREDIT (OUT)',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isDebit ? Colors.green : Colors.red,
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
      ),
    );
  }
}

class _DayBookVoucher {
  final DateTime date;
  final String voucherType;
  final String voucherNo;
  final String partyName;
  final String paymentMode;
  final double debit;
  final double credit;
  final String remarks;

  _DayBookVoucher({
    required this.date,
    required this.voucherType,
    required this.voucherNo,
    required this.partyName,
    required this.paymentMode,
    required this.debit,
    required this.credit,
    required this.remarks,
  });
}
