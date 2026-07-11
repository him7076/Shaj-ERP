import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/domain/repositories/report_repository.dart';
import 'package:business_sahaj_erp/core/services/report_service.dart';
import 'package:business_sahaj_erp/core/services/profit_service.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportService _reportService;
  final ProfitService _profitService;

  ReportRepositoryImpl(this._reportService, this._profitService);

  @override
  Future<SalesReportSummary> getSalesReport({
    required DateTime start,
    required DateTime end,
    String? partyUuid,
    String? paymentStatus,
    int offset = 0,
    int limit = 100,
  }) {
    return _reportService.getSalesReport(
      start: start,
      end: end,
      partyUuid: partyUuid,
      paymentStatus: paymentStatus,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<List<Order>> getOrderReport({
    required DateTime start,
    required DateTime end,
    String? status,
    String? partyUuid,
  }) {
    return _reportService.getOrderReport(
      start: start,
      end: end,
      status: status,
      partyUuid: partyUuid,
    );
  }

  @override
  Future<GSTReportSummary> getGSTReport({
    required DateTime start,
    required DateTime end,
  }) {
    return _reportService.getGSTReport(start: start, end: end);
  }

  @override
  Future<OutstandingReportSummary> getOutstandingReport() {
    return _reportService.getOutstandingReport();
  }

  @override
  Future<PartyLedgerSummary> getPartyLedger(String partyUuid, DateTime start, DateTime end) {
    return _reportService.getPartyLedger(partyUuid, start, end);
  }

  @override
  Future<StockReportSummary> getStockReport({String? status}) {
    return _reportService.getStockReport(status: status);
  }

  @override
  Future<List<StockMovementEntry>> getStockMovementReport(String itemUuid) {
    return _reportService.getStockMovementReport(itemUuid);
  }

  @override
  Future<SalesmanPerformanceSummary> getSalesmanPerformance(DateTime start, DateTime end) {
    return _reportService.getSalesmanPerformance(start, end);
  }

  @override
  Future<ProfitSummary> getProfitReport(DateTime start, DateTime end) {
    return _profitService.calculateProfitReport(start, end);
  }
}
