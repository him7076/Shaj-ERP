import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';

enum ReportDatePreset {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  financialYear,
  custom,
}

class ReportDateFilter {
  final ReportDatePreset preset;
  final DateTime startDate;
  final DateTime endDate;

  ReportDateFilter({
    required this.preset,
    required this.startDate,
    required this.endDate,
  });

  factory ReportDateFilter.fromPreset(ReportDatePreset preset, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day);
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case ReportDatePreset.today:
        // Already initialized to today
        break;
      case ReportDatePreset.yesterday:
        start = start.subtract(const Duration(days: 1));
        end = DateTime(start.year, start.month, start.day, 23, 59, 59);
        break;
      case ReportDatePreset.thisWeek:
        // Start of week (Monday)
        final daysToSubtract = start.weekday - 1;
        start = start.subtract(Duration(days: daysToSubtract));
        break;
      case ReportDatePreset.thisMonth:
        start = DateTime(start.year, start.month, 1);
        break;
      case ReportDatePreset.lastMonth:
        final prevMonth = start.month == 1 ? 12 : start.month - 1;
        final prevYear = start.month == 1 ? start.year - 1 : start.year;
        start = DateTime(prevYear, prevMonth, 1);
        end = DateTime(start.year, start.month + 1, 0, 23, 59, 59);
        break;
      case ReportDatePreset.thisYear:
        start = DateTime(start.year, 1, 1);
        break;
      case ReportDatePreset.financialYear:
        // Indian Financial Year: April 1st to March 31st
        if (start.month >= 4) {
          start = DateTime(start.year, 4, 1);
          end = DateTime(start.year + 1, 3, 31, 23, 59, 59);
        } else {
          start = DateTime(start.year - 1, 4, 1);
          end = DateTime(start.year, 3, 31, 23, 59, 59);
        }
        break;
      case ReportDatePreset.custom:
        start = customStart ?? start;
        end = customEnd ?? end;
        break;
    }

    return ReportDateFilter(
      preset: preset,
      startDate: start,
      endDate: end,
    );
  }

  String get displayName {
    switch (preset) {
      case ReportDatePreset.today: return 'Today';
      case ReportDatePreset.yesterday: return 'Yesterday';
      case ReportDatePreset.thisWeek: return 'This Week';
      case ReportDatePreset.thisMonth: return 'This Month';
      case ReportDatePreset.lastMonth: return 'Last Month';
      case ReportDatePreset.thisYear: return 'This Year';
      case ReportDatePreset.financialYear: return 'Financial Year';
      case ReportDatePreset.custom: return 'Custom Range';
    }
  }
}

class SalesReportSummary {
  final double totalSales;
  final double totalGST;
  final double totalDiscount;
  final double netSales;
  final int invoiceCount;
  final List<Invoice> invoices;

  SalesReportSummary({
    required this.totalSales,
    required this.totalGST,
    required this.totalDiscount,
    required this.netSales,
    required this.invoiceCount,
    required this.invoices,
  });
}

class GSTReportSummary {
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalGST;
  final int invoiceCount;
  final List<HsnSummaryEntry> hsnSummaries;

  GSTReportSummary({
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalGST,
    required this.invoiceCount,
    required this.hsnSummaries,
  });
}

class HsnSummaryEntry {
  final String hsnCode;
  final double quantity;
  final double taxableAmount;
  final double gstRate;
  final double gstAmount;

  HsnSummaryEntry({
    required this.hsnCode,
    required this.quantity,
    required this.taxableAmount,
    required this.gstRate,
    required this.gstAmount,
  });
}

class StockReportSummary {
  final double totalValue;
  final int availableCount;
  final int lowStockCount;
  final int outOfStockCount;
  final List<StockReportLine> lines;

  StockReportSummary({
    required this.totalValue,
    required this.availableCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.lines,
  });
}

class StockReportLine {
  final String itemName;
  final String sku;
  final double currentStock;
  final double reorderLevel;
  final double buyRate;
  final double stockValue;
  final String status; // 'Available', 'Low Stock', 'Out Of Stock'

  StockReportLine({
    required this.itemName,
    required this.sku,
    required this.currentStock,
    required this.reorderLevel,
    required this.buyRate,
    required this.stockValue,
    required this.status,
  });
}

