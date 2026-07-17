import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Determine responsive column counts
    int crossAxisCount = 1;
    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 4;
    } else if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    final todayDateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stackTrace) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load dashboard metrics: $err', style: const TextStyle(fontWeight: FontWeight.bold)),
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
        data: (analytics) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions Dashboard Header & Grid
                _buildQuickActionsHeader(context),
                const SizedBox(height: 20),
                _buildQuickActionsGrid(context),
                const SizedBox(height: 28),

                // Responsive Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'Sales (Invoices)',
                      value: currencyFormat.format(analytics.monthlySales),
                      trend: 'This Month\'s total sales',
                      trendColor: Colors.green,
                      icon: Icons.monetization_on_rounded,
                      iconColor: Colors.green,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Purchases (Bills)',
                      value: currencyFormat.format(analytics.monthlyPurchases),
                      trend: 'This Month\'s total purchases',
                      trendColor: Colors.blue,
                      icon: Icons.shopping_bag_rounded,
                      iconColor: Colors.blue,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Total Receivables',
                      value: currencyFormat.format(analytics.totalOutstanding),
                      trend: 'Pending customer collections',
                      trendColor: Colors.orange,
                      icon: Icons.assignment_returned_rounded,
                      iconColor: Colors.purple,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Total Payables',
                      value: currencyFormat.format(analytics.totalPayable),
                      trend: 'Dues payable to suppliers',
                      trendColor: Colors.red,
                      icon: Icons.assignment_return_rounded,
                      iconColor: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Recent Activity Panel taking full width
                Card(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Transactions Log',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                            Icon(Icons.history_rounded, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                          ],
                        ),
                        const Divider(height: 32, thickness: 0.5),
                        
                        _buildActivityItem(
                          theme: theme,
                          title: 'Invoice generated for Krishna Electronics',
                          time: '10 mins ago',
                          subtitle: 'Invoice #INV-2026-084 • Amount: ₹14,200',
                          statusIcon: Icons.receipt_long,
                          statusColor: Colors.blue,
                        ),
                        _buildActivityItem(
                          theme: theme,
                          title: 'Payment received from Shiva Traders',
                          time: '1 hour ago',
                          subtitle: 'Ref #TXN-90234 • Amount: ₹45,000',
                          statusIcon: Icons.check_circle_outline,
                          statusColor: Colors.green,
                        ),
                        _buildActivityItem(
                          theme: theme,
                          title: 'Wholesale Purchase draft saved',
                          time: '3 hours ago',
                          subtitle: 'Bill #PUR-2026-0001 • Balaji Wholesalers',
                          statusIcon: Icons.shopping_bag_outlined,
                          statusColor: Colors.orange,
                        ),
                        _buildActivityItem(
                          theme: theme,
                          title: 'Office rent payment logged',
                          time: '5 hours ago',
                          subtitle: 'Expense Category: Rent • Amount: ₹12,000',
                          statusIcon: Icons.account_balance_wallet_outlined,
                          statusColor: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsHeader(BuildContext context) {
    final theme = Theme.of(context);
    final todayDateStr = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
    final isMobile = ResponsiveLayout.isMobile(context);

    final content = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Create Shortcuts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Record a transaction directly into Shaj ERP',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
      if (isMobile) const SizedBox(height: 12),
      Card(
        elevation: 0,
        color: theme.colorScheme.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 14),
              const SizedBox(width: 8),
              Text(
                todayDateStr,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: content,
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final theme = Theme.of(context);
    
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Sales Order',
        'subtitle': 'Book customer order',
        'icon': Icons.description_outlined,
        'color': Colors.indigo,
        'path': '/orders?create=true',
      },
      {
        'title': 'Sales Invoice',
        'subtitle': 'Create sales entry',
        'icon': Icons.receipt_long_outlined,
        'color': Colors.green,
        'path': '/sales?create=true',
      },
      {
        'title': 'Purchase Bill',
        'subtitle': 'Record supplier bill',
        'icon': Icons.shopping_bag_outlined,
        'color': Colors.blue,
        'path': '/purchases?create=true',
      },
      {
        'title': 'Record Expense',
        'subtitle': 'Log business expense',
        'icon': Icons.account_balance_wallet_outlined,
        'color': Colors.red,
        'path': '/expenses?create=true',
      },
      {
        'title': 'Payment Out',
        'subtitle': 'Paid to supplier/party',
        'icon': Icons.arrow_circle_up_outlined,
        'color': Colors.orange,
        'path': '/payments?create=true',
      },
      {
        'title': 'Receipt In',
        'subtitle': 'Received from customer',
        'icon': Icons.arrow_circle_down_outlined,
        'color': Colors.teal,
        'path': '/receipts?create=true',
      },
      {
        'title': 'Credit Note',
        'subtitle': 'Sales returns / refund',
        'icon': Icons.assignment_returned_outlined,
        'color': Colors.purple,
        'path': '/credit-notes?create=true',
      },
      {
        'title': 'Debit Note',
        'subtitle': 'Purchase returns / debit',
        'icon': Icons.assignment_return_outlined,
        'color': Colors.pink,
        'path': '/debit-notes?create=true',
      },
      {
        'title': 'Party Transfer',
        'subtitle': 'Transfer balance',
        'icon': Icons.swap_horiz_outlined,
        'color': Colors.teal,
        'path': '/party-transfers?create=true',
      },
      {
        'title': 'Other Income',
        'subtitle': 'Non-sales revenue',
        'icon': Icons.monetization_on_outlined,
        'color': Colors.amber,
        'path': '/other-incomes?create=true',
      },
    ];

    int gridColumns = 1;
    if (ResponsiveLayout.isDesktop(context)) {
      gridColumns = 5;
    } else if (ResponsiveLayout.isTablet(context)) {
      gridColumns = 3;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: ResponsiveLayout.isMobile(context) ? 3.0 : 2.2,
      ),
      itemBuilder: (ctx, idx) {
        final act = actions[idx];
        final Color col = act['color'] as Color;
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
          ),
          child: InkWell(
            onTap: () => context.go(act['path'] as String),
            borderRadius: BorderRadius.circular(16),
            hoverColor: col.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: col.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(act['icon'] as IconData, color: col, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          act['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          act['subtitle'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: col.withOpacity(0.6),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              iconColor.withOpacity(0.01),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onBackground,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      trendColor == Colors.red ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: trendColor,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required ThemeData theme,
    required String title,
    required String time,
    required String subtitle,
    required IconData statusIcon,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
