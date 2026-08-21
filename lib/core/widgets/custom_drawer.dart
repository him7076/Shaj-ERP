import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/unsaved_changes_provider.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/core/theme/app_decorations.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final activeFirmId = ref.watch(activeFirmIdProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final firmName = prefs.getString('firm_name_$activeFirmId') ?? (activeFirmId == 'firm_default' ? 'Default Company' : 'New Company');

    return Drawer(
      elevation: isPermanent ? 0 : 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: isPermanent
              ? Border(
                  right: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                )
              : null,
        ),
        child: Column(
          children: [
            // Executive Header Banner with mesh gradient
            Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sahaj ERP',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                              ),
                              child: const Text(
                                'ENTERPRISE PRO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6EE7B7),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business_center_rounded, color: Color(0xFFA5B4FC), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            firmName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    routePath: '/dashboard',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('FINANCIAL ACCOUNTS'),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.shopping_cart_rounded,
                    label: 'Sales Orders',
                    routePath: '/orders',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp Order Importer',
                    routePath: '/orders/whatsapp-import',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.tune_rounded,
                    label: 'WhatsApp Mapping Master',
                    routePath: '/orders/whatsapp-mappings',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.receipt_long_rounded,
                    label: 'All Transactions',
                    routePath: '/transactions',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.point_of_sale_rounded,
                    label: 'Sales (Invoices)',
                    routePath: '/sales',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.shopping_bag_rounded,
                    label: 'Purchases (Bills)',
                    routePath: '/purchases',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Expenses',
                    routePath: '/expenses',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.arrow_circle_down_rounded,
                    label: 'Receipts (Payment In)',
                    routePath: '/receipts',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.arrow_circle_up_rounded,
                    label: 'Payments (Payment Out)',
                    routePath: '/payments',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.assignment_return_rounded,
                    label: 'Credit Notes',
                    routePath: '/credit-notes',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.assignment_returned_rounded,
                    label: 'Debit Notes',
                    routePath: '/debit-notes',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.swap_horiz_rounded,
                    label: 'Party Transfers',
                    routePath: '/party-transfers',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.monetization_on_rounded,
                    label: 'Other Income',
                    routePath: '/other-incomes',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.tune_rounded,
                    label: 'Stock Adjustments',
                    routePath: '/stock-adjustments',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('BUSINESS MASTERS'),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.account_balance_rounded,
                    label: 'Cash & Bank',
                    routePath: '/cash-and-bank',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.category_rounded,
                    label: 'Categories',
                    routePath: '/categories',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.people_alt_rounded,
                    label: 'Parties & Customers',
                    routePath: '/parties',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.inventory_2_rounded,
                    label: 'Items & Stock',
                    routePath: '/items',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('MANAGEMENT & BULK EDIT'),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.edit_note_rounded,
                    label: 'Bulk Item Edit',
                    routePath: '/bulk-item-edit',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('REPORTS & SYSTEM'),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports & Analytics',
                    routePath: '/reports',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.cloud_sync_rounded,
                    label: 'Sync Center',
                    routePath: '/sync-center',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    routePath: '/settings',
                    currentPath: location,
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 0.5, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),

            // Quick Control Actions Footer (Theme, Sync & Logout)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Theme Switcher Tile
                      InkWell(
                        onTap: () {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDark ? 'Dark Mode' : 'Light Mode',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Logout Button
                      IconButton(
                        tooltip: 'Logout Account',
                        icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFF43F5E)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Confirm Logout'),
                              content: const Text('Are you sure you want to log out of Sahaj ERP?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          }
                        },
                      ),
                    ],
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Color _getItemColor(String routePath) {
    switch (routePath) {
      case '/dashboard': return const Color(0xFF6366F1);
      case '/orders': return const Color(0xFF0EA5E9);
      case '/orders/whatsapp-import': return const Color(0xFF25D366);
      case '/orders/whatsapp-mappings': return const Color(0xFF10B981);
      case '/transactions': return const Color(0xFF8B5CF6);
      case '/sales': return const Color(0xFF10B981);
      case '/purchases': return const Color(0xFF6366F1);
      case '/expenses': return const Color(0xFFF43F5E);
      case '/receipts': return const Color(0xFF10B981);
      case '/payments': return const Color(0xFFF43F5E);
      case '/credit-notes': return const Color(0xFF6366F1);
      case '/debit-notes': return const Color(0xFFF59E0B);
      case '/party-transfers': return const Color(0xFF14B8A6);
      case '/other-incomes': return const Color(0xFF3B82F6);
      case '/cash-and-bank': return const Color(0xFF0EA5E9);
      case '/categories': return const Color(0xFFEC4899);
      case '/parties': return const Color(0xFFD946EF);
      case '/items': return const Color(0xFFF97316);
      case '/stock-adjustments': return const Color(0xFF8B5CF6);
      case '/bulk-item-edit': return const Color(0xFFF59E0B);
      case '/reports': return const Color(0xFF06B6D4);
      case '/sync-center': return const Color(0xFF10B981);
      case '/settings': return const Color(0xFF64748B);
      default: return const Color(0xFF6366F1);
    }
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required String routePath,
    required String currentPath,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = currentPath == routePath;
    final itemColor = _getItemColor(routePath);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive 
              ? itemColor.withOpacity(isDark ? 0.18 : 0.1) 
              : Colors.transparent,
        ),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? itemColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isActive ? itemColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              size: 18,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13.0,
              color: isActive 
                  ? (isDark ? Colors.white : itemColor)
                  : theme.colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          trailing: isActive
              ? Container(
                  width: 6,
                  height: 18,
                  decoration: BoxDecoration(
                    color: itemColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: itemColor.withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          minLeadingWidth: 24,
          onTap: () async {
            final hasUnsaved = ref.read(unsavedChangesProvider);
            if (hasUnsaved && !isActive) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      SizedBox(width: 10),
                      Text('Unsaved Changes!', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: const Text(
                    'You have unsaved changes in your current transaction form. Navigating away will discard your changes.\n\nDo you want to discard changes and leave?',
                    style: TextStyle(height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Stay & Continue Editing'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Discard & Navigate'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;
              ref.read(unsavedChangesProvider.notifier).state = false;
            }

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

