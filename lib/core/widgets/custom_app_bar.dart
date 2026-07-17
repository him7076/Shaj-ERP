import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/connectivity_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/sync_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final themeMode = ref.watch(themeProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final syncStateAsync = ref.watch(syncStateProvider);
    final authState = ref.watch(authProvider);
    
    final theme = Theme.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AppBar(
      title: Text(
        isMobile ? 'Sahaj ERP' : 'Business Sahaj ERP',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      elevation: 1,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      actions: [
        // Internet Connectivity status widget
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Tooltip(
            message: isOnline ? 'Network Connection: Online' : 'Network Connection: Offline',
            child: isMobile
                ? IconButton(
                    icon: Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 20,
                      color: isOnline ? Colors.green : Colors.red,
                    ),
                    onPressed: null,
                  )
                : Chip(
                    avatar: Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: isOnline ? Colors.green[800] : Colors.grey[800],
                    ),
                    label: Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.green[800] : Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: isOnline ? Colors.green[100] : Colors.grey[200],
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
          ),
        ),

        // Firebase Synchronization Action Button
        IconButton(
          tooltip: 'Sync Database',
          icon: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : syncStateAsync.maybeWhen(
                  data: (state) => Icon(
                    state.status == SyncStatus.failure
                        ? Icons.sync_problem_rounded
                        : Icons.sync_rounded,
                    color: state.status == SyncStatus.failure ? Colors.redAccent : Colors.white,
                  ),
                  orElse: () => const Icon(Icons.sync_rounded),
                ),
          onPressed: isSyncing
              ? null
              : () {
                  ref.read(syncServiceProvider).syncAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting Firebase Sync...')),
                  );
                },
        ),

        // Appearance Theme Switcher
        IconButton(
          tooltip: 'Toggle Theme',
          icon: Icon(
            themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () {
            ref.read(themeProvider.notifier).toggleTheme();
          },
        ),

        const SizedBox(width: 8),

        // User Account Dropdown
        PopupMenuButton<int>(
          tooltip: 'Account Options',
          icon: CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              (authState.email != null && authState.email!.isNotEmpty)
                  ? authState.email![0].toUpperCase()
                  : 'A',
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onSelected: (value) async {
            if (value == 1) {
              // Trigger sign out sequence
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
                    'Logged In As:',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    authState.email ?? 'admin@sahaj.com',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
