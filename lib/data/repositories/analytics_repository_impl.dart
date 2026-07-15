import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/domain/repositories/analytics_repository.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final DatabaseService _dbService;

  AnalyticsRepositoryImpl(this._dbService);

  @override
  Future<DashboardAnalyticsSummary> getDashboardAnalytics() async {
    try {
      final isar = _dbService.isar;
    final now = DateTime.now();
    
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // 1. Today's Sales
    final todayInvoices = await isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .invoiceStatusEqualTo('Active')
        .and()
        .invoiceDateBetween(startOfToday, endOfToday)
        .findAll();
    final todaySales = todayInvoices.fold(0.0, (sum, inv) => sum + (inv.grandTotal ?? 0.0));

    // 2. Monthly Sales
    final monthlyInvoices = await isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .invoiceStatusEqualTo('Active')
        .and()
        .invoiceDateBetween(startOfMonth, endOfMonth)
        .findAll();
    final monthlySales = monthlyInvoices.fold(0.0, (sum, inv) => sum + (inv.grandTotal ?? 0.0));

    // Monthly Purchases
    final monthlyPurchasesInvoices = await isar.collection<Purchase>()
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .purchaseDateBetween(startOfMonth, endOfMonth)
        .findAll();
    final monthlyPurchases = monthlyPurchasesInvoices.fold(0.0, (sum, p) => sum + (p.grandTotal ?? 0.0));

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
      final bal = p.outstandingBalance ?? 0.0;
      if (p.partyType == 'Supplier') {
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
    final recentInvoices = await isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .invoiceStatusEqualTo('Active')
        .and()
        .invoiceDateBetween(date30DaysAgo, now)
        .findAll();

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
      final invoiceItems = await isar.invoiceItems
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

      final dayInvoices = await isar.invoices
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .invoiceStatusEqualTo('Active')
          .and()
          .invoiceDateBetween(dateStart, dateEnd)
          .findAll();

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
