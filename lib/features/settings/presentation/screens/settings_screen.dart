import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/demo_data_seeder.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure layout preferences and sync options.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            
            // Appearance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Appearance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Choose Theme Mode',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    
                    // Segmented Theme Button
                    SegmentedButton<ThemeMode>(
                      segments: const <ButtonSegment<ThemeMode>>[
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.settings_suggest_outlined),
                        ),
                      ],
                      selected: <ThemeMode>{currentThemeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        ref.read(themeProvider.notifier).setThemeMode(newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Testing & Demo Data Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.layers_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Testing & Demo Data',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Load sample business data (Customers, Products, Orders, Invoices) to test all functionalities of the ERP system instantly.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: const Text('Load Sample Demo Data'),
                      onPressed: () async {
                        try {
                          final db = ref.read(databaseServiceProvider);
                          await DemoDataSeeder.seedDemoData(db);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Demo business data loaded successfully! Redirecting...'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.go('/dashboard');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to load demo data: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Start New Firm Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business_outlined, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Text(
                          'Firm Management',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Ready to start your actual firm? Clear all local testing/demo data and start fresh with empty registers.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                      label: const Text('Start New Firm (Clear All Data)', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Clear All Local Data?'),
                              ],
                            ),
                            content: const Text(
                              'This action will permanently delete all local customers, products, invoices, orders, and configurations. This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    final db = ref.read(databaseServiceProvider);
                                    await db.clearDatabase();
                                    
                                    // Clear SharedPreferences/Cache
                                    final prefs = ref.read(sharedPreferencesProvider);
                                    await prefs.clear();
                                    
                                    // Logout
                                    await ref.read(authProvider.notifier).logout();
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('All data cleared successfully! Welcome to your fresh firm!'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                      context.go('/dashboard');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to clear database: $e')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Wipe All Data', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // App Version Info Card
            Card(
              child: ListTile(
                leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                title: const Text('Version Info'),
                subtitle: const Text('Business Sahaj ERP v1.0.0'),
                trailing: Text(
                  'Stable Release',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
