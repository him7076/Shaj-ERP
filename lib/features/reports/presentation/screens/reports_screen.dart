import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/features/reports/presentation/screens/sales_report_screen.dart';
import 'package:business_sahaj_erp/features/reports/presentation/screens/gst_report_screen.dart';
import 'package:business_sahaj_erp/features/reports/presentation/screens/stock_report_screen.dart';
import 'package:business_sahaj_erp/features/reports/presentation/screens/outstanding_report_screen.dart';
import 'package:business_sahaj_erp/features/reports/presentation/screens/party_ledger_screen.dart';
import 'package:business_sahaj_erp/features/reports/presentation/screens/salesman_report_screen.dart';
import 'package:business_sahaj_erp/features/reports/presentation/screens/batch_report_screen.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/screens/purchases_screen.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Business Intelligence', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh Analytics',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardAnalyticsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) {
          final chartService = ref.read(chartServiceProvider);
          final spots = chartService.mapToLineSpots(analytics.dailySalesPoints);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Cards Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: [
                    _buildKpiCard(
                      title: "Today's Sales",
                      value: currencyFormat.format(analytics.todaySales),
                      icon: Icons.today_rounded,
                      color: const Color(0xFF0EA5E9),
                    ),
                    _buildKpiCard(
                      title: "Monthly Sales",
                      value: currencyFormat.format(analytics.monthlySales),
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    _buildKpiCard(
                      title: "Pending Orders",
                      value: '${analytics.pendingOrdersCount} Orders',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    _buildKpiCard(
                      title: "Total Outstanding",
                      value: currencyFormat.format(analytics.totalOutstanding),
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFFF43F5E),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Charts Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line Chart for 30-Day Sales
                    Expanded(
                      flex: 2,
                      child: AnimatedHoverCard(
                        glowColor: theme.colorScheme.primary,
                        enableScale: false,
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Revenue Trend (Last 30 Days)',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Daily Overview',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 250,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: 5,
                                        getTitlesWidget: (val, meta) => Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'Day ${val.toInt()}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 42,
                                        getTitlesWidget: (val, meta) => Text(
                                          '₹${(val / 1000).toStringAsFixed(0)}k',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                                      isCurved: true,
                                      color: theme.colorScheme.primary,
                                      barWidth: 3.5,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: theme.colorScheme.primary.withOpacity(0.12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Reports Navigation Section Header
                Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Executive Detailed Reports',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.2,
                  children: [
                    _buildReportMenuCard(
                      title: 'Sales Register',
                      description: 'Track invoices, discounts & tax splits',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF0EA5E9),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'GST Tax Filings',
                      description: 'CGST / SGST / IGST quarterly summaries',
                      icon: Icons.gavel_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GstReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Stock Ledger',
                      description: 'Reorder levels, values & tracking logs',
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StockReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Party Outstanding',
                      description: 'Unpaid bills, credit terms & limits status',
                      icon: Icons.badge_rounded,
                      color: const Color(0xFFF43F5E),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OutstandingReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Customer Ledger',
                      description: 'Account balance debit/credit statements',
                      icon: Icons.account_balance_rounded,
                      color: const Color(0xFF14B8A6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PartyLedgerScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Purchases Register',
                      description: 'Inward goods bills and vendor invoices',
                      icon: Icons.shopping_bag_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PurchasesScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Expenses Log',
                      description: 'Operational outflows, salaries & overheads',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFFF97316),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpensesScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Salesman Performance',
                      description: 'Salesperson wise revenue, orders & invoices',
                      icon: Icons.badge_outlined,
                      color: const Color(0xFFD946EF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesmanReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Batch & Expiry Tracking',
                      description: 'Batch numbers, mfg & expiry date tracking logs',
                      icon: Icons.qr_code_2_rounded,
                      color: const Color(0xFFA855F7),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BatchReportScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stackTrace) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text('Failed to compile business reports: $err', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Text(
                    stackTrace.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return AnimatedHoverCard(
      glowColor: color,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportMenuCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return AnimatedHoverCard(
      glowColor: color,
      onTap: onTap,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.7)),
        ],
      ),
    );
  }
}
