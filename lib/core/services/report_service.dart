import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';

class ReportService {
  final DatabaseService _dbService;

  ReportService(this._dbService);

  /// 1. Sales Report
  Future<SalesReportSummary> getSalesReport({
    required DateTime start,
    required DateTime end,
    String? partyUuid,
    String? paymentStatus,
    int offset = 0,
    int limit = 100,
  }) async {
    final isar = _dbService.isar;
    List<Invoice> allMatches;

    if (kIsWeb) {
      var list = await isar.invoices
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoiceDateBetween(start, end)
          .findAll();

      if (partyUuid != null && partyUuid.isNotEmpty) {
        final party = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
        if (party != null) {
          list = list.where((inv) => inv.partyId == party.id).toList();
        } else {
          list = [];
        }
      }

      if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'All') {
        list = list.where((inv) => inv.paymentStatus == paymentStatus).toList();
      }
      allMatches = list;
    } else {
      var query = isar.invoices
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoiceDateBetween(start, end);

      if (partyUuid != null && partyUuid.isNotEmpty) {
        query = query.and().party((q) => q.uuidEqualTo(partyUuid));
      }

      if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'All') {
        query = query.and().paymentStatusEqualTo(paymentStatus);
      }

      allMatches = await query.findAll();
    }

    double totalSales = 0.0;
    double totalGST = 0.0;
    double totalDiscount = 0.0;

    for (var inv in allMatches) {
      if (inv.invoiceStatus == 'Cancelled') continue;
      totalSales += inv.grandTotal ?? 0.0;
      totalGST += inv.totalGST ?? 0.0;
      totalDiscount += inv.discountAmount ?? 0.0;
    }

    // Apply pagination for the returned list slice
    final invoicesSlice = allMatches.skip(offset).take(limit).toList();

    return SalesReportSummary(
      totalSales: totalSales,
      totalGST: totalGST,
      totalDiscount: totalDiscount,
      netSales: totalSales - totalGST,
      invoiceCount: allMatches.length,
      invoices: invoicesSlice,
    );
  }

  /// 2. Order Report
  Future<List<Order>> getOrderReport({
    required DateTime start,
    required DateTime end,
    String? status,
    String? partyUuid,
  }) async {
    final isar = _dbService.isar;

    if (kIsWeb) {
      var list = await isar.orders
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .orderDateBetween(start, end)
          .findAll();

      if (status != null && status.isNotEmpty && status != 'All') {
        list = list.where((o) => o.status == status).toList();
      }

      if (partyUuid != null && partyUuid.isNotEmpty) {
        final party = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
        if (party != null) {
          list = list.where((o) => o.partyId == party.id).toList();
        } else {
          list = [];
        }
      }
      return list;
    }

    var query = isar.orders
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .orderDateBetween(start, end);

    if (status != null && status.isNotEmpty && status != 'All') {
      query = query.and().statusEqualTo(status);
    }

    if (partyUuid != null && partyUuid.isNotEmpty) {
      query = query.and().party((q) => q.uuidEqualTo(partyUuid));
    }

    return await query.findAll();
  }

  /// 3. GST Report
  Future<GSTReportSummary> getGSTReport({
    required DateTime start,
    required DateTime end,
  }) async {
    final isar = _dbService.isar;

    final invoices = await isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .invoiceStatusEqualTo('Active')
        .and()
        .invoiceDateBetween(start, end)
        .findAll();

    double taxableAmount = 0.0;
    double cgstAmount = 0.0;
    double sgstAmount = 0.0;
    double igstAmount = 0.0;
    double totalGST = 0.0;

    // HSN aggregation map
    final Map<String, _HsnAggregate> hsnMap = {};

    for (var inv in invoices) {
      taxableAmount += inv.taxableAmount ?? 0.0;
      cgstAmount += inv.cgstAmount ?? 0.0;
      sgstAmount += inv.sgstAmount ?? 0.0;
      igstAmount += inv.igstAmount ?? 0.0;
      totalGST += inv.totalGST ?? 0.0;

      // Aggregating HSN details from invoice items
      final items = kIsWeb
          ? (await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll())
              .where((item) => item.parentInvoiceId == inv.id)
              .toList()
          : await isar.invoiceItems
              .filter()
              .invoice((q) => q.idEqualTo(inv.id))
              .and()
              .isDeletedEqualTo(false)
              .findAll();

      for (var item in items) {
        final hsn = item.hsnCode ?? 'N/A';
        final qty = (item.quantity ?? 0.0) + (item.freeQuantity ?? 0.0);
        final taxVal = item.taxableAmount ?? 0.0;
        final rate = item.gstRate ?? 0.0;
        final taxAmt = item.gstAmount ?? 0.0;

        final key = '${hsn}_$rate';
        if (hsnMap.containsKey(key)) {
          hsnMap[key]!.add(qty, taxVal, taxAmt);
        } else {
          hsnMap[key] = _HsnAggregate(
            hsnCode: hsn,
            quantity: qty,
            taxableAmount: taxVal,
            gstRate: rate,
            gstAmount: taxAmt,
          );
        }
      }
    }

    final hsnLines = hsnMap.values.map((agg) {
      return HsnSummaryEntry(
        hsnCode: agg.hsnCode,
        quantity: agg.quantity,
        taxableAmount: agg.taxableAmount,
        gstRate: agg.gstRate,
        gstAmount: agg.gstAmount,
      );
    }).toList();

    return GSTReportSummary(
      taxableAmount: taxableAmount,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      totalGST: totalGST,
      invoiceCount: invoices.length,
      hsnSummaries: hsnLines,
    );
  }

  /// 4. Outstanding Accounts Report
  Future<OutstandingReportSummary> getOutstandingReport() async {
    final isar = _dbService.isar;
    final parties = await isar.partys
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .outstandingBalanceGreaterThan(0.0)
        .findAll();

    double totalOutstanding = 0.0;
    int overdueCount = 0;
    int limitExceededCount = 0;

    final List<OutstandingEntry> entries = [];

    final now = DateTime.now();

    for (var party in parties) {
      final balance = party.outstandingBalance ?? 0.0;
      totalOutstanding += balance;

      final limit = party.creditLimit ?? 0.0;
      final limitExceeded = limit > 0 && balance > limit;
      if (limitExceeded) limitExceededCount++;

      // Evaluate due days based on unpaid invoices
      final unpaidInvoices = kIsWeb
          ? (await isar.invoices
              .filter()
              .isDeletedEqualTo(false)
              .and()
              .invoiceStatusEqualTo('Active')
              .findAll())
              .where((inv) => inv.partyId == party.id && (inv.paymentStatus == 'Unpaid' || inv.paymentStatus == 'Partially Paid'))
              .toList()
          : await isar.invoices
              .filter()
              .party((q) => q.uuidEqualTo(party.uuid))
              .and()
              .isDeletedEqualTo(false)
              .and()
              .invoiceStatusEqualTo('Active')
              .and()
              .group((q) => q.paymentStatusEqualTo('Unpaid').or().paymentStatusEqualTo('Partially Paid'))
              .findAll();

      int maxDueDays = 0;
      bool isOverdue = false;

      for (var inv in unpaidInvoices) {
        if (inv.dueDate != null && inv.dueDate!.isBefore(now)) {
          isOverdue = true;
          final diff = now.difference(inv.dueDate!).inDays;
          if (diff > maxDueDays) maxDueDays = diff;
        }
      }

      if (isOverdue) overdueCount++;

      entries.add(OutstandingEntry(
        partyId: party.id,
        partyUuid: party.uuid ?? '',
        partyName: party.partyName ?? 'Unnamed Party',
        mobileNumber: party.mobileNumber ?? 'N/A',
        creditLimit: limit,
        outstandingAmount: balance,
        dueDays: maxDueDays,
        isOverdue: isOverdue,
        isLimitExceeded: limitExceeded,
      ));
    }

    // Sort by outstanding balance descending
    entries.sort((a, b) => b.outstandingAmount.compareTo(a.outstandingAmount));

    return OutstandingReportSummary(
      totalOutstanding: totalOutstanding,
      overdueCount: overdueCount,
      limitExceededCount: limitExceededCount,
      entries: entries,
    );
  }

  /// 5. Party Ledger Statement
  Future<PartyLedgerSummary> getPartyLedger(String partyUuid, DateTime start, DateTime end) async {
    final isar = _dbService.isar;

    // 1. Calculate opening balance (invoices before start date minus paid amounts before start date)
    List<Invoice> preInvoices;
    List<Invoice> rangeInvoices;

    if (kIsWeb) {
      final party = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
      final targetPartyId = party?.id;

      final allPreInvoices = await isar.invoices
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoiceStatusEqualTo('Active')
          .and()
          .invoiceDateLessThan(start)
          .findAll();
      preInvoices = allPreInvoices.where((inv) => inv.partyId == targetPartyId).toList();

      final allRangeInvoices = await isar.invoices
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoiceStatusEqualTo('Active')
          .and()
          .invoiceDateBetween(start, end)
          .findAll();
      rangeInvoices = allRangeInvoices.where((inv) => inv.partyId == targetPartyId).toList();
    } else {
      preInvoices = await isar.invoices
          .filter()
          .party((q) => q.uuidEqualTo(partyUuid))
          .and()
          .isDeletedEqualTo(false)
          .and()
          .invoiceStatusEqualTo('Active')
          .and()
          .invoiceDateLessThan(start)
          .findAll();

      rangeInvoices = await isar.invoices
          .filter()
          .party((q) => q.uuidEqualTo(partyUuid))
          .and()
          .isDeletedEqualTo(false)
          .and()
          .invoiceStatusEqualTo('Active')
          .and()
          .invoiceDateBetween(start, end)
          .findAll();
    }

    double openingDebit = 0.0;
    double openingCredit = 0.0;
    for (var inv in preInvoices) {
      openingDebit += inv.grandTotal ?? 0.0;
      openingCredit += inv.paidAmount ?? 0.0;
    }
    final openingBalance = openingDebit - openingCredit;

    final List<LedgerEntry> entries = [];
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (var inv in rangeInvoices) {
      final date = inv.invoiceDate ?? DateTime.now();
      final total = inv.grandTotal ?? 0.0;
      final paid = inv.paidAmount ?? 0.0;

      // Add Sale Invoice (Debit - Customer owes us)
      entries.add(LedgerEntry(
        date: date,
        voucherNo: inv.invoiceNumber ?? 'N/A',
        voucherType: 'Sale Invoice',
        debit: total,
        credit: 0.0,
        balance: 0.0, // Calculated sequentially below
      ));
      totalDebit += total;

      // Add Payment Receipt (Credit - Customer paid us)
      if (paid > 0) {
        entries.add(LedgerEntry(
          date: inv.updatedAt, // Simulate payment booking timestamp
          voucherNo: 'REC-${inv.invoiceNumber}',
          voucherType: 'Receipt Payment',
          debit: 0.0,
          credit: paid,
          balance: 0.0,
        ));
        totalCredit += paid;
      }
    }

    // Sort chronologically
    entries.sort((a, b) => a.date.compareTo(b.date));

    // Compile running balance
    double runningBalance = openingBalance;
    final List<LedgerEntry> finalEntries = [];
    for (var entry in entries) {
      runningBalance = runningBalance + entry.debit - entry.credit;
      finalEntries.add(LedgerEntry(
        date: entry.date,
        voucherNo: entry.voucherNo,
        voucherType: entry.voucherType,
        debit: entry.debit,
        credit: entry.credit,
        balance: runningBalance,
      ));
    }

    return PartyLedgerSummary(
      openingBalance: openingBalance,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      closingBalance: openingBalance + totalDebit - totalCredit,
      entries: finalEntries,
    );
  }

  /// 6. Inventory Stock Report
  Future<StockReportSummary> getStockReport({String? status}) async {
    final isar = _dbService.isar;
    final items = await isar.items.filter().isDeletedEqualTo(false).findAll();

    double totalValue = 0.0;
    int available = 0;
    int low = 0;
    int out = 0;

    final List<StockReportLine> lines = [];

    for (var item in items) {
      final stock = item.currentStock ?? 0.0;
      final buy = item.buyRate ?? 0.0;
      final value = stock * buy;
      final reorder = item.reorderLevel ?? 0.0;

      totalValue += value;

      String itemStatus = 'Available';
      if (stock <= 0) {
        itemStatus = 'Out Of Stock';
        out++;
      } else if (stock <= reorder) {
        itemStatus = 'Low Stock';
        low++;
      } else {
        available++;
      }

      if (status == null || status == 'All' || status == itemStatus) {
        lines.add(StockReportLine(
          itemName: item.itemName ?? 'Unnamed Item',
          sku: item.sku ?? 'N/A',
          currentStock: stock,
          reorderLevel: reorder,
          buyRate: buy,
          stockValue: value,
          status: itemStatus,
        ));
      }
    }

    return StockReportSummary(
      totalValue: totalValue,
      availableCount: available,
      lowStockCount: low,
      outOfStockCount: out,
      lines: lines,
    );
  }

  /// 7. Stock Movement ledger report parsed from notes
  Future<List<StockMovementEntry>> getStockMovementReport(String itemUuid) async {
    final isar = _dbService.isar;
    final item = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
    if (item == null) return [];

    final notes = item.notes ?? '';
    if (notes.trim().isEmpty) return [];

    final List<StockMovementEntry> entries = [];
    final lines = notes.split('\n');

    final regex = RegExp(r'^\[([\d\-\s:]+)\]\s+(STOCK_IN|STOCK_OUT):\s+([+-]?[\d.]+)\s+\|\s+Bal:\s+([\d.]+)\s+\|\s+Reason:\s+(.*)$');

    for (var line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final dateStr = match.group(1)!;
        final type = match.group(2)!;
        final change = double.parse(match.group(3)!);
        final balance = double.parse(match.group(4)!);
        final reason = match.group(5)!;

        DateTime date;
        try {
          date = DateTime.parse(dateStr.replaceFirst(' ', 'T'));
        } catch (_) {
          date = DateTime.now();
        }

        entries.add(StockMovementEntry(
          date: date,
          itemName: item.itemName ?? 'Unknown',
          sku: item.sku ?? '',
          qtyIn: type == 'STOCK_IN' ? change : 0.0,
          qtyOut: type == 'STOCK_OUT' ? change.abs() : 0.0,
          balance: balance,
          reason: reason,
        ));
      }
    }

    // Sort chronologically (oldest first or newest first, let's return newest first for report view)
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// 8. Salesman Performance Report
  Future<SalesmanPerformanceSummary> getSalesmanPerformance(DateTime start, DateTime end) async {
    final isar = _dbService.isar;

    // Group invoices and orders by salesman name (createdBy field)
    final invoices = await isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .invoiceStatusEqualTo('Active')
        .and()
        .invoiceDateBetween(start, end)
        .findAll();

    final orders = await isar.orders
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .orderDateBetween(start, end)
        .findAll();

    final newParties = await isar.partys
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .createdAtBetween(start, end)
        .findAll();

    final Map<String, _SalesmanAggregate> aggregates = {};

    for (var inv in invoices) {
      final salesman = inv.createdBy ?? 'Admin';
      aggregates.putIfAbsent(salesman, () => _SalesmanAggregate(salesman)).totalSales += inv.grandTotal ?? 0.0;
    }

    for (var ord in orders) {
      final salesman = ord.createdBy ?? 'Admin';
      aggregates.putIfAbsent(salesman, () => _SalesmanAggregate(salesman)).ordersCount++;
    }

    for (var party in newParties) {
      // Assuming a custom createdBy/editedBy or similar is mapped, else default admin
      final salesman = party.email != null ? 'Salesman' : 'Admin'; // simple heuristic for mock representation
      aggregates.putIfAbsent(salesman, () => _SalesmanAggregate(salesman)).customersAdded++;
    }

    final records = aggregates.values.map((agg) {
      return SalesmanRecord(
        salesmanName: agg.name,
        ordersCount: agg.ordersCount,
        totalSales: agg.totalSales,
        customersAdded: agg.customersAdded,
      );
    }).toList();

    int totalOrders = orders.length;
    double totalSalesAmount = invoices.fold(0.0, (sum, item) => sum + (item.grandTotal ?? 0.0));
    int totalNewParties = newParties.length;

    return SalesmanPerformanceSummary(
      ordersTaken: totalOrders,
      salesAmount: totalSalesAmount,
      newPartiesCount: totalNewParties,
      conversionRate: totalOrders > 0 ? (invoices.length / totalOrders) * 100 : 0.0,
      records: records,
    );
  }
}

class _HsnAggregate {
  final String hsnCode;
  final double gstRate;
  double quantity;
  double taxableAmount;
  double gstAmount;

  _HsnAggregate({
    required this.hsnCode,
    required this.gstRate,
    required this.quantity,
    required this.taxableAmount,
    required this.gstAmount,
  });

  void add(double qty, double taxVal, double taxAmt) {
    quantity += qty;
    taxableAmount += taxVal;
    gstAmount += taxAmt;
  }
}

class _SalesmanAggregate {
  final String name;
  int ordersCount = 0;
  double totalSales = 0.0;
  int customersAdded = 0;

  _SalesmanAggregate(this.name);
}
