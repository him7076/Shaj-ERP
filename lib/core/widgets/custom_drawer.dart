import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatelessWidget {
  final bool isPermanent;

  const CustomDrawer({
    Key? key,
    required this.isPermanent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the active route location to highlight the menu option
    final String location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);

    return Drawer(
      elevation: isPermanent ? 0 : 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Drawer Header Visual
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.primary.withOpacity(0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.business_center_rounded,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sahaj ERP',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enterprise Manager',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Drawer Navigation Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  routePath: '/dashboard',
                  currentPath: location,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.people_alt_rounded,
                  label: 'Parties',
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
                  label: 'Orders',
                  routePath: '/orders',
                  currentPath: location,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.monetization_on_rounded,
                  label: 'Sales',
                  routePath: '/sales',
                  currentPath: location,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.analytics_rounded,
                  label: 'Reports',
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
          const Divider(height: 1),

          // Drawer Footer Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.offline_pin_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Offline Sync Core v1.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
          ),
        ),
        selected: isActive,
        selectedTileColor: theme.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          // If in mobile layout, close the slider drawer first before navigating
          if (!isPermanent) {
            Navigator.of(context).pop();
          }
          
          if (!isActive) {
            context.go(routePath);
          }
        },
      ),
    );
  }
}
