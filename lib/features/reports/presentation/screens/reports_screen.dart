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
import 'package:business_sahaj_erp/features/purchases/presentation/screens/purchases_screen.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/screens/expenses_screen.dart';

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
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Business Intelligence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardAnalyticsProvider),
          ),
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
                      color: Colors.blue[700]!,
                    ),
                    _buildKpiCard(
                      title: "Monthly Sales",
                      value: currencyFormat.format(analytics.monthlySales),
                      icon: Icons.calendar_month_rounded,
                      color: Colors.green[700]!,
                    ),
                    _buildKpiCard(
                      title: "Pending Orders",
                      value: '${analytics.pendingOrdersCount} Orders',
                      icon: Icons.pending_actions_rounded,
                      color: Colors.orange[700]!,
                    ),
                    _buildKpiCard(
                      title: "Total Outstanding",
                      value: currencyFormat.format(analytics.totalOutstanding),
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.red[700]!,
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
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '30-Day Sales Trend',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 220,
                                child: spots.isEmpty
                                    ? const Center(child: Text('Insufficient historical sales data.'))
                                    : LineChart(
                                        LineChartData(
                                          gridData: const FlGridData(show: false),
                                          titlesData: const FlTitlesData(
                                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: spots,
                                              isCurved: true,
                                              color: theme.colorScheme.primary,
                                              barWidth: 3,
                                              isStrokeCapRound: true,
                                              dotData: const FlDotData(show: false),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: theme.colorScheme.primary.withOpacity(0.1),
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
                    ),
                    if (MediaQuery.of(context).size.width > 900) ...[
                      const SizedBox(width: 24),
                      // Doughnut Chart of Top Customers
                      Expanded(
                        flex: 1,
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Top Customer Share',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 220,
                                  child: analytics.topCustomers.isEmpty
                                      ? const Center(child: Text('No customer logs found.'))
                                      : PieChart(
                                          PieChartData(
                                            sections: chartService.mapToPieSections(analytics.topCustomers),
                                            centerSpaceRadius: 40,
                                            sectionsSpace: 2,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),

                // Reports Menu Grid
                Text(
                  'Detailed Reports',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'GST Tax Filings',
                      description: 'CGST / SGST / IGST quarterly summaries',
                      icon: Icons.gavel_rounded,
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GstReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Stock Ledger',
                      description: 'Reorder levels, values & tracking logs',
                      icon: Icons.inventory_2_rounded,
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StockReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Party Outstanding',
                      description: 'Unpaid bills, credit terms & limits status',
                      icon: Icons.badge_rounded,
                      color: Colors.red,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OutstandingReportScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Customer Ledger',
                      description: 'Account balance debit/credit statements',
                      icon: Icons.account_balance_rounded,
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        // Navigates to a helper selector or opens ledger screen
                        MaterialPageRoute(builder: (context) => const PartyLedgerScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Purchases Register',
                      description: 'Inward goods bills and vendor invoices',
                      icon: Icons.shopping_bag_rounded,
                      color: Colors.blueGrey,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PurchasesScreen()),
                      ),
                    ),
                    _buildReportMenuCard(
                      title: 'Expenses Log',
                      description: 'Operational outflows, salaries & overheads',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.redAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpensesScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to compile business reports: $err'),
            ],
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
    return Card(
      elevation: 0,
      color: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.15)),
      ),
      child: Padding(
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
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
