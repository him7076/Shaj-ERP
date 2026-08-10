import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/export_service.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';

class ProfitLossReportScreen extends ConsumerStatefulWidget {
  const ProfitLossReportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfitLossReportScreen> createState() => _ProfitLossReportScreenState();
}

class _ProfitLossReportScreenState extends ConsumerState<ProfitLossReportScreen> {
  String _selectedRange = 'This Month';
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  bool _isLoading = true;
  bool _showDetailedBreakdown = true;
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  // Financial Metrics
  double _saleAmount = 0.0;
  double _saleFaAmount = 0.0;
  double _creditNoteAmount = 0.0;
  double _purchaseAmount = 0.0;
  double _purchaseFaAmount = 0.0;
  double _debitNoteAmount = 0.0;
  double _paymentOutDiscount = 0.0;

  double _openingStock = 0.0;
  double _closingStock = 0.0;
  double _openingFaStock = 0.0;
  double _closingFaStock = 0.0;

  double _otherDirectExpense = 0.0;
  double _paymentInDiscount = 0.0;

  double _gstPayable = 0.0;
  double _tcsPayable = 0.0;
  double _tdsPayable = 0.0;

  double _gstReceivable = 0.0;
  double _tcsReceivable = 0.0;
  double _tdsReceivable = 0.0;

  double _otherIncome = 0.0;

