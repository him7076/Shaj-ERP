import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/domain/repositories/analytics_repository.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final DatabaseService _dbService;

  AnalyticsRepositoryImpl(this._dbService);

  @override
  Future<DashboardAnalyticsSummary> getDashboardAnalytics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final isar = _dbService.isar;
      final now = DateTime.now();
      
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final rangeStart = startDate ?? DateTime(now.year, now.month, 1);
      final rangeEnd = endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Fetch all non-deleted Invoices, Purchases, and Transactions
      final allInvoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final allPurchases = await isar.collection<Purchase>().filter().isDeletedEqualTo(false).findAll();
      final allTransactions = await isar.transactions.filter().isDeletedEqualTo(false).findAll();

      bool isWithin(DateTime? dt, DateTime s, DateTime e) {
        if (dt == null) return false;
        return (dt.isAfter(s.subtract(const Duration(seconds: 1))) &&
                dt.isBefore(e.add(const Duration(seconds: 1))));
      }

      // 1. Today's Sales
      double todaySales = 0.0;
      for (var inv in allInvoices) {
        if (inv.paymentStatus != 'Cancelled' && isWithin(inv.invoiceDate ?? inv.createdAt, startOfToday, endOfToday)) {
          todaySales += (inv.grandTotal ?? 0.0);
        }
      }
      for (var txn in allTransactions) {
        if (txn.transactionType == 'Sales' && isWithin(txn.transactionDate ?? txn.createdAt, startOfToday, endOfToday)) {
          if (!allInvoices.any((i) => i.uuid == txn.uuid || i.invoiceNumber == txn.transactionNumber)) {
            todaySales += (txn.amount ?? 0.0);
          }
        }
      }

      // 2. Period Sales (Invoices + Standalone Sales Transactions only)
      double monthlySales = 0.0;
      for (var inv in allInvoices) {
        if (inv.paymentStatus != 'Cancelled' && isWithin(inv.invoiceDate ?? inv.createdAt, rangeStart, rangeEnd)) {
          monthlySales += (inv.grandTotal ?? 0.0);
        }
      }
      for (var txn in allTransactions) {
        if (txn.transactionType == 'Sales' && isWithin(txn.transactionDate ?? txn.createdAt, rangeStart, rangeEnd)) {
          if (!allInvoices.any((i) => i.uuid == txn.uuid || i.invoiceNumber == txn.transactionNumber)) {
            monthlySales += (txn.amount ?? 0.0);
          }
        }
      }

      // 3. Period Purchases (Purchase Bills + Standalone Purchase Transactions only)
      double monthlyPurchases = 0.0;
      for (var pur in allPurchases) {
        if (pur.paymentStatus != 'Cancelled' && isWithin(pur.purchaseDate ?? pur.createdAt, rangeStart, rangeEnd)) {
          monthlyPurchases += (pur.grandTotal ?? 0.0);
        }
      }
      for (var txn in allTransactions) {
        if (txn.transactionType == 'Purchase' && isWithin(txn.transactionDate ?? txn.createdAt, rangeStart, rangeEnd)) {
          if (!allPurchases.any((p) => p.uuid == txn.uuid || p.purchaseNumber == txn.transactionNumber)) {
            monthlyPurchases += (txn.amount ?? 0.0);
          }
        }
      }

    // 3. Pending Orders Count
    final pendingOrdersCount = await isar.orders
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .statusEqualTo('Pending')
        .count();

    // 4. Receivables and Payables outstanding
    final parties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
    double totalOutstanding = 0.0;
    double totalPayable = 0.0;
    for (var p in parties) {
      final pUuid = p.uuid;
      final pName = p.partyName?.trim().toLowerCase();
      final pId = p.id;

      double salesPending = 0.0;
      final partyInvoices = allInvoices.where((inv) {
        final match = (pUuid != null && inv.partyUuid == pUuid) ||
                      (pName != null && inv.partyName?.trim().toLowerCase() == pName) ||
                      inv.partyId == pId;
        return match && inv.paymentStatus != 'Cancelled';
      }).toList();
      for (var inv in partyInvoices) {
        salesPending += (inv.pendingAmount ?? ((inv.grandTotal ?? 0.0) - (inv.paidAmount ?? 0.0)));
      }

      double purchasePending = 0.0;
      final partyPurchases = allPurchases.where((pur) {
        final match = (pUuid != null && pur.partyUuid == pUuid) ||
                      (pName != null && pur.partyName?.trim().toLowerCase() == pName) ||
                      pur.partyId == pId;
        return match && pur.paymentStatus != 'Cancelled';
      }).toList();
      for (var pur in partyPurchases) {
        purchasePending += (pur.pendingAmount ?? ((pur.grandTotal ?? 0.0) - (pur.paidAmount ?? 0.0)));
      }

      final opening = p.openingBalance ?? 0.0;
      final storedBal = p.outstandingBalance ?? 0.0;

      if (p.partyType == 'Supplier') {
        final due = purchasePending > 0 ? purchasePending : (storedBal != 0 ? storedBal : opening);
        if (due > 0) totalPayable += due;
      } else {
        final due = salesPending > 0 ? salesPending : (storedBal != 0 ? storedBal : opening);
        if (due > 0) totalOutstanding += due;
      }
    }

    // 5. Low Stock Items Count
    final items = await isar.items.filter().isDeletedEqualTo(false).findAll();
    int lowStockCount = 0;
    for (var item in items) {
      final stock = item.currentStock ?? 0.0;
      final reorder = item.reorderLevel ?? 0.0;
      if (stock <= reorder) {
        lowStockCount++;
      }
    }

    // 6. Top Customers (last 30 days)
    final date30DaysAgo = now.subtract(const Duration(days: 30));
    final recentInvoices = (await isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .invoiceDateBetween(date30DaysAgo, now)
        .findAll()).where((i) => i.paymentStatus != 'Cancelled').toList();

    final Map<String, _CustomerAggregate> customerMap = {};
    for (var inv in recentInvoices) {
      final name = inv.partyName ?? 'Unknown Party';
      final total = inv.grandTotal ?? 0.0;
      
      // Look up party from pre-loaded parties to avoid inv.party.value crashes on minified Web
      final matchingParty = parties.firstWhere(
        (p) => p.id == inv.partyId,
        orElse: () => Party(),
      );
      final outstanding = matchingParty.outstandingBalance ?? 0.0;

      if (customerMap.containsKey(name)) {
        customerMap[name]!.revenue += total;
      } else {
        customerMap[name] = _CustomerAggregate(name, total, outstanding);
      }
    }

    final topCustomers = customerMap.values.map((agg) {
      return TopCustomerEntry(
        partyName: agg.name,
        revenue: agg.revenue,
        outstanding: agg.outstanding,
      );
    }).toList();
    topCustomers.sort((a, b) => b.revenue.compareTo(a.revenue));

    // 7. Top Products (last 30 days)
    final Map<String, _ProductAggregate> productMap = {};
    for (var inv in recentInvoices) {
      final invoiceItems = kIsWeb
          ? (await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll())
              .where((item) => item.parentInvoiceId == inv.id)
              .toList()
          : await isar.invoiceItems
              .filter()
              .invoice((q) => q.idEqualTo(inv.id))
              .and()
              .isDeletedEqualTo(false)
              .findAll();

      for (var item in invoiceItems) {
        final name = item.itemName ?? 'Unknown Product';
        final qty = (item.quantity ?? 0.0) + (item.freeQuantity ?? 0.0);
        final revenue = item.totalAmount ?? 0.0;

        if (productMap.containsKey(name)) {
          productMap[name]!.qty += qty;
          productMap[name]!.revenue += revenue;
        } else {
          productMap[name] = _ProductAggregate(name, qty, revenue);
        }
      }
    }

    final topProducts = productMap.values.map((agg) {
      return TopProductEntry(
        itemName: agg.name,
        quantitySold: agg.qty,
        revenue: agg.revenue,
      );
    }).toList();
    topProducts.sort((a, b) => b.revenue.compareTo(a.revenue));

    // 8. Daily Sales Points (last 30 days)
    final List<DailySalesPoint> dailySalesPoints = [];
    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final dayInvoices = (await isar.invoices
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoiceDateBetween(dateStart, dateEnd)
          .findAll()).where((i) => i.paymentStatus != 'Cancelled').toList();

      final daySum = dayInvoices.fold(0.0, (sum, inv) => sum + (inv.grandTotal ?? 0.0));
      dailySalesPoints.add(DailySalesPoint(date: date, salesAmount: daySum));
    }

    return DashboardAnalyticsSummary(
      todaySales: todaySales,
      monthlySales: monthlySales,
      monthlyPurchases: monthlyPurchases,
      pendingOrdersCount: pendingOrdersCount,
      totalOutstanding: totalOutstanding,
      totalPayable: totalPayable,
      lowStockCount: lowStockCount,
      topCustomers: topCustomers.take(5).toList(),
      topProducts: topProducts.take(5).toList(),
      dailySalesPoints: dailySalesPoints,
    );
    } catch (e, stackTrace) {
      print('DASHBOARD METRICS ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }
}

class _CustomerAggregate {
  final String name;
  double revenue;
  final double outstanding;
  _CustomerAggregate(this.name, this.revenue, this.outstanding);
}

class _ProductAggregate {
  final String name;
  double qty;
  double revenue;
  _ProductAggregate(this.name, this.qty, this.revenue);
}
