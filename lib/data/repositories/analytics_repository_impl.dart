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

    // 4. Receivables and Payables — use Party.outstandingBalance directly
    // OPTIMIZED: Previous code loaded ALL invoices + ALL purchases + ran party.load()
    // per record in nested loops. Now uses pre-stored balance on Party collection.
    final parties = await isar.partys.filter().isDeletedEqualTo(false).findAll();

    double totalOutstanding = 0.0;
    double totalPayable = 0.0;

    for (var p in parties) {
      final bal = p.outstandingBalance ?? p.openingBalance ?? 0.0;
      if (bal <= 0) continue;
      
      final pType = (p.partyType ?? '').trim().toLowerCase();
      final isSupp = pType == 'supplier' || pType == 'vendor' || p.balanceType == 'credit';

      if (isSupp) {
        totalPayable += bal;
      } else {
        totalOutstanding += bal;
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

    // 7. Top Products (last 30 days) — single bulk query instead of per-invoice N+1
    final allInvItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
    final recentInvIds = recentInvoices.map((i) => i.id).toSet();
    
    final Map<String, _ProductAggregate> productMap = {};
    for (var item in allInvItems) {
      // Only include items belonging to recent invoices
      if (item.parentInvoiceId == null || !recentInvIds.contains(item.parentInvoiceId)) continue;
      
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

    final topProducts = productMap.values.map((agg) {
      return TopProductEntry(
        itemName: agg.name,
        quantitySold: agg.qty,
        revenue: agg.revenue,
      );
    }).toList();
    topProducts.sort((a, b) => b.revenue.compareTo(a.revenue));

    // 8. Daily Sales Points (last 30 days) - In-memory calculation for instant response
    final List<DailySalesPoint> dailySalesPoints = [];
    final date30DaysStart = now.subtract(const Duration(days: 30));
    final invoices30Days = allInvoices.where((i) {
      final dt = i.invoiceDate ?? i.createdAt;
      return dt != null && dt.isAfter(date30DaysStart) && i.paymentStatus != 'Cancelled';
    }).toList();

    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final daySum = invoices30Days
          .where((i) => isWithin(i.invoiceDate ?? i.createdAt, dateStart, dateEnd))
          .fold(0.0, (sum, inv) => sum + (inv.grandTotal ?? 0.0));

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
      return DashboardAnalyticsSummary.empty();
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
