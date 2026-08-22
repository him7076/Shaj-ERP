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
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';

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
    final startBoundary = DateTime(start.year, start.month, start.day, 0, 0, 0, 0);
    final endBoundary = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    var query = isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .not().paymentStatusEqualTo('Cancelled')
        .and()
        .group((q) => q
            .invoiceDateBetween(startBoundary, endBoundary)
            .or()
            .group((q2) => q2.invoiceDateIsNull().and().createdAtBetween(startBoundary, endBoundary))
        );

    if (partyUuid != null && partyUuid.isNotEmpty) {
      final party = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
      if (party != null) {
        query = query.and().group((q) => q
            .partyIdEqualTo(party.id)
            .or()
            .party((p) => p.uuidEqualTo(partyUuid))
            .or()
            .partyNameEqualTo(party.partyName ?? '', caseSensitive: false)
        );
      } else {
        query = query.and().idEqualTo(-1); // return empty
      }
    }

    if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'All') {
      query = query.and().paymentStatusEqualTo(paymentStatus);
    }

    final allMatches = await query.findAll();

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

    final startBoundary = DateTime(start.year, start.month, start.day, 0, 0, 0, 0);
    final endBoundary = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final invoices = await isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .invoiceDateBetween(startBoundary, endBoundary)
            .or()
            .group((q2) => q2.invoiceDateIsNull().and().createdAtBetween(startBoundary, endBoundary))
        )
        .findAll();

    double taxableAmount = 0.0;
    double cgstAmount = 0.0;
    double sgstAmount = 0.0;
    double igstAmount = 0.0;
    double totalGST = 0.0;

    double b2bTaxable = 0.0;
    double b2bGst = 0.0;
    int b2bCount = 0;

    double b2cTaxable = 0.0;
    double b2cGst = 0.0;
    int b2cCount = 0;

    final Map<String, _HsnAggregate> hsnMap = {};
    
    // Batch fetch invoice items to avoid O(N*M) DB query
    List<InvoiceItem> allItems;
    if (kIsWeb) {
      final validInvoiceIds = invoices.map((i) => i.id).toSet();
      final validInvoiceUuids = invoices.map((i) => i.uuid).whereType<String>().toSet();
      final fetchedAllItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
      allItems = fetchedAllItems.where((item) => 
        (item.parentInvoiceId != null && validInvoiceIds.contains(item.parentInvoiceId)) || 
        (item.parentInvoiceUuid != null && validInvoiceUuids.contains(item.parentInvoiceUuid))
      ).toList();
    } else {
      allItems = await isar.invoiceItems
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoice((q) => q
              .isDeletedEqualTo(false)
              .and()
              .invoiceStatusEqualTo('Active')
              .and()
              .group((q2) => q2
                  .invoiceDateBetween(startBoundary, endBoundary)
                  .or()
                  .group((q3) => q3.invoiceDateIsNull().and().createdAtBetween(startBoundary, endBoundary))
              )
          )
          .findAll();
    }
    
    // Create items map grouped by invoice ID/UUID for O(1) lookup
    final Map<int, List<InvoiceItem>> itemsByInvoiceId = {};
    final Map<String, List<InvoiceItem>> itemsByInvoiceUuid = {};
    for (var item in allItems) {
      if (item.parentInvoiceId != null) {
        itemsByInvoiceId.putIfAbsent(item.parentInvoiceId!, () => []).add(item);
      }
      if (item.parentInvoiceUuid != null && item.parentInvoiceUuid!.isNotEmpty) {
        itemsByInvoiceUuid.putIfAbsent(item.parentInvoiceUuid!, () => []).add(item);
      }
    }

    // Batch fetch parties to avoid N+1 load() calls
    final uniquePartyIds = invoices.map((i) => i.partyId).whereType<int>().toSet().toList();
    final fetchedParties = await isar.partys.getAll(uniquePartyIds);
    final partyMap = {
      for (int i = 0; i < uniquePartyIds.length; i++)
        if (fetchedParties[i] != null) uniquePartyIds[i]: fetchedParties[i]!
    };

    for (var inv in invoices) {
      if (inv.paymentStatus == 'Cancelled') continue;

      // Aggregating HSN details and item totals from invoice items
      final items = (itemsByInvoiceId[inv.id] ?? itemsByInvoiceUuid[inv.uuid] ?? []);

      double calculatedItemTaxable = 0.0;
      double calculatedItemGst = 0.0;

      for (var item in items) {
        final hsn = item.hsnCode ?? 'N/A';
        final qty = (item.quantity ?? 0.0) + (item.freeQuantity ?? 0.0);
        final rate = item.gstRate ?? 0.0;
        final taxVal = (item.taxableAmount != null && item.taxableAmount! > 0)
            ? item.taxableAmount!
            : ((item.quantity ?? 0.0) * (item.rate ?? 0.0) - (item.discount ?? 0.0));
        final taxAmt = (item.gstAmount != null && item.gstAmount! > 0)
            ? item.gstAmount!
            : (taxVal * rate / 100.0);

        calculatedItemTaxable += taxVal;
        calculatedItemGst += taxAmt;

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

      double invTaxable = inv.taxableAmount ?? (inv.subtotal ?? 0.0);
      double invGst = inv.totalGST ?? 0.0;

      if (invTaxable == 0 && calculatedItemTaxable > 0) invTaxable = calculatedItemTaxable;
      if (invGst == 0 && calculatedItemGst > 0) invGst = calculatedItemGst;

      taxableAmount += invTaxable;
      totalGST += invGst;

      if ((inv.cgstAmount ?? 0) > 0 || (inv.sgstAmount ?? 0) > 0 || (inv.igstAmount ?? 0) > 0) {
        cgstAmount += inv.cgstAmount ?? 0.0;
        sgstAmount += inv.sgstAmount ?? 0.0;
        igstAmount += inv.igstAmount ?? 0.0;
      } else {
        cgstAmount += invGst / 2.0;
        sgstAmount += invGst / 2.0;
      }

      final linkedParty = inv.partyId != null ? partyMap[inv.partyId] : null;
      final gstin = (linkedParty?.gstNumber?.trim().isNotEmpty == true)
          ? linkedParty!.gstNumber!.trim()
          : (inv.gstNumber?.trim() ?? '');

      if (gstin.length >= 15) {
        b2bTaxable += invTaxable;
        b2bGst += invGst;
        b2bCount++;
      } else {
        b2cTaxable += invTaxable;
        b2cGst += invGst;
        b2cCount++;
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
      b2bTaxableAmount: b2bTaxable,
      b2bTotalGST: b2bGst,
      b2bInvoiceCount: b2bCount,
      b2cTaxableAmount: b2cTaxable,
      b2cTotalGST: b2cGst,
      b2cInvoiceCount: b2cCount,
      hsnSummaries: hsnLines,
    );
  }

  Future<GSTR2ReportSummary> getGstr2Report({
    required DateTime start,
    required DateTime end,
  }) async {
    final isar = _dbService.isar;
    final startBoundary = DateTime(start.year, start.month, start.day, 0, 0, 0, 0);
    final endBoundary = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

    final purchases = await isar.purchases
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .not().paymentStatusEqualTo('Cancelled')
        .and()
        .group((q) => q
            .purchaseDateBetween(startBoundary, endBoundary)
            .or()
            .group((q2) => q2.purchaseDateIsNull().and().createdAtBetween(startBoundary, endBoundary))
        )
        .findAll();

    double totalTaxable = 0.0;
    double totalCGST = 0.0;
    double totalSGST = 0.0;
    double totalIGST = 0.0;
    double totalITC = 0.0;

    for (var pur in purchases) {
      totalTaxable += (pur.taxableAmount ?? (pur.subtotal ?? 0.0) - (pur.discountAmount ?? 0.0));
      final gst = pur.totalGST ?? 0.0;
      final cgst = pur.cgstAmount ?? (gst / 2);
      final sgst = pur.sgstAmount ?? (gst / 2);
      final igst = pur.igstAmount ?? 0.0;

      totalCGST += cgst;
      totalSGST += sgst;
      totalIGST += igst;
      totalITC += (cgst + sgst + igst);
    }

    return GSTR2ReportSummary(
      purchasesCount: purchases.length,
      totalTaxableAmount: totalTaxable,
      inputCGST: totalCGST,
      inputSGST: totalSGST,
      inputIGST: totalIGST,
      totalITCCredit: totalITC,
      purchases: purchases,
    );
  }

  Future<GSTR3BReportSummary> getGstr3bReport({
    required DateTime start,
    required DateTime end,
  }) async {
    final gstr1 = await getGSTReport(start: start, end: end);
    final gstr2 = await getGstr2Report(start: start, end: end);

    final netCgst = gstr1.cgstAmount - gstr2.inputCGST;
    final netSgst = gstr1.sgstAmount - gstr2.inputSGST;
    final netIgst = gstr1.igstAmount - gstr2.inputIGST;
    final netPayable = gstr1.totalGST - gstr2.totalITCCredit;

    return GSTR3BReportSummary(
      outwardTaxable: gstr1.taxableAmount,
      outwardTaxLiability: gstr1.totalGST,
      inwardTaxable: gstr2.totalTaxableAmount,
      inwardITCCredit: gstr2.totalITCCredit,
      netCGSTPayable: netCgst,
      netSGSTPayable: netSgst,
      netIGSTPayable: netIgst,
      netGSTPayable: netPayable > 0 ? netPayable : 0.0,
      excessITCCarryForward: netPayable < 0 ? netPayable.abs() : 0.0,
    );
  }

  /// Accurate Total Receivables (Customer dues & Debit balance)
  Future<double> getTotalReceivables() async {
    final isar = _dbService.isar;
    final parties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
    double total = 0.0;
    for (var p in parties) {
      final bal = p.outstandingBalance ?? 0.0;
      if (bal > 0 && (p.partyType == 'Customer' || p.balanceType == 'Debit')) {
        total += bal;
      }
    }
    return total;
  }

  /// Accurate Total Payables (Supplier dues & Credit balance)
  Future<double> getTotalPayables() async {
    final isar = _dbService.isar;
    final parties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
    double total = 0.0;
    for (var p in parties) {
      final bal = p.outstandingBalance ?? 0.0;
      if (bal > 0 && (p.partyType == 'Supplier' || p.balanceType == 'Credit')) {
        total += bal;
      }
    }
    return total;
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
      final targetPartyId = party?.id ?? -1;

      preInvoices = await isar.invoices
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoiceStatusEqualTo('Active')
          .and()
          .invoiceDateLessThan(start)
          .and()
          .partyIdEqualTo(targetPartyId)
          .findAll();

      rangeInvoices = await isar.invoices
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoiceStatusEqualTo('Active')
          .and()
          .invoiceDateBetween(start, end)
          .and()
          .partyIdEqualTo(targetPartyId)
          .findAll();
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

    final allPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
    final validPurIds = allPurchases.map((p) => p.id).toSet();
    final validPurUuids = allPurchases.map((p) => p.uuid).whereType<String>().toSet();

    final allPurItems = await isar.collection<PurchaseItem>().filter().isDeletedEqualTo(false).findAll();

    // Map item ID / UUID / Name -> (totalAmt, totalQty) for Weighted Average Purchase Rate calculation
    final Map<String, double> itemPurTotalAmt = {};
    final Map<String, double> itemPurTotalQty = {};
    
    final Map<int, String> itemIdToUuid = {
      for (var i in items)
        if (i.id != null && i.uuid != null) i.id!: i.uuid!
    };

    for (var pi in allPurItems) {
      final isValidParent = (pi.purchaseId != null && validPurIds.contains(pi.purchaseId)) ||
          (pi.purchaseUuid != null && validPurUuids.contains(pi.purchaseUuid)) ||
          pi.purchase.value != null;
      if (!isValidParent) continue;

      final linkedUuid = pi.itemId != null ? itemIdToUuid[pi.itemId!] : null;
      final itemIdStr = pi.itemId?.toString();
      final itemNameKey = pi.itemName?.trim().toLowerCase();

      final keys = <String>{};
      if (linkedUuid != null && linkedUuid.isNotEmpty) keys.add(linkedUuid);
      if (itemIdStr != null && itemIdStr.isNotEmpty && itemIdStr != '0') keys.add(itemIdStr);
      if (itemNameKey != null && itemNameKey.isNotEmpty) keys.add('name_$itemNameKey');

      final qty = pi.quantity ?? 0.0;
      final rate = pi.rate ?? 0.0;
      if (qty > 0) {
        for (var k in keys) {
          itemPurTotalAmt[k] = (itemPurTotalAmt[k] ?? 0.0) + (qty * rate);
          itemPurTotalQty[k] = (itemPurTotalQty[k] ?? 0.0) + qty;
        }
      }
    }

    // Also include StockAdjustment rates in transaction valuation
    final allAdjustments = await isar.collection<StockAdjustment>().filter().isDeletedEqualTo(false).findAll();
    for (var sa in allAdjustments) {
      final qty = sa.quantity ?? 0.0;
      final rate = sa.ratePerUnit ?? 0.0;
      if (qty > 0 && rate > 0) {
        final keys = <String>{};
        if (sa.itemUuid != null && sa.itemUuid!.isNotEmpty) keys.add(sa.itemUuid!);
        if (sa.itemId != null && sa.itemId! > 0) keys.add(sa.itemId!.toString());
        if (sa.itemName != null && sa.itemName!.trim().isNotEmpty) keys.add('name_${sa.itemName!.trim().toLowerCase()}');

        for (var k in keys) {
          itemPurTotalAmt[k] = (itemPurTotalAmt[k] ?? 0.0) + (qty * rate);
          itemPurTotalQty[k] = (itemPurTotalQty[k] ?? 0.0) + qty;
        }
      }
    }

    double totalValue = 0.0;
    int available = 0;
    int low = 0;
    int out = 0;

    final List<StockReportLine> lines = [];

    for (var item in items) {
      final stock = item.currentStock ?? 0.0;
      final key1 = item.id.toString();
      final key2 = item.uuid ?? '';
      final key3 = 'name_${item.itemName?.trim().toLowerCase() ?? ""}';

      final totalPurAmt = itemPurTotalAmt[key2] ?? itemPurTotalAmt[key1] ?? itemPurTotalAmt[key3] ?? 0.0;
      final totalPurQty = itemPurTotalQty[key2] ?? itemPurTotalQty[key1] ?? itemPurTotalQty[key3] ?? 0.0;

      final double effectiveRate = (totalPurQty > 0) ? (totalPurAmt / totalPurQty) : (item.buyRate ?? 0.0);
      final value = stock * effectiveRate;
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
          buyRate: effectiveRate,
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
