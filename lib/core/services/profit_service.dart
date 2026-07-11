import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';

class ProfitService {
  final DatabaseService _dbService;

  ProfitService(this._dbService);

  /// Calculates profitability metrics for invoice transactions in date range.
  Future<ProfitSummary> calculateProfitReport(DateTime start, DateTime end) async {
    final isar = _dbService.isar;

    // Fetch active invoices within date bounds
    final invoices = await isar.invoices
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .invoiceStatusEqualTo('Active')
        .and()
        .invoiceDateBetween(start, end)
        .findAll();

    double totalRevenue = 0.0;
    double totalCost = 0.0;

    // Map to aggregate metrics per product
    final Map<String, _ProductProfitAggregate> productAggregates = {};

    for (var invoice in invoices) {
      // Fetch associated invoice items
      final invoiceItems = await isar.invoiceItems
          .filter()
          .invoice((q) => q.idEqualTo(invoice.id))
          .and()
          .isDeletedEqualTo(false)
          .findAll();

      for (var invoiceItem in invoiceItems) {
        final itemName = invoiceItem.itemName ?? 'Unknown Product';
        final qty = (invoiceItem.quantity ?? 0.0) + (invoiceItem.freeQuantity ?? 0.0);
        
        final revenue = invoiceItem.taxableAmount ?? 0.0; // Profit is evaluated against Taxable value (excluding GST)

        // Fetch buyRate of item. Fallback to 0.0 if not configured.
        double buyRate = 0.0;
        if (invoiceItem.item.value != null) {
          buyRate = invoiceItem.item.value!.buyRate ?? 0.0;
        } else if (invoiceItem.itemId != null) {
          final originalItem = await isar.items.get(invoiceItem.itemId!);
          if (originalItem != null) {
            buyRate = originalItem.buyRate ?? 0.0;
          }
        }

        final cost = buyRate * qty;
        final profit = revenue - cost;

        totalRevenue += revenue;
        totalCost += cost;

        if (productAggregates.containsKey(itemName)) {
          productAggregates[itemName]!.add(qty, revenue, cost);
        } else {
          productAggregates[itemName] = _ProductProfitAggregate(
            itemName: itemName,
            qtySold: qty,
            revenue: revenue,
            cost: cost,
          );
        }
      }
    }

    final grossProfit = totalRevenue; // Before buying costs
    final netProfit = totalRevenue - totalCost; // Net sales margin
    final profitPercentage = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

    final profitLines = productAggregates.values.map((agg) {
      final marginPercent = agg.revenue > 0 ? ((agg.revenue - agg.cost) / agg.revenue) * 100 : 0.0;
      return ProfitLineItem(
        itemName: agg.itemName,
        qtySold: agg.qtySold,
        revenue: agg.revenue,
        cost: agg.cost,
        profit: agg.revenue - agg.cost,
        marginPercent: marginPercent,
      );
    }).toList();

    // Sort by profit descending
    profitLines.sort((a, b) => b.profit.compareTo(a.profit));

    return ProfitSummary(
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit: grossProfit,
      netProfit: netProfit,
      profitPercentage: profitPercentage,
      lines: profitLines,
    );
  }
}

class _ProductProfitAggregate {
  final String itemName;
  double qtySold;
  double revenue;
  double cost;

  _ProductProfitAggregate({
    required this.itemName,
    required this.qtySold,
    required this.revenue,
    required this.cost,
  });

  void add(double qty, double rev, double cst) {
    qtySold += qty;
    revenue += rev;
    cost += cst;
  }
}
