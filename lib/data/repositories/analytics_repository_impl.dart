import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
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

      final date30DaysAgo = now.subtract(const Duration(days: 30));
      
      final earliestDate = rangeStart.isBefore(date30DaysAgo) ? rangeStart : date30DaysAgo;
      final latestDate = rangeEnd.isAfter(endOfToday) ? rangeEnd : endOfToday;

      final queryStart = earliestDate.subtract(const Duration(days: 1));
      final queryEnd = latestDate.add(const Duration(days: 1));

      // 1. Fetch ONLY relevant Invoices using DB-level date filtering
      final periodInvoices = await isar.invoices.filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .invoiceDateBetween(queryStart, queryEnd)
              .or()
              .group((q) => q.invoiceDateIsNull().and().createdAtBetween(queryStart, queryEnd))
          )
          .findAll();

      // 2. Fetch ONLY relevant Purchases
      final periodPurchases = await isar.collection<Purchase>().filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .purchaseDateBetween(queryStart, queryEnd)
              .or()
              .group((q) => q.purchaseDateIsNull().and().createdAtBetween(queryStart, queryEnd))
          )
          .findAll();

      // 3. Fetch ONLY relevant Transactions
      final periodTransactions = await isar.transactions.filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .transactionDateBetween(queryStart, queryEnd)
              .or()
              .group((q) => q.transactionDateIsNull().and().createdAtBetween(queryStart, queryEnd))
          )
          .findAll();

      bool isWithin(DateTime? dt, DateTime s, DateTime e) {
        if (dt == null) return false;
        return (dt.isAfter(s.subtract(const Duration(seconds: 1))) &&
                dt.isBefore(e.add(const Duration(seconds: 1))));
      }

      // Calculate Today's Sales
      double todaySales = 0.0;
      for (var inv in periodInvoices) {
        if (inv.paymentStatus != 'Cancelled' && isWithin(inv.invoiceDate ?? inv.createdAt, startOfToday, endOfToday)) {
          todaySales += (inv.grandTotal ?? 0.0);
        }
      }
      for (var txn in periodTransactions) {
        if (txn.transactionType == 'Sales' && isWithin(txn.transactionDate ?? txn.createdAt, startOfToday, endOfToday)) {
          if (!periodInvoices.any((i) => i.uuid == txn.uuid || i.invoiceNumber == txn.transactionNumber)) {
            todaySales += (txn.amount ?? 0.0);
          }
        }
      }

      // Calculate Period Sales
      double monthlySales = 0.0;
      for (var inv in periodInvoices) {
        if (inv.paymentStatus != 'Cancelled' && isWithin(inv.invoiceDate ?? inv.createdAt, rangeStart, rangeEnd)) {
          monthlySales += (inv.grandTotal ?? 0.0);
        }
      }
      for (var txn in periodTransactions) {
        if (txn.transactionType == 'Sales' && isWithin(txn.transactionDate ?? txn.createdAt, rangeStart, rangeEnd)) {
          if (!periodInvoices.any((i) => i.uuid == txn.uuid || i.invoiceNumber == txn.transactionNumber)) {
            monthlySales += (txn.amount ?? 0.0);
          }
        }
      }

      // Calculate Period Purchases
      double monthlyPurchases = 0.0;
      for (var pur in periodPurchases) {
        if (pur.paymentStatus != 'Cancelled' && isWithin(pur.purchaseDate ?? pur.createdAt, rangeStart, rangeEnd)) {
          monthlyPurchases += (pur.grandTotal ?? 0.0);
        }
      }
      for (var txn in periodTransactions) {
        if (txn.transactionType == 'Purchase' && isWithin(txn.transactionDate ?? txn.createdAt, rangeStart, rangeEnd)) {
          if (!periodPurchases.any((p) => p.uuid == txn.uuid || p.purchaseNumber == txn.transactionNumber)) {
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
    final recentInvoices = periodInvoices.where((i) {
      final dt = i.invoiceDate ?? i.createdAt;
      return i.paymentStatus != 'Cancelled' && isWithin(dt, date30DaysAgo, endOfToday);
    }).toList();

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

    // 7. Top Products (last 30 days) — query only required items via chunking
    final recentInvIds = recentInvoices.map((i) => i.id).toSet().toList();
    final List<InvoiceItem> relevantInvItems = [];
    
    // Chunk queries to avoid Isar anyOf limits
    const chunkSize = 500;
    for (var i = 0; i < recentInvIds.length; i += chunkSize) {
      final chunk = recentInvIds.sublist(i, min(i + chunkSize, recentInvIds.length));
      final chunkItems = await isar.invoiceItems.filter()
          .isDeletedEqualTo(false)
          .and()
          .anyOf(chunk, (q, int id) => q.parentInvoiceIdEqualTo(id))
          .findAll();
      relevantInvItems.addAll(chunkItems);
    }
    
    final Map<String, _ProductAggregate> productMap = {};
    for (var item in relevantInvItems) {
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

    // 8. Daily Sales Points (last 30 days) - Reuse already fetched periodInvoices
    final List<DailySalesPoint> dailySalesPoints = [];
    final date30DaysStart = now.subtract(const Duration(days: 30));
    final invoices30Days = periodInvoices.where((i) {
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