  double _otherExpense = 0.0;
  double _loanInterestExpense = 0.0;
  double _loanProcessingFee = 0.0;
  double _loanChargesExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateReportData();
  }

  void _onRangeChanged(String? range) {
    if (range == null) return;
    final now = DateTime.now();
    setState(() {
      _selectedRange = range;
      if (range == 'Today') {
        _fromDate = DateTime(now.year, now.month, now.day);
        _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (range == 'This Month') {
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (range == 'This Quarter') {
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        _fromDate = DateTime(now.year, quarterMonth, 1);
        _toDate = DateTime(now.year, quarterMonth + 3, 0, 23, 59, 59);
      } else if (range == 'This Year') {
        _fromDate = DateTime(now.year, 1, 1);
        _toDate = DateTime(now.year, 12, 31, 23, 59, 59);
      }
    });
    _calculateReportData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = 'Custom Range';
        _fromDate = picked.start;
        _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _calculateReportData();
    }
  }

  bool _isInDateRange(DateTime? date) {
    if (date == null) return true; // Include records without date
    return date.isAfter(_fromDate.subtract(const Duration(seconds: 1))) &&
           date.isBefore(_toDate.add(const Duration(seconds: 1)));
  }

  Future<void> _calculateReportData() async {
    setState(() => _isLoading = true);
    try {
      final isar = ref.read(databaseServiceProvider).isar;

      // 1. Fetch Sales Invoices & Transactions
      final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final transactions = await isar.transactions.filter().isDeletedEqualTo(false).findAll();

      double totalSales = 0.0;
      double totalGstOutput = 0.0;
      double paymentInDisc = 0.0;
      double paymentOutDisc = 0.0;

      for (var inv in invoices) {
        if (_isInDateRange(inv.invoiceDate)) {
          totalSales += (inv.grandTotal ?? 0.0);
          double gst = inv.totalGST ?? ((inv.cgstAmount ?? 0.0) + (inv.sgstAmount ?? 0.0) + (inv.igstAmount ?? 0.0));
          if (gst == 0.0 && inv.grandTotal != null && inv.taxableAmount != null && inv.grandTotal! > inv.taxableAmount!) {
            gst = inv.grandTotal! - inv.taxableAmount!;
          }
          totalGstOutput += gst;
        }
      }

      // Also check sales transactions
      for (var txn in transactions) {
        if (_isInDateRange(txn.transactionDate)) {
          final type = txn.transactionType?.toLowerCase() ?? '';
          if (type.contains('sale') || type.contains('receipt')) {
            if (invoices.isEmpty) {
              totalSales += (txn.amount ?? 0.0);
            }
          } else if (type.contains('income')) {
            _otherIncome += (txn.amount ?? 0.0);
          }
        }
      }

      // 2. Fetch Purchases
      final purchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      double totalPurchases = 0.0;
      double totalGstInput = 0.0;
      for (var pur in purchases) {
        if (_isInDateRange(pur.purchaseDate)) {
          totalPurchases += (pur.grandTotal ?? 0.0);
          double gstIn = pur.totalGST ?? ((pur.cgstAmount ?? 0.0) + (pur.sgstAmount ?? 0.0) + (pur.igstAmount ?? 0.0));
          if (gstIn == 0.0 && pur.grandTotal != null && pur.taxableAmount != null && pur.grandTotal! > pur.taxableAmount!) {
            gstIn = pur.grandTotal! - pur.taxableAmount!;
          }
          totalGstInput += gstIn;
        }
      }

      // If no purchases recorded, check transaction purchases
      if (totalPurchases == 0.0) {
        for (var txn in transactions) {
          if (_isInDateRange(txn.transactionDate)) {
            final type = txn.transactionType?.toLowerCase() ?? '';
            if (type.contains('purchase')) {
              totalPurchases += (txn.amount ?? 0.0);
            }
          }
        }
      }

      // 3. Fetch Credit & Debit Notes
      final creditNotes = await isar.creditNotes.filter().isDeletedEqualTo(false).findAll();
      double totalCrNote = 0.0;
      for (var cn in creditNotes) {
        if (_isInDateRange(cn.creditNoteDate)) {
          totalCrNote += (cn.grandTotal ?? 0.0);
        }
      }

      final debitNotes = await isar.debitNotes.filter().isDeletedEqualTo(false).findAll();
      double totalDrNote = 0.0;
      for (var dn in debitNotes) {
        if (_isInDateRange(dn.debitNoteDate)) {
          totalDrNote += (dn.grandTotal ?? 0.0);
        }
      }

      // 4. Fetch Expenses
      final expenses = await isar.expenses.filter().isDeletedEqualTo(false).findAll();
      double directExp = 0.0;
      double indirectExp = 0.0;
      double interestExp = 0.0;
      double processingFeeExp = 0.0;

      for (var exp in expenses) {
        if (_isInDateRange(exp.expenseDate)) {
          final category = exp.category?.toLowerCase() ?? '';
          final amount = exp.amount ?? 0.0;
          if (category.contains('direct')) {
            directExp += amount;
          } else if (category.contains('interest')) {
            interestExp += amount;
          } else if (category.contains('processing')) {
            processingFeeExp += amount;
          } else {
            indirectExp += amount;
          }
        }
      }

      // 5. Calculate Stock Valuation based on Actual Purchase Rates
      final items = await isar.items.filter().isDeletedEqualTo(false).findAll();
      final purchaseItems = await isar.collection<PurchaseItem>().filter().isDeletedEqualTo(false).findAll();

      double closingVal = 0.0;
      double openingVal = 0.0;
      for (var item in items) {
        // Find actual purchase rates from purchase history for this item
        double actualPurchaseRate = 0.0;
        final itemPurchases = purchaseItems.where((p) => p.itemId == item.id).toList();
        if (itemPurchases.isNotEmpty) {
          double totalCost = 0.0;
          double totalQty = 0.0;
          for (var pi in itemPurchases) {
            final qty = (pi.quantity ?? 0.0);
            final rate = (pi.rate ?? 0.0);
            if (qty > 0 && rate > 0) {
              totalCost += (qty * rate);
              totalQty += qty;
            }
          }
          if (totalQty > 0) {
            actualPurchaseRate = totalCost / totalQty;
          }
        }

        // Fallback hierarchy: actual purchase history rate -> buyRate -> wholesaleRate -> sellRate
        if (actualPurchaseRate <= 0.0) {
          actualPurchaseRate = (item.buyRate != null && item.buyRate! > 0)
              ? item.buyRate!
              : (item.wholesaleRate != null && item.wholesaleRate! > 0)
                  ? item.wholesaleRate!
                  : (item.sellRate ?? 0.0);
        }

        if (item.currentStock != null && item.currentStock! > 0) {
          closingVal += item.currentStock! * actualPurchaseRate;
        }
        if (item.openingStock != null && item.openingStock! > 0) {
          openingVal += item.openingStock! * actualPurchaseRate;
        }
      }

      setState(() {
        _saleAmount = totalSales;
        _creditNoteAmount = totalCrNote;
        _purchaseAmount = totalPurchases;
        _debitNoteAmount = totalDrNote;
        _paymentOutDiscount = paymentOutDisc;

        _closingStock = closingVal;
        _openingStock = openingVal;

        _otherDirectExpense = directExp;
        _paymentInDiscount = paymentInDisc;

        _gstPayable = totalGstOutput;
        _gstReceivable = totalGstInput;

        _otherExpense = indirectExp;
        _loanInterestExpense = interestExp;
        _loanProcessingFee = processingFeeExp;
      });
    } catch (e) {
      debugPrint('[PROFIT LOSS CALC ERROR] $e');
    }
    setState(() => _isLoading = false);
  }

  double get _totalDirectExpenses => _otherDirectExpense + _paymentInDiscount;
  double get _totalTaxPayable => _gstPayable + _tcsPayable + _tdsPayable;
  double get _totalTaxReceivable => _gstReceivable + _tcsReceivable + _tdsReceivable;

  double get _grossProfit {
    final totalInflows = _saleAmount + _saleFaAmount + _debitNoteAmount + _paymentOutDiscount + _closingStock + _closingFaStock + _totalTaxReceivable;
    final totalOutflows = _creditNoteAmount + _purchaseAmount + _purchaseFaAmount + _openingStock + _openingFaStock + _totalDirectExpenses + _totalTaxPayable;
    return totalInflows - totalOutflows;
  }

  double get _totalIndirectExpenses => _otherExpense + _loanInterestExpense + _loanProcessingFee + _loanChargesExpense;

  double get _netProfit => _grossProfit + _otherIncome - _totalIndirectExpenses;

  Future<void> _exportPdf() async {
    final rows = [
      ['Sale (+)', currencyFormat.format(_saleAmount)],
      ['Sale FA (+)', currencyFormat.format(_saleFaAmount)],
      ['Cr. Note/Sale Return (-)', currencyFormat.format(_creditNoteAmount)],
      ['Purchase (-)', currencyFormat.format(_purchaseAmount)],
      ['Purchase FA (-)', currencyFormat.format(_purchaseFaAmount)],
      ['Dr. Note/Purchase Return (+)', currencyFormat.format(_debitNoteAmount)],
      ['Payment Out Discount (+)', currencyFormat.format(_paymentOutDiscount)],
      ['Opening Stock (-)', currencyFormat.format(_openingStock)],
      ['Closing Stock (+)', currencyFormat.format(_closingStock)],
      ['Other Direct Expense (-)', currencyFormat.format(_otherDirectExpense)],
      ['GST Payable (-)', currencyFormat.format(_gstPayable)],
      ['GST Receivable (+)', currencyFormat.format(_gstReceivable)],
      ['GROSS PROFIT', currencyFormat.format(_grossProfit)],
      ['Other Income (+)', currencyFormat.format(_otherIncome)],
      ['Other Expense (-)', currencyFormat.format(_otherExpense)],
      ['NET PROFIT', currencyFormat.format(_netProfit)],
    ];

    try {
      final exportService = ExportService();
      await exportService.exportToPDF(
        title: 'Profit & Loss Statement',
        subtitle: '${DateFormat('dd/MM/yyyy').format(_fromDate)} TO ${DateFormat('dd/MM/yyyy').format(_toDate)}',
        headers: ['Particulars', 'Amount (₹)'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    final rows = [
      ['Sale (+)', _saleAmount],
      ['Sale FA (+)', _saleFaAmount],
      ['Cr. Note/Sale Return (-)', _creditNoteAmount],
      ['Purchase (-)', _purchaseAmount],
      ['Purchase FA (-)', _purchaseFaAmount],
      ['Dr. Note/Purchase Return (+)', _debitNoteAmount],
      ['Payment Out Discount (+)', _paymentOutDiscount],
      ['Opening Stock (-)', _openingStock],
      ['Closing Stock (+)', _closingStock],
      ['Other Direct Expense (-)', _otherDirectExpense],
      ['GST Payable (-)', _gstPayable],
      ['GST Receivable (+)', _gstReceivable],
      ['GROSS PROFIT', _grossProfit],
      ['Other Income (+)', _otherIncome],
      ['Other Expense (-)', _otherExpense],
      ['NET PROFIT', _netProfit],
    ];

    try {
      final exportService = ExportService();
      await exportService.exportToExcel(
        title: 'Profit_Loss_Report_${DateFormat('dd_MM_yyyy').format(_fromDate)}',
        headers: ['Particulars', 'Amount'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Executive Slate Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profit & Loss Intelligence',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
                ),
                Text(
                  'FINANCIAL HEALTH STATEMENT',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF34D399), letterSpacing: 1.2),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Glassmorphic PDF Export Badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: _exportPdf,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 6)],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          // Glassmorphic Excel Export Badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _exportExcel,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 6)],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.table_chart_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('XLS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
              child: Column(
                children: [
                  // 1. Date Range Segment Filter Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['This Month', 'Today', 'This Quarter', 'This Year', 'Custom Range']
                                .map((r) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(r),
                                        selected: _selectedRange == r,
                                        selectedColor: const Color(0xFF10B981),
                                        backgroundColor: const Color(0xFF334155),
                                        labelStyle: TextStyle(
                                          color: _selectedRange == r ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                        onSelected: (_) => _onRangeChanged(r),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDateRange,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: Colors.cyanAccent, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Range: ${dateFormat.format(_fromDate)}  ➔  ${dateFormat.format(_toDate)}',
                                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Executive Hero KPI Cards Grid (Gross Profit & Net Profit)
                  Row(
                    children: [
                      Expanded(
                        child: _buildExecutiveKpiCard(
                          title: 'GROSS PROFIT',
                          amount: _grossProfit,
                          icon: Icons.account_balance_wallet_rounded,
                          gradientColors: [const Color(0xFF065F46), const Color(0xFF047857)],
                          borderColor: const Color(0xFF10B981),
                          textColor: const Color(0xFF34D399),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildExecutiveKpiCard(
                          title: 'NET PROFIT',
                          amount: _netProfit,
                          icon: Icons.monetization_on_rounded,
                          gradientColors: [const Color(0xFF0F766E), const Color(0xFF115E59)],
                          borderColor: const Color(0xFF14B8A6),
                          textColor: const Color(0xFF2DD4BF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Sectional Financial Cards Grid
                  _buildSectionCard(
                    title: 'Operating Sales & Returns',
                    icon: Icons.trending_up_rounded,
                    accentColor: const Color(0xFF10B981),
                    items: [
                      _LineItemData('Sale (+)', _saleAmount, isPositive: true),
                      _LineItemData('Sale FA (+)', _saleFaAmount, isPositive: true),
                      _LineItemData('Cr. Note / Sale Return (-)', _creditNoteAmount, isNegative: true),
                      _LineItemData('Dr. Note / Purchase Return (+)', _debitNoteAmount, isPositive: true),
                      _LineItemData('Payment Out Discount (+)', _paymentOutDiscount, isPositive: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildSectionCard(
                    title: 'Purchases & Procurement',
                    icon: Icons.shopping_cart_rounded,
                    accentColor: const Color(0xFFF43F5E),
                    items: [
                      _LineItemData('Purchase (-)', _purchaseAmount, isNegative: true),
                      _LineItemData('Purchase FA (-)', _purchaseFaAmount, isNegative: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildSectionCard(
                    title: 'Stock Valuation & Inventory',
                    icon: Icons.inventory_2_rounded,
                    accentColor: const Color(0xFF3B82F6),
                    items: [
                      _LineItemData('Opening Stock (-)', _openingStock, isNegative: true),
                      _LineItemData('Closing Stock (+)', _closingStock, isPositive: true),
                      _LineItemData('Opening FA Stock (-)', _openingFaStock, isNegative: true),
                      _LineItemData('Closing FA Stock (+)', _closingFaStock, isPositive: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildSectionCard(
                    title: 'Direct Expenses & Outflows',
                    icon: Icons.payments_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    items: [
                      _LineItemData('Other Direct Expense (-)', _otherDirectExpense, isNegative: true),
                      _LineItemData('Payment In Discount (-)', _paymentInDiscount, isNegative: true),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildSectionCard(
                    title: 'Taxation Liabilities & Credits',
                    icon: Icons.gavel_rounded,
                    accentColor: const Color(0xFF8B5CF6),
                    items: [
                      _LineItemData('GST Payable (-)', _gstPayable, isNegative: true),
                      _LineItemData('TCS Payable (-)', _tcsPayable, isNegative: true),
                      _LineItemData('TDS Payable (-)', _tdsPayable, isNegative: true),
                      _LineItemData('GST Receivable (+)', _gstReceivable, isPositive: true),
                      _LineItemData('TCS Receivable (+)', _tcsReceivable, isPositive: true),
                      _LineItemData('TDS Receivable (+)', _tdsReceivable, isPositive: true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🌟 GROSS PROFIT HIGHLIGHT BANNER
                  _buildHighlightCardBanner(
                    title: 'GROSS PROFIT STATEMENT',
                    amount: _grossProfit,
                    subtitle: 'Total Operating Revenue Minus Cost of Goods & Direct Expenses',
                    gradientColors: [const Color(0xFF047857), const Color(0xFF064E3B)],
                    borderColor: const Color(0xFF34D399),
                  ),
                  const SizedBox(height: 16),

                  _buildSectionCard(
                    title: 'Other Income & Indirect Expenses',
                    icon: Icons.account_balance_rounded,
                    accentColor: const Color(0xFFEC4899),
                    items: [
                      _LineItemData('Other Income (+)', _otherIncome, isPositive: true),
                      _LineItemData('Other Expense (-)', _otherExpense, isNegative: true),
                      _LineItemData('Loan Interest Expense (-)', _loanInterestExpense, isNegative: true),
                      _LineItemData('Loan Processing Fee Expense (-)', _loanProcessingFee, isNegative: true),
                      _LineItemData('Charges on Loan Expense (-)', _loanChargesExpense, isNegative: true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🏆 NET PROFIT HIGHLIGHT HERO BANNER
                  _buildHighlightCardBanner(
                    title: 'NET PROFIT STATEMENT',
                    amount: _netProfit,
                    subtitle: 'Final Net Earnings After All Direct & Indirect Outflows',
                    gradientColors: [const Color(0xFF0F766E), const Color(0xFF134E4A)],
                    borderColor: const Color(0xFF2DD4BF),
                    isHero: true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildExecutiveKpiCard({
    required String title,
    required double amount,
    required IconData icon,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: borderColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1.0),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: textColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currencyFormat.format(amount),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: amount >= 0 ? textColor : Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<_LineItemData> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: accentColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: items.map((item) {
                Color valColor = Colors.white70;
                if (item.amount > 0) {
                  if (item.isPositive) valColor = const Color(0xFF34D399);
                  if (item.isNegative) valColor = const Color(0xFFF87171);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        currencyFormat.format(item.amount),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCardBanner({
    required String title,
    required double amount,
    required String subtitle,
    required List<Color> gradientColors,
    required Color borderColor,
    bool isHero = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isHero ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(color: borderColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.1),
              ),
              Icon(isHero ? Icons.military_tech_rounded : Icons.verified_rounded, color: Colors.amberAccent, size: 22),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(fontSize: isHero ? 28 : 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LineItemData {
  final String label;
  final double amount;
  final bool isPositive;
  final bool isNegative;

  _LineItemData(this.label, this.amount, {this.isPositive = false, this.isNegative = false});
}
