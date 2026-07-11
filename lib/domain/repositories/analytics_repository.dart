import 'package:business_sahaj_erp/domain/models/report_models.dart';

abstract class AnalyticsRepository {
  Future<DashboardAnalyticsSummary> getDashboardAnalytics();
}
