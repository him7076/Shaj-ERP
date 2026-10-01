import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:business_sahaj_erp/features/sales/presentation/screens/invoice_detail_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/add_edit_purchase_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_credit_note_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_debit_note_screen.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/screens/add_edit_transaction_dialog.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/features/bank/presentation/screens/adjust_cash_dialog.dart';
import 'package:business_sahaj_erp/features/bank/presentation/screens/transfer_funds_dialog.dart';
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

  Map<String, double> _parseAllocations(String? linkedStr, double txAmount) {
    if (linkedStr == null || linkedStr.isEmpty) return {};
    try {
      if (linkedStr.startsWith('{')) {
        final Map<String, dynamic> decoded = jsonDecode(linkedStr);
        return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } else {
        return {linkedStr: txAmount};
      }
    } catch (e) {
      return {linkedStr: txAmount};
    }
  }

  Future<List<_DayBookVoucher>> _loadDayVouchers() async {
    final isar = ref.read(databaseServiceProvider).isar;
    final List<_DayBookVoucher> vouchers = [];
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    // Fetch all transactions to calculate linked amounts
    final allTxns = await isar.transactions.filter().isDeletedEqualTo(false).findAll();
    Map<String, double> linkedAmountMap = {};
    for (var tx in allTxns) {
      final allocs = _parseAllocations(tx.linkedBillUuid, tx.amount ?? 0.0);
      allocs.forEach((uuid, amt) {
        linkedAmountMap[uuid] = (linkedAmountMap[uuid] ?? 0.0) + amt;
      });
    }

    // 1. Sales Invoices
    final invoices = await isar.invoices.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q.invoiceDateBetween(startOfDay, endOfDay).or().invoiceDateIsNull())
        .findAll();
    for (var inv in invoices) {
      if (_isSameDay(inv.invoiceDate, _selectedDate)) {
        final totalPaid = inv.paidAmount ?? 0.0;
        final linked = (linkedAmountMap[inv.uuid ?? ''] ?? 0.0) + (linkedAmountMap[inv.invoiceNumber ?? ''] ?? 0.0);
        final initialPaid = (totalPaid - linked) > 0 ? (totalPaid - linked) : 0.0;
        
        vouchers.add(_DayBookVoucher(
          date: inv.invoiceDate ?? DateTime.now(),
          voucherType: 'Sale Invoice',
          voucherNo: inv.invoiceNumber ?? 'N/A',
          partyName: inv.partyName ?? 'Customer',
          paymentMode: inv.paymentMode ?? 'Cash',
          debit: initialPaid,
          credit: 0.0,
          totalAmount: inv.grandTotal ?? 0.0,
          remarks: inv.remarks ?? '',
          entityUuid: inv.uuid,
          route: '/sales/invoice',
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
        final totalPaid = pur.paidAmount ?? 0.0;
        final linked = (linkedAmountMap[pur.uuid ?? ''] ?? 0.0) + (linkedAmountMap[pur.purchaseNumber ?? ''] ?? 0.0);
        final initialPaid = (totalPaid - linked) > 0 ? (totalPaid - linked) : 0.0;

        vouchers.add(_DayBookVoucher(
          date: pur.purchaseDate ?? DateTime.now(),
          voucherType: 'Purchase Bill',
          voucherNo: pur.purchaseNumber ?? 'N/A',
          partyName: pur.partyName ?? 'Supplier',
          paymentMode: pur.paymentMode ?? 'Cash',
          debit: 0.0,
          credit: initialPaid,
          totalAmount: pur.grandTotal ?? 0.0,
          remarks: pur.remarks ?? '',
          entityUuid: pur.uuid,
          route: '/purchases/bill',
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
        final isCredit = type == 'Payment' || type == 'Expense';
        
        // Transfer does not add to total Cash inflow/outflow directly unless it involves Cash, 
        // but let's keep it 0 for Daybook net balance to avoid double counting bank-to-bank.
        final actualDebit = (isDebit && !['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(type)) ? amt : 0.0;
        final actualCredit = (isCredit && !['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(type)) ? amt : 0.0;

        vouchers.add(_DayBookVoucher(
          date: t.transactionDate ?? DateTime.now(),
          voucherType: type,
          voucherNo: t.transactionNumber ?? 'N/A',
          partyName: t.partyName ?? 'Account',
          paymentMode: t.paymentMode ?? 'Cash',
          debit: actualDebit,
          credit: actualCredit,
          totalAmount: amt,
          remarks: t.remarks ?? '',
          entityUuid: t.uuid,
          route: '/transactions', // We don't have a direct detailed screen for transaction, so we just pass null route if we want to avoid error
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
          totalAmount: exp.amount ?? 0.0,
          remarks: exp.remarks ?? '',
          entityUuid: null,
          route: null,
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
          credit: 0.0, // Credit notes adjust balance, no direct cash flow
          totalAmount: cn.grandTotal ?? 0.0,
          remarks: cn.remarks ?? '',
          entityUuid: cn.uuid,
          route: '/sales/credit-note',
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
          debit: 0.0, // Debit notes adjust balance, no direct cash flow
          credit: 0.0,
          totalAmount: dn.grandTotal ?? 0.0,
          remarks: dn.remarks ?? '',
          entityUuid: dn.uuid,
          route: '/purchases/debit-note',
        ));
      }
    }

    // Sort chronologically
    vouchers.sort((a, b) => a.date.compareTo(b.date));
    return vouchers;
  }

  void _exportPDF(List<_DayBookVoucher> vouchers) async {
    final exportService = ref.read(exportServiceProvider);
    final headers = ['Date', 'Type', 'Voucher #', 'Party', 'Total', 'Money In', 'Money Out'];
    final rows = vouchers.map((v) {
      return [
        DateFormat('dd-MM-yyyy').format(v.date),
        v.voucherType,
        v.voucherNo,
        v.partyName,
        currencyFormat.format(v.totalAmount),
        v.debit > 0 ? currencyFormat.format(v.debit) : '-',
        v.credit > 0 ? currencyFormat.format(v.credit) : '-',
      ];
    }).toList();

    double totalDebit = vouchers.fold(0.0, (s, v) => s + v.debit);
    double totalCredit = vouchers.fold(0.0, (s, v) => s + v.credit);

    final totals = [
      'Total Money In: ${currencyFormat.format(totalDebit)}',
      'Total Money Out: ${currencyFormat.format(totalCredit)}',
      'Net Balance: ${currencyFormat.format(totalDebit - totalCredit)}',
    ];

    await exportService.exportToPDF(
      title: 'Day Book Journal Report',
      subtitle: 'Date: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
      headers: headers,
      rows: rows,
      totals: totals,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false, leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null, 
        title: const Text('Day Book', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
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
              // Date & Summary Card
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${vouchers.length} Transactions',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: vouchers.isEmpty ? null : () => _exportPDF(vouchers),
                          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                          tooltip: 'Export PDF',
                          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Money In (+)', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(currencyFormat.format(totalDebit), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Money Out (-)', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(currencyFormat.format(totalCredit), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transaction List
              Expanded(
                child: vouchers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text('No transactions for this date.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: vouchers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final v = vouchers[index];
                          final isMoneyIn = v.debit > 0;
                          final isMoneyOut = v.credit > 0;
                          
                          // Avatar Icon & Color
                          IconData iconData = Icons.receipt_rounded;
                          Color iconColor = theme.colorScheme.primary;
                          if (v.voucherType.contains('Sale') || v.voucherType == 'Receipt') {
                            iconData = Icons.arrow_downward_rounded;
                            iconColor = Colors.green;
                          } else if (v.voucherType.contains('Purchase') || v.voucherType == 'Payment' || v.voucherType == 'Expense') {
                            iconData = Icons.arrow_upward_rounded;
                            iconColor = Colors.red;
                          }

                          return InkWell(
                            onTap: v.entityUuid != null ? () async {
                              if (v.voucherType.contains('Sale Invoice')) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceUuid: v.entityUuid!)));
                              } else if (v.voucherType.contains('Purchase Bill')) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPurchaseScreen(purchaseUuid: v.entityUuid!)));
                              } else if (v.voucherType.contains('Credit Note')) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditCreditNoteScreen(parentCreditNoteUuid: v.entityUuid!)));
                              } else if (v.voucherType.contains('Debit Note')) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditDebitNoteScreen(parentDebitNoteUuid: v.entityUuid!)));
                              } else if (v.voucherType == 'Receipt' || v.voucherType == 'Payment' || v.voucherType == 'Other Income' || ['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(v.voucherType)) {
                                final isar = ref.read(databaseServiceProvider).isar;
                                final txn = await isar.transactions.filter().uuidEqualTo(v.entityUuid).findFirst();
                                if (txn != null && mounted) {
                                   if (txn.transactionType == 'Bank Transfer' || txn.transactionType == 'Cash Adjustment') {
                                      showDialog(context: context, builder: (_) => TransferFundsDialog(existingTransaction: txn));
                                   } else {
                                      showDialog(context: context, builder: (_) => AddEditTransactionDialog(transaction: txn, initialType: txn.transactionType ?? v.voucherType));
                                   }
                                }
                              }
                            } : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: iconColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(iconData, color: iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                v.partyName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              currencyFormat.format(v.totalAmount),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${v.voucherType} #${v.voucherNo}',
                                                style: TextStyle(fontSize: 9, color: theme.colorScheme.onSecondaryContainer),
                                              ),
                                            ),
                                            const Spacer(),
                                            if (isMoneyIn)
                                              Text(
                                                '+ ${currencyFormat.format(v.debit)} In',
                                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            if (isMoneyOut)
                                              Text(
                                                '- ${currencyFormat.format(v.credit)} Out',
                                                style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
  final double totalAmount;
  final String remarks;
  final String? entityUuid;
  final String? route;

  _DayBookVoucher({
    required this.date,
    required this.voucherType,
    required this.voucherNo,
    required this.partyName,
    required this.paymentMode,
    required this.debit,
    required this.credit,
    required this.totalAmount,
    required this.remarks,
    this.entityUuid,
    this.route,
  });
}
