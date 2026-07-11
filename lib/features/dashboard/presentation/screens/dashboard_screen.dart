import 'package:flutter/material.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Sahaj ERP',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your business overview for today.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // Calendar Date Indicator (Responsive display)
                if (!ResponsiveLayout.isMobile(context))
                  Card(
                    color: theme.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: theme.colorScheme.onSecondaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            'June 23, 2026',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Responsive Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  context: context,
                  title: 'Total Orders',
                  value: '1,248',
                  trend: '+12.5% vs last week',
                  trendColor: Colors.green,
                  icon: Icons.shopping_basket_rounded,
                  iconColor: Colors.blue,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Total Sales',
                  value: '₹3,84,900',
                  trend: '+8.3% vs last week',
                  trendColor: Colors.green,
                  icon: Icons.monetization_on_rounded,
                  iconColor: Colors.green,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Active Parties',
                  value: '184',
                  trend: '+3 registered today',
                  trendColor: Colors.orange,
                  icon: Icons.people_alt_rounded,
                  iconColor: Colors.deepPurple,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Products Stocked',
                  value: '456 Items',
                  trend: '5 Out of Stock',
                  trendColor: Colors.red,
                  icon: Icons.inventory_2_rounded,
                  iconColor: Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Split Section: Recent Activity & Quick Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Activity Panel
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          
                          // Mock Transaction List
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
                            title: 'New purchase order drafted',
                            time: '3 hours ago',
                            subtitle: 'Order #ORD-5012 • Vendor: Balaji Wholesalers',
                            statusIcon: Icons.add_shopping_cart,
                            statusColor: Colors.orange,
                          ),
                          _buildActivityItem(
                            theme: theme,
                            title: 'Inventory stock level warning',
                            time: '5 hours ago',
                            subtitle: 'Item: LED Bulb 9W is below reorder level (Qty: 4)',
                            statusIcon: Icons.warning_amber_rounded,
                            statusColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Quick Actions Menu (Hidden on narrow mobile layouts for neat scaling)
                if (ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context)) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 24),
                            
                            ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('Add New Party'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.create_new_folder_outlined),
                              label: const Text('Create New Invoice'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.post_add_outlined),
                              label: const Text('Receive Goods / Stock'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.print_outlined),
                              label: const Text('Export Daybook PDF'),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trend,
                  style: TextStyle(
                    color: trendColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
