import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';

abstract class ReportRepository {
  Future<SalesReportSummary> getSalesReport({
    required DateTime start,
    required DateTime end,
    String? partyUuid,
    String? paymentStatus,
    int offset = 0,
    int limit = 100,
  });

  Future<List<Order>> getOrderReport({
    required DateTime start,
    required DateTime end,
    String? status,
    String? partyUuid,
  });

  Future<GSTReportSummary> getGSTReport({
    required DateTime start,
    required DateTime end,
  });

  Future<OutstandingReportSummary> getOutstandingReport();

  Future<PartyLedgerSummary> getPartyLedger(String partyUuid, DateTime start, DateTime end);

  Future<StockReportSummary> getStockReport({String? status});

  Future<List<StockMovementEntry>> getStockMovementReport(String itemUuid);

  Future<SalesmanPerformanceSummary> getSalesmanPerformance(DateTime start, DateTime end);

  Future<ProfitSummary> getProfitReport(DateTime start, DateTime end);
}
