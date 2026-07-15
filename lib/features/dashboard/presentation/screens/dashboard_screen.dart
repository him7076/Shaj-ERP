import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine responsive column counts
    int crossAxisCount = 1;
    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 4;
    } else if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Visual with glassmorphism layout style
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.06),
                    theme.colorScheme.primary.withOpacity(0.01),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, Administrator',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onBackground,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sahaj ERP is live. Here is your enterprise summary for today.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!ResponsiveLayout.isMobile(context))
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary, size: 16),
                            const SizedBox(width: 10),
                            Text(
                              'July 15, 2026',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
                  value: '₹3,84,900',
                  trend: '+8.3% vs last week',
                  trendColor: Colors.green,
                  icon: Icons.monetization_on_rounded,
                  iconColor: Colors.green,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Purchases (Bills)',
                  value: '₹68,440',
                  trend: '1 bill recorded',
                  trendColor: Colors.blue,
                  icon: Icons.shopping_bag_rounded,
                  iconColor: Colors.blue,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Active Customers',
                  value: '184 Parties',
                  trend: '+3 registered today',
                  trendColor: Colors.orange,
                  icon: Icons.people_alt_rounded,
                  iconColor: Colors.purple,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Stock Ledger',
                  value: '456 Items',
                  trend: '5 Out of Stock',
                  trendColor: Colors.red,
                  icon: Icons.inventory_2_rounded,
                  iconColor: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Split Section: Recent Activity & Quick Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Activity Panel
                Expanded(
                  flex: 3,
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
                ),
                
                // Quick Actions Menu
                if (ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context)) ...[
                  const SizedBox(width: 20),
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
                              'Quick Actions Shortcuts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                            const Divider(height: 32, thickness: 0.5),
                            
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.create_new_folder_outlined,
                              label: 'Create Sales Invoice',
                              color: Colors.green,
                              routePath: '/sales',
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.add_shopping_cart_rounded,
                              label: 'Log Purchase Bill',
                              color: Colors.blue,
                              routePath: '/purchases',
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Record Expense',
                              color: Colors.red,
                              routePath: '/expenses',
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Add New Party Profile',
                              color: Colors.purple,
                              routePath: '/parties',
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.print_outlined,
                              label: 'Generate Business Report',
                              color: Colors.teal,
                              routePath: '/reports',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String routePath,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.go(routePath),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground.withOpacity(0.9),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6), size: 16),
          ],
        ),
      ),
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
