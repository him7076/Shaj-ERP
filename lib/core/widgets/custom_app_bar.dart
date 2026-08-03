import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/connectivity_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/sync_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/core/widgets/pulsing_dot_widget.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final themeMode = ref.watch(themeProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final syncStateAsync = ref.watch(syncStateProvider);
    final authState = ref.watch(authProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final location = GoRouterState.of(context).matchedLocation;
    final isDashboard = location == '/' || location == '/dashboard' || location.isEmpty;

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E).withOpacity(0.95) : Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        child: Row(
          children: [
            // Drawer button for mobile
            if (Scaffold.of(context).hasDrawer)
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),

            // App Brand Logo & Title (Only show logo on non-dashboard tabs in mobile)
            if (!isMobile || isDashboard)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMobile ? 'Sahaj ERP' : 'Business Sahaj ERP',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Executive Edition',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(width: 24),

            // Quick Search Input Bar (Desktop / Tablet)
            if (!isMobile)
              Expanded(
                child: Container(
                  height: 40,
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quick search transactions, parties, items...',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Text(
                          'Ctrl K',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Spacer(),

            const SizedBox(width: 12),

            if (isMobile) ...[
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'App Options',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) async {
                  if (val == 'sync') {
                    ref.read(syncServiceProvider).syncAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚡ Syncing local database with Cloud...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (val == 'theme') {
                    ref.read(themeProvider.notifier).toggleTheme();
                  } else if (val == 'logout') {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'info',
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? '🟢 Cloud Live Mode' : '🔴 Offline Mode',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOnline ? const Color(0xFF10B981) : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.email ?? 'admin@sahaj.com',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'sync',
                    child: Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 18, color: Color(0xFF6366F1)),
                        SizedBox(width: 10),
                        Text('Sync Database Now'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 18,
                          color: themeMode == ThemeMode.dark ? Colors.amber : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 10),
                        Text(themeMode == ThemeMode.dark ? 'Switch Light Mode' : 'Switch Dark Mode'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Desktop Header Actions
              Consumer(
                builder: (context, ref, _) {
                  final prefs = ref.watch(sharedPreferencesProvider);
                  final isCloudSyncEnabled = prefs.getBool('enable_firebase_cloud_sync') ?? true;

                  if (!isCloudSyncEnabled) {
                    return Tooltip(
                      message: 'Local Offline Mode Active (Firebase Sync OFF)',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.sd_storage_rounded, size: 14, color: Colors.amber),
                            SizedBox(width: 6),
                            Text(
                              'Local Mode',
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Tooltip(
                    message: isOnline ? 'Network Connection: Live Cloud Sync' : 'Network Connection: Offline',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isOnline ? const Color(0xFF10B981) : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isOnline ? const Color(0xFF10B981) : Colors.red).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          PulsingDotWidget(
                            color: isOnline ? const Color(0xFF10B981) : Colors.red,
                            size: 8,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Cloud Live' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? const Color(0xFF10B981) : Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Sync Database Now',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
                icon: isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : syncStateAsync.maybeWhen(
                        data: (state) => Icon(
                          state.status == SyncStatus.failure
                              ? Icons.sync_problem_rounded
                              : Icons.sync_rounded,
                          size: 20,
                          color: state.status == SyncStatus.failure ? Colors.redAccent : theme.colorScheme.primary,
                        ),
                        orElse: () => Icon(Icons.sync_rounded, size: 20, color: theme.colorScheme.primary),
                      ),
                onPressed: isSyncing
                    ? null
                    : () {
                        ref.read(syncServiceProvider).syncAll();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚡ Syncing local offline database with Cloud...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: themeMode == ThemeMode.dark ? 'Switch to Light Theme' : 'Switch to Obsidian Dark Theme',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
                icon: Icon(
                  themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: themeMode == ThemeMode.dark ? Colors.amber : const Color(0xFF475569),
                ),
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
              const SizedBox(width: 12),
              PopupMenuButton<int>(
                tooltip: 'Account Options',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF0EA5E9)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.surface,
                    child: Text(
                      (authState.email != null && authState.email!.isNotEmpty)
                          ? authState.email![0].toUpperCase()
                          : 'A',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 1) {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0,
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logged In Executive',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.email ?? 'admin@sahaj.com',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

