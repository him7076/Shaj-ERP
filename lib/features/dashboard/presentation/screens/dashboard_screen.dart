import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:business_sahaj_erp/core/widgets/animated_hover_card.dart';
import 'package:business_sahaj_erp/core/widgets/liquid_glass_card.dart';
import 'package:business_sahaj_erp/core/theme/app_decorations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFilter = ref.watch(dashboardDateFilterProvider);
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    int crossAxisCount = 1;
    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 4;
    } else if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: analyticsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stackTrace) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
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
            padding: EdgeInsets.all(ResponsiveLayout.isMobile(context) ? 14.0 : 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Executive Hero Banner Greeting Header
                _buildHeroHeader(context),
                SizedBox(height: ResponsiveLayout.isMobile(context) ? 16 : 28),

                // Quick Actions Header & Grid (Desktop & Tablet only, mobile uses Central FAB sheet)
                if (!ResponsiveLayout.isMobile(context)) ...[
                  _buildQuickActionsHeader(context),
                  const SizedBox(height: 12),
                  _buildQuickActionsGrid(context),
                  const SizedBox(height: 28),
                ],

                // Section Header for KPIs & Period Filter Dropdown
                Flex(
                  direction: ResponsiveLayout.isMobile(context) ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Key Business Analytics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (ResponsiveLayout.isMobile(context)) const SizedBox(height: 10),
                    // Period Filter Selection Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<DashboardPeriodPreset>(
                              value: dateFilter.preset,
                              isDense: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: DashboardPeriodPreset.today,
                                  child: Text('Today'),
                                ),
                                DropdownMenuItem(
                                  value: DashboardPeriodPreset.weekly,
                                  child: Text('Weekly (This Week)'),
                                ),
                                DropdownMenuItem(
                                  value: DashboardPeriodPreset.monthly,
                                  child: Text('Monthly (This Month)'),
                                ),
                                DropdownMenuItem(
                                  value: DashboardPeriodPreset.yearly,
                                  child: Text('Yearly (This Year)'),
                                ),
                                DropdownMenuItem(
                                  value: DashboardPeriodPreset.custom,
                                  child: Text('Custom Date Range...'),
                                ),
                              ],
                              onChanged: (preset) async {
                                if (preset == null) return;
                                if (preset == DashboardPeriodPreset.custom) {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    initialDateRange: DateTimeRange(
                                      start: dateFilter.startDate,
                                      end: dateFilter.endDate,
                                    ),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    ref.read(dashboardDateFilterProvider.notifier).state =
                                        DashboardDateFilter.fromPreset(
                                      DashboardPeriodPreset.custom,
                                      customStart: picked.start,
                                      customEnd: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
                                    );
                                  }
                                } else {
                                  ref.read(dashboardDateFilterProvider.notifier).state =
                                      DashboardDateFilter.fromPreset(preset);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Responsive Stats Grid with AnimatedHoverCard
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: ResponsiveLayout.isMobile(context) ? 2 : crossAxisCount,
                  crossAxisSpacing: ResponsiveLayout.isMobile(context) ? 8 : 18,
                  mainAxisSpacing: ResponsiveLayout.isMobile(context) ? 8 : 18,
                  childAspectRatio: ResponsiveLayout.isMobile(context) ? 2.8 : 1.6,
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'Sales Invoices',
                      value: currencyFormat.format(analytics.monthlySales),
                      trend: '${dateFilter.label} Total',
                      trendColor: const Color(0xFF10B981),
                      icon: Icons.point_of_sale_rounded,
                      iconColor: const Color(0xFF10B981),
                      onTap: () => context.go('/sales'),
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Purchase Bills',
                      value: currencyFormat.format(analytics.monthlyPurchases),
                      trend: '${dateFilter.label} Total',
                      trendColor: const Color(0xFF6366F1),
                      icon: Icons.shopping_bag_rounded,
                      iconColor: const Color(0xFF6366F1),
                      onTap: () => context.go('/purchases'),
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Total Receivables',
                      value: currencyFormat.format(analytics.totalOutstanding),
                      trend: 'Pending Customer Dues',
                      trendColor: const Color(0xFFF59E0B),
                      icon: Icons.arrow_circle_down_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () => context.go('/reports/receivables'),
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Total Payables',
                      value: currencyFormat.format(analytics.totalPayable),
                      trend: 'Supplier Dues Payable',
                      trendColor: const Color(0xFFF43F5E),
                      icon: Icons.arrow_circle_up_rounded,
                      iconColor: const Color(0xFFF43F5E),
                      onTap: () => context.go('/reports/payables'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Real Recent Activity Timeline Card
                Consumer(
                  builder: (context, ref, _) {
                    final txsAsync = ref.watch(filteredTransactionsProvider);
                    return AnimatedHoverCard(
                      glowColor: theme.colorScheme.primary,
                      enableScale: false,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.history_rounded, color: theme.colorScheme.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Recent Transactions Timeline',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () => context.go('/transactions'),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                label: const Text('View All'),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          txsAsync.when(
                            data: (list) {
                              if (list.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.history_toggle_off_rounded, size: 44, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                                        const SizedBox(height: 8),
                                        Text('No recent transactions logged yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                                        const SizedBox(height: 4),
                                        Text('Transactions created will appear here ordered by entry timestamp', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final recentList = list.take(5).toList();
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentList.length,
                                separatorBuilder: (ctx, i) => const Divider(height: 12, thickness: 0.2),
                                itemBuilder: (ctx, idx) {
                                  final tx = recentList[idx];
                                  final createdTime = tx.createdAt ?? tx.transactionDate ?? DateTime.now();
                                  final diff = DateTime.now().difference(createdTime);
                                  String timeStr = 'Just now';
                                  if (diff.inMinutes >= 60) {
                                    timeStr = '${diff.inHours}h ago';
                                  } else if (diff.inMinutes > 0) {
                                    timeStr = '${diff.inMinutes}m ago';
                                  }

                                  Color iconCol = const Color(0xFF0EA5E9);
                                  IconData iconData = Icons.receipt_long_rounded;
                                  if (tx.transactionType == 'Purchase') {
                                    iconCol = const Color(0xFF10B981);
                                    iconData = Icons.shopping_bag_rounded;
                                  } else if (tx.transactionType == 'Receipt' || tx.transactionType == 'Payment In') {
                                    iconCol = const Color(0xFF16A34A);
                                    iconData = Icons.arrow_circle_down_rounded;
                                  } else if (tx.transactionType == 'Payment' || tx.transactionType == 'Expense') {
                                    iconCol = const Color(0xFFDC2626);
                                    iconData = Icons.arrow_circle_up_rounded;
                                  }

                                  return _buildActivityItem(
                                    theme: theme,
                                    title: '${tx.transactionType} ${tx.transactionNumber ?? ""} • ${tx.partyName ?? "Walk-in Party"}',
                                    time: timeStr,
                                    subtitle: 'Amount: ₹${tx.amount.toStringAsFixed(2)} • Mode: ${tx.paymentMode ?? "Cash"}',
                                    statusIcon: iconData,
                                    statusColor: iconCol,
                                    isLast: idx == recentList.length - 1,
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                            error: (e, _) => Text('Error loading activity: $e', style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final todayDateStr = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now());
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      decoration: BoxDecoration(
        gradient: AppDecorations.primaryIndigoGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_graph_rounded,
              size: isMobile ? 100 : 160,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          todayDateStr,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Live Metrics',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 16),
              Text(
                'Good Morning, Executive! ✨',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(height: 6),
                Text(
                  'Here is your business financial overview and quick record actions for today.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Quick Create Shortcuts',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final theme = Theme.of(context);
    
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Sales Order',
        'subtitle': 'Book customer order',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF0EA5E9),
        'path': '/orders?create=true',
      },
      {
        'title': 'Sales Invoice',
        'subtitle': 'Create sales entry',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFF10B981),
        'path': '/sales?create=true',
      },
      {
        'title': 'Purchase Bill',
        'subtitle': 'Record supplier bill',
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFF6366F1),
        'path': '/purchases?create=true',
      },
      {
        'title': 'Record Expense',
        'subtitle': 'Log business expense',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFFF43F5E),
        'path': '/expenses?create=true',
      },
      {
        'title': 'Payment Out',
        'subtitle': 'Paid to supplier',
        'icon': Icons.arrow_circle_up_rounded,
        'color': const Color(0xFFF97316),
        'path': '/payments?create=true',
      },
      {
        'title': 'Receipt In',
        'subtitle': 'Received from party',
        'icon': Icons.arrow_circle_down_rounded,
        'color': const Color(0xFF14B8A6),
        'path': '/receipts?create=true',
      },
      {
        'title': 'Credit Note',
        'subtitle': 'Sales returns',
        'icon': Icons.assignment_returned_rounded,
        'color': const Color(0xFF8B5CF6),
        'path': '/credit-notes?create=true',
      },
      {
        'title': 'Debit Note',
        'subtitle': 'Purchase returns',
        'icon': Icons.assignment_return_rounded,
        'color': const Color(0xFFEC4899),
        'path': '/debit-notes?create=true',
      },
      {
        'title': 'Party Transfer',
        'subtitle': 'Transfer balance',
        'icon': Icons.swap_horiz_rounded,
        'color': const Color(0xFF06B6D4),
        'path': '/party-transfers?create=true',
      },
      {
        'title': 'Other Income',
        'subtitle': 'Non-sales revenue',
        'icon': Icons.monetization_on_rounded,
        'color': const Color(0xFFF59E0B),
        'path': '/other-incomes?create=true',
      },
    ];

    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (ctx, idx) {
          final act = actions[idx];
          final Color col = act['color'] as Color;
          return InkWell(
            onTap: () => context.go(act['path'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: col.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(act['icon'] as IconData, color: col, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  act['title'] as String,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      );
    }

    int gridColumns = ResponsiveLayout.isDesktop(context) ? 5 : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (ctx, idx) {
        final act = actions[idx];
        final Color col = act['color'] as Color;
        return AnimatedHoverCard(
          glowColor: col,
          onTap: () => context.go(act['path'] as String),
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: col.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(act['icon'] as IconData, color: col, size: 20),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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
                color: col.withOpacity(0.7),
                size: 16,
              ),
            ],
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
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    final cardChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 10 : 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isMobile ? 16 : 20,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: isMobile ? 13.5 : 20,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isMobile) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, size: 12, color: trendColor),
                          const SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(color: trendColor, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trend,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      );

    if (isMobile) {
      return LiquidGlassCard(
        onTap: onTap,
        accentGlowColor: iconColor,
        padding: const EdgeInsets.all(12.0),
        child: cardChild,
      );
    }

    return AnimatedHoverCard(
      glowColor: iconColor,
      onTap: onTap,
      padding: const EdgeInsets.all(20.0),
      child: cardChild,
    );
  }

  Widget _buildActivityItem({
    required ThemeData theme,
    required String title,
    required String time,
    required String subtitle,
    required IconData statusIcon,
    required Color statusColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
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
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
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

