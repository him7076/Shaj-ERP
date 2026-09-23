import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/unsaved_changes_provider.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/core/theme/app_decorations.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';

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
    final enableTasks = prefs.getBool('enable_task_management') ?? false;

    final themeState = ref.watch(themeProvider);
    final isNeumorphic = themeState.themeType == ThemeType.neumorphism;

    return Drawer(
      elevation: isPermanent ? 0 : 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isNeumorphic 
              ? theme.scaffoldBackgroundColor
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          border: isPermanent
              ? Border(
                  right: BorderSide(
                    color: isNeumorphic 
                        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
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
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      tooltip: 'Switch Firm',
                      offset: const Offset(0, 45),
                      onSelected: (selectedFirmId) async {
                        if (selectedFirmId == 'manage_firms') {
                          if (!isPermanent) Navigator.of(context).pop();
                          context.go('/settings');
                          return;
                        }
                        if (selectedFirmId == activeFirmId) return;
                        
                        // Show switching indicator dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            content: Row(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Switching firm & loading data...',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        try {
                          final db = ref.read(databaseServiceProvider);
                          await db.switchFirm(selectedFirmId, prefs);
                          ref.read(activeFirmIdProvider.notifier).state = selectedFirmId;
                          
                          // Sync Manager clears stale timestamps and downloads data
                          try {
                            await ref.read(syncManagerProvider).handleFirmSwitch(selectedFirmId);
                          } catch (_) {}

                          // Invalidate providers to force refresh UI
                          ref.invalidate(sharedPreferencesProvider);
                          
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop(); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚡ Firm switched successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            if (!isPermanent) Navigator.of(context).pop();
                            context.go('/dashboard');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to switch firm: $e')),
                            );
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        final firmsList = prefs.getStringList('firms_list') ?? ['firm_default'];
                        final items = firmsList.map((firmId) {
                          final name = prefs.getString('firm_name_$firmId') ?? 
                              (firmId == 'firm_default' ? 'Default Company' : 'New Company');
                          final isActive = firmId == activeFirmId;
                          return PopupMenuItem<String>(
                            value: firmId,
                            child: Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle_rounded : Icons.business_rounded, 
                                  color: isActive ? Colors.green : (isDark ? Colors.white70 : Colors.black87),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      color: isActive ? Colors.green : null,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                        
                        items.add(const PopupMenuItem<String>(
                          value: 'manage_firms',
                          child: Row(
                            children: [
                              Icon(Icons.settings_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Manage Firms', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ));
                        return items;
                      },
                      child: Container(
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
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Menu List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: ref.watch(vaultModeProvider) == VaultMode.personal
                 ? [
                  _buildDrawerHeader('PERSONAL VAULT'),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.pie_chart_rounded,
                    label: 'Personal Stats',
                    routePath: '/personal-stats',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.receipt_long_rounded,
                    label: 'Transactions',
                    routePath: '/transactions',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.task_alt_rounded,
                    label: 'Tasks',
                    routePath: '/tasks',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.settings_rounded,
                    label: 'Accounts & Manage',
                    routePath: '/personal-management',
                    currentPath: location,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo.shade900,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.business_rounded),
                      label: const Text('Back to Business Vault'),
                      onPressed: () {
                        ref.read(vaultModeProvider.notifier).setMode(VaultMode.business);
                        if (!isPermanent) Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    ),
                  ),
                 ]
                 : [
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
                  if (prefs.getBool('enable_fixed_assets') ?? false)
                    _buildDrawerItem(
                      context: context,
                      ref: ref,
                      icon: Icons.domain_rounded,
                      label: 'Fixed Assets',
                      routePath: '/fixed-assets',
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
                  if (enableTasks)
                    _buildDrawerItem(
                      context: context,
                      ref: ref,
                      icon: Icons.task_alt_rounded,
                      label: 'Task Management',
                      routePath: '/tasks',
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
                  _buildDrawerHeader('OTHER FEATURES'),
                  _buildDrawerItem(
                    context: context,
                    ref: ref,
                    icon: Icons.settings_applications_rounded, // Optional: change icon to better fit "settings"
                    label: 'Other Settings',
                    routePath: '/other-features',
                    currentPath: location,
                  ),
                  if (prefs.getBool('enable_personal_vault') ?? false)
                    _buildDrawerItem(
                      context: context,
                      ref: ref,
                      icon: Icons.security,
                      label: 'Personal Vault',
                      routePath: '/personal-stats',
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
                    icon: Icons.sd_storage_rounded,
                    label: 'Backup & Restore (.sahaj)',
                    routePath: '/backup',
                    currentPath: location,
                  ),
                  _buildThemesDrawerItem(context: context, ref: ref),
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

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isNeumorphic 
                  ? theme.scaffoldBackgroundColor
                  : (isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Theme Switcher Tile
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isNeumorphic 
                                  ? theme.scaffoldBackgroundColor
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: isNeumorphic
                                  ? null
                                  : Border.all(color: isDark ? Colors.white12 : Colors.black12),
                              boxShadow: isNeumorphic 
                                  ? [
                                      BoxShadow(
                                        color: isDark ? Colors.black.withOpacity(0.6) : const Color(0xFFA3B1C6).withOpacity(0.6),
                                        offset: const Offset(4, 4),
                                        blurRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: isDark ? const Color(0xFF2D2D36).withOpacity(0.5) : Colors.white.withOpacity(0.9),
                                        offset: const Offset(-4, -4),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    isDark ? 'Dark Mode' : 'Light Mode',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
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
      case '/fixed-assets': return const Color(0xFFEAB308);
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
      case '/tasks': return const Color(0xFF22C55E);
      case '/reports': return const Color(0xFF06B6D4);
      case '/sync-center': return const Color(0xFF10B981);
      case '/backup': return const Color(0xFF8B5CF6);
      case '/other-features': return const Color(0xFFEAB308);
      case '/vault': return Colors.blueGrey;
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

    final themeState = ref.watch(themeProvider);
    final isNeumorphic = themeState.themeType == ThemeType.neumorphism;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive 
              ? (isNeumorphic 
                  ? (isDark ? const Color(0xFF18181D) : const Color(0xFFD1D9E6)) 
                  : itemColor.withOpacity(isDark ? 0.18 : 0.1))
              : Colors.transparent,
          boxShadow: isActive && isNeumorphic
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.4) : const Color(0xFFA3B1C6).withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ]
              : null,
        ),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? (isNeumorphic ? Colors.transparent : itemColor.withOpacity(0.2)) : Colors.transparent,
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
                  ? (isDark || isNeumorphic ? (isNeumorphic ? theme.colorScheme.onSurface : Colors.white) : itemColor)
                  : theme.colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
          trailing: isActive && !isNeumorphic
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

            if (routePath == '/personal-stats' || routePath == '/personal-management') {
              ref.read(vaultModeProvider.notifier).setMode(VaultMode.personal);
            } else if (routePath == '/dashboard') {
              ref.read(vaultModeProvider.notifier).setMode(VaultMode.business);
            }

            if (!isPermanent) {
              Navigator.of(context).pop();
            }
            context.go(routePath);
          },
        ),
      ),
    );
  }

  Widget _buildThemesDrawerItem({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.color_lens_rounded,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            size: 18,
          ),
        ),
        title: Text(
          'Themes & Appearance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.0,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minLeadingWidth: 24,
        onTap: () {
          if (!isPermanent) Navigator.pop(context);
          _showThemeSettingsDialog(context, ref);
        },
      ),
    );
  }

  void _showThemeSettingsDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final themeState = ref.watch(themeProvider);
            final notifier = ref.read(themeProvider.notifier);
            
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Themes & Appearance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<ThemeMode>(
                          title: const Text('Light', style: TextStyle(fontSize: 13)),
                          value: ThemeMode.light,
                          groupValue: themeState.themeMode,
                          onChanged: (val) => notifier.setThemeMode(val!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<ThemeMode>(
                          title: const Text('Dark', style: TextStyle(fontSize: 13)),
                          value: ThemeMode.dark,
                          groupValue: themeState.themeMode,
                          onChanged: (val) => notifier.setThemeMode(val!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<ThemeMode>(
                          title: const Text('System', style: TextStyle(fontSize: 13)),
                          value: ThemeMode.system,
                          groupValue: themeState.themeMode,
                          onChanged: (val) => notifier.setThemeMode(val!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text('Theme Type', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<ThemeType>(
                          title: const Text('Standard (Material)'),
                          subtitle: const Text('Classic flat material design', style: TextStyle(fontSize: 11)),
                          value: ThemeType.standard,
                          groupValue: themeState.themeType,
                          onChanged: (val) => notifier.setThemeType(val!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeType>(
                          title: const Text('Neumorphism (3D Soft UI)'),
                          subtitle: const Text('Soft UI with blending backgrounds', style: TextStyle(fontSize: 11)),
                          value: ThemeType.neumorphism,
                          groupValue: themeState.themeType,
                          onChanged: (val) => notifier.setThemeType(val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

