import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class CustomDrawer extends ConsumerWidget {
  final bool isPermanent;

  const CustomDrawer({
    Key? key,
    required this.isPermanent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);
    final activeFirmId = ref.watch(activeFirmIdProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final firmName = prefs.getString('firm_name_$activeFirmId') ?? (activeFirmId == 'firm_default' ? 'Default Company' : 'New Company');

    return Drawer(
      elevation: isPermanent ? 0 : 6,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            // Premium Header Visual with gradient background
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E3C72),
                    Color(0xFF2A5298),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sahaj ERP',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    firmName.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    routePath: '/dashboard',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('ACCOUNTS'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.monetization_on_rounded,
                    label: 'Sales (Invoices)',
                    routePath: '/sales',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.shopping_bag_rounded,
                    label: 'Purchases (Bills)',
                    routePath: '/purchases',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Expenses',
                    routePath: '/expenses',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.arrow_downward_rounded,
                    label: 'Receipts (Payment In)',
                    routePath: '/receipts',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.arrow_upward_rounded,
                    label: 'Payments (Payment Out)',
                    routePath: '/payments',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.assignment_return_rounded,
                    label: 'Credit Notes',
                    routePath: '/credit-notes',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.assignment_returned_rounded,
                    label: 'Debit Notes',
                    routePath: '/debit-notes',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.swap_horiz_rounded,
                    label: 'Party Transfers',
                    routePath: '/party-transfers',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.monetization_on_rounded,
                    label: 'Other Income',
                    routePath: '/other-incomes',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('MANAGEMENT'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.people_alt_rounded,
                    label: 'Parties & Contacts',
                    routePath: '/parties',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.inventory_2_rounded,
                    label: 'Items & Inventory',
                    routePath: '/items',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.shopping_cart_rounded,
                    label: 'Sales Orders',
                    routePath: '/orders',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('SYSTEM'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.analytics_rounded,
                    label: 'Reports & Analytics',
                    routePath: '/reports',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.cloud_sync_rounded,
                    label: 'Sync Center',
                    routePath: '/sync-center',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.sd_storage_rounded,
                    label: 'Local Backup',
                    routePath: '/backup',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    routePath: '/settings',
                    currentPath: location,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.offline_pin_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Offline Sync Core v1.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.grey,
        ),
      ),
    );
  }

  Color _getItemColor(String routePath) {
    switch (routePath) {
      case '/dashboard': return const Color(0xFF1E88E5); // Rich blue
      case '/sales': return const Color(0xFF43A047); // Rich emerald green
      case '/purchases': return const Color(0xFF5E35B1); // Premium indigo
      case '/expenses': return const Color(0xFFE53935); // Clean red
      case '/receipts': return const Color(0xFF43A047); // Emerald green
      case '/payments': return const Color(0xFFE53935); // Clean red
      case '/credit-notes': return const Color(0xFF3F51B5); // Indigo
      case '/debit-notes': return const Color(0xFFFB8C00); // Deep orange
      case '/party-transfers': return const Color(0xFF009688); // Teal
      case '/other-incomes': return const Color(0xFF2196F3); // Blue
      case '/parties': return const Color(0xFFD81B60); // Magenta/pink
      case '/items': return const Color(0xFFF57C00); // Amber orange
      case '/orders': return const Color(0xFF00897B); // Clean teal
      case '/reports': return const Color(0xFF00ACC1); // Vivid cyan
      case '/sync-center': return const Color(0xFF00897B); // Teal
      case '/backup': return const Color(0xFF795548); // Brown
      case '/settings': return const Color(0xFF757575); // Slate grey
      default: return const Color(0xFF1E88E5);
    }
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String routePath,
    required String currentPath,
  }) {
    final theme = Theme.of(context);
    final isActive = currentPath == routePath;
    final itemColor = _getItemColor(routePath);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive 
              ? itemColor.withOpacity(0.08) 
              : Colors.transparent,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isActive 
                ? itemColor 
                : itemColor.withOpacity(0.7),
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              fontSize: 13.0,
              color: isActive 
                  ? itemColor 
                  : theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          selected: isActive,
          hoverColor: itemColor.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          minLeadingWidth: 20,
          dense: true,
          onTap: () {
            if (!isPermanent) {
              Navigator.of(context).pop();
            }
            if (!isActive) {
              context.go(routePath);
            }
          },
        ),
      ),
    );
  }
}
