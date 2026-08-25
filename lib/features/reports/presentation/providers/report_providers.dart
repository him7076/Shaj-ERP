import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/domain/models/report_models.dart';
import 'package:business_sahaj_erp/domain/repositories/report_repository.dart';
import 'package:business_sahaj_erp/domain/repositories/analytics_repository.dart';
import 'package:business_sahaj_erp/data/repositories/report_repository_impl.dart';
import 'package:business_sahaj_erp/data/repositories/analytics_repository_impl.dart';
import 'package:business_sahaj_erp/core/services/report_service.dart';
import 'package:business_sahaj_erp/core/services/profit_service.dart';
import 'package:business_sahaj_erp/core/services/export_service.dart';
import 'package:business_sahaj_erp/core/services/chart_service.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';

// --- Services Providers ---

final profitServiceProvider = Provider<ProfitService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ProfitService(dbService);
});

final reportServiceProvider = Provider<ReportService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ReportService(dbService);
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final chartServiceProvider = Provider<ChartService>((ref) {
  return ChartService();
});

// --- Repositories Providers ---

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final reportService = ref.watch(reportServiceProvider);
  final profitService = ref.watch(profitServiceProvider);
  return ReportRepositoryImpl(reportService, profitService);
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return AnalyticsRepositoryImpl(dbService);
});

enum DashboardPeriodPreset {
  today,
  weekly,
  monthly,
  yearly,
  custom,
}

class DashboardDateFilter {
  final DashboardPeriodPreset preset;
  final DateTime startDate;
  final DateTime endDate;

  DashboardDateFilter({
    required this.preset,
    required this.startDate,
    required this.endDate,
  });

  factory DashboardDateFilter.fromPreset(DashboardPeriodPreset preset, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, 1);
    DateTime end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    switch (preset) {
      case DashboardPeriodPreset.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DashboardPeriodPreset.weekly:
        final daysToSubtract = now.weekday - 1;
        start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DashboardPeriodPreset.monthly:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DashboardPeriodPreset.yearly:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case DashboardPeriodPreset.custom:
        start = customStart ?? start;
        end = customEnd ?? end;
        break;
    }

    return DashboardDateFilter(
      preset: preset,
      startDate: start,
      endDate: end,
    );
  }

  String get label {
    switch (preset) {
      case DashboardPeriodPreset.today:
        return 'Today';
      case DashboardPeriodPreset.weekly:
        return 'This Week';
      case DashboardPeriodPreset.monthly:
        return 'This Month';
      case DashboardPeriodPreset.yearly:
        return 'This Year';
      case DashboardPeriodPreset.custom:
        return 'Custom Range';
    }
  }
}

final dashboardDateFilterProvider = StateProvider<DashboardDateFilter>((ref) {
  return DashboardDateFilter.fromPreset(DashboardPeriodPreset.monthly);
});

// 1. Dashboard Analytics Summary (cached — no autoDispose; invalidated explicitly after sync/writes)
final dashboardAnalyticsProvider = FutureProvider<DashboardAnalyticsSummary>((ref) async {
  final dateFilter = ref.watch(dashboardDateFilterProvider);
  final repository = ref.watch(analyticsRepositoryProvider);
  return await repository.getDashboardAnalytics(
    startDate: dateFilter.startDate,
    endDate: dateFilter.endDate,
  );
});

// 2. Sales Report Summary
final salesReportProvider = FutureProvider.family.autoDispose<
    SalesReportSummary,
    ({DateTime start, DateTime end, String? partyUuid, String? paymentStatus, int offset, int limit})>((ref, args) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getSalesReport(
    start: args.start,
    end: args.end,
    partyUuid: args.partyUuid,
    paymentStatus: args.paymentStatus,
    offset: args.offset,
    limit: args.limit,
  );
});

// 3. Order List Report
final orderReportProvider = FutureProvider.family.autoDispose<
    List<Order>,
    ({DateTime start, DateTime end, String? status, String? partyUuid})>((ref, args) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getOrderReport(
    start: args.start,
    end: args.end,
    status: args.status,
    partyUuid: args.partyUuid,
  );
});

// 4. GST Summary
final gstReportProvider = FutureProvider.family.autoDispose<
    GSTReportSummary,
    ({DateTime start, DateTime end})>((ref, args) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getGSTReport(start: args.start, end: args.end);
});

// 5. Customer Outstanding Summary
final outstandingReportProvider = FutureProvider.autoDispose<OutstandingReportSummary>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getOutstandingReport();
});

// 6. Party Ledger Statement
final partyLedgerProvider = FutureProvider.family.autoDispose<
    PartyLedgerSummary,
    ({String partyUuid, DateTime start, DateTime end})>((ref, args) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getPartyLedger(args.partyUuid, args.start, args.end);
});

// 7. Stock Summary List
final stockReportProvider = FutureProvider.family.autoDispose<
    StockReportSummary,
    String?>((ref, status) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getStockReport(status: status);
});

// 8. Stock Movement History
final stockMovementProvider = FutureProvider.family.autoDispose<
    List<StockMovementEntry>,
    String>((ref, itemUuid) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getStockMovementReport(itemUuid);
});

// 9. Salesman Performance Summary
final salesmanPerformanceProvider = FutureProvider.family.autoDispose<
    SalesmanPerformanceSummary,
    ({DateTime start, DateTime end})>((ref, args) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getSalesmanPerformance(args.start, args.end);
});

// 10. Net Profit Margin Summary
final profitReportProvider = FutureProvider.family.autoDispose<
    ProfitSummary,
    ({DateTime start, DateTime end})>((ref, args) async {
  final repository = ref.watch(reportRepositoryProvider);
  return await repository.getProfitReport(args.start, args.end);
});