class StockMovementEntry {
  final DateTime date;
  final String itemName;
  final String sku;
  final double qtyIn;
  final double qtyOut;
  final double balance;
  final String reason;

  StockMovementEntry({
    required this.date,
    required this.itemName,
    required this.sku,
    required this.qtyIn,
    required this.qtyOut,
    required this.balance,
    required this.reason,
  });
}

class OutstandingReportSummary {
  final double totalOutstanding;
  final int overdueCount;
  final int limitExceededCount;
  final List<OutstandingEntry> entries;

  OutstandingReportSummary({
    required this.totalOutstanding,
    required this.overdueCount,
    required this.limitExceededCount,
    required this.entries,
  });
}

class OutstandingEntry {
  final int partyId;
  final String partyUuid;
  final String partyName;
  final String mobileNumber;
  final double creditLimit;
  final double outstandingAmount;
  final int dueDays;
  final bool isOverdue;
  final bool isLimitExceeded;

  OutstandingEntry({
    required this.partyId,
    required this.partyUuid,
    required this.partyName,
    required this.mobileNumber,
    required this.creditLimit,
    required this.outstandingAmount,
    required this.dueDays,
    required this.isOverdue,
    required this.isLimitExceeded,
  });
}

class PartyLedgerSummary {
  final double openingBalance;
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final List<LedgerEntry> entries;

  PartyLedgerSummary({
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    required this.entries,
  });
}

class LedgerEntry {
  final DateTime date;
  final String voucherNo;
  final String voucherType; // 'Sale Invoice', 'Receipt Payment', 'Opening Balance'
  final double debit;
  final double credit;
  final double balance;

  LedgerEntry({
    required this.date,
    required this.voucherNo,
    required this.voucherType,
    required this.debit,
    required this.credit,
    required this.balance,
  });
}

class SalesmanPerformanceSummary {
  final int ordersTaken;
  final double salesAmount;
  final int newPartiesCount;
  final double conversionRate; // orders / visited parties
  final List<SalesmanRecord> records;

  SalesmanPerformanceSummary({
    required this.ordersTaken,
    required this.salesAmount,
    required this.newPartiesCount,
    required this.conversionRate,
    required this.records,
  });
}

class SalesmanRecord {
  final String salesmanName;
  final int ordersCount;
  final double totalSales;
  final int customersAdded;

  SalesmanRecord({
    required this.salesmanName,
    required this.ordersCount,
    required this.totalSales,
    required this.customersAdded,
  });
}

class ProfitSummary {
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double netProfit;
  final double profitPercentage;
  final List<ProfitLineItem> lines;

  ProfitSummary({
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.netProfit,
    required this.profitPercentage,
    required this.lines,
  });
}

class ProfitLineItem {
  final String itemName;
  final double qtySold;
  final double revenue;
  final double cost;
  final double profit;
  final double marginPercent;

  ProfitLineItem({
    required this.itemName,
    required this.qtySold,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.marginPercent,
  });
}

class DashboardAnalyticsSummary {
  final double todaySales;
  final double monthlySales;
  final int pendingOrdersCount;
  final double totalOutstanding;
  final int lowStockCount;
  final List<TopCustomerEntry> topCustomers;
  final List<TopProductEntry> topProducts;
  final List<DailySalesPoint> dailySalesPoints;

  DashboardAnalyticsSummary({
    required this.todaySales,
    required this.monthlySales,
    required this.pendingOrdersCount,
    required this.totalOutstanding,
    required this.lowStockCount,
    required this.topCustomers,
    required this.topProducts,
    required this.dailySalesPoints,
  });
}

class TopCustomerEntry {
  final String partyName;
  final double revenue;
  final double outstanding;

  TopCustomerEntry({
    required this.partyName,
    required this.revenue,
    required this.outstanding,
  });
}

class TopProductEntry {
  final String itemName;
  final double quantitySold;
  final double revenue;

  TopProductEntry({
    required this.itemName,
    required this.quantitySold,
    required this.revenue,
  });
}

class DailySalesPoint {
  final DateTime date;
  final double salesAmount;

  DailySalesPoint({
    required this.date,
    required this.salesAmount,
  });
}
