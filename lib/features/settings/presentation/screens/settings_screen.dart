import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/utils/demo_data_seeder.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final prefs = ref.watch(sharedPreferencesProvider);

    final activeFirmId = prefs.getString('active_firm_id') ?? 'firm_default';
    final firmsList = prefs.getStringList('firms_list') ?? ['firm_default'];

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
              'Configure layouts, manage multiple firms, and wipe data.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            
            // Appearance Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
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

            // Company / Firm Manager Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business_center_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Company / Firm Manager',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateFirmDialog(prefs, firmsList),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Firm'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Manage and switch between separate databases for different companies.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: firmsList.length,
                      itemBuilder: (context, index) {
                        final firmId = firmsList[index];
                        final firmName = prefs.getString('firm_name_$firmId') ?? 
                            (firmId == 'firm_default' ? 'Default Company' : 'New Company');
                        final isActive = firmId == activeFirmId;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            firmName,
                            style: TextStyle(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text('ID: $firmId'),
                          leading: CircleAvatar(
                            backgroundColor: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.business,
                              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showEditFirmDialog(firmId, firmName),
                                tooltip: 'Edit Name',
                              ),
                              if (firmsList.length > 1)
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                  onPressed: () => _showDeleteFirmDialog(firmId, firmName),
                                  tooltip: 'Delete Company',
                                ),
                              const SizedBox(width: 8),
                              isActive
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                   : OutlinedButton(
                                       onPressed: () async {
                                         final db = ref.read(databaseServiceProvider);
                                         await db.switchFirm(firmId, prefs);
                                         ref.read(activeFirmIdProvider.notifier).state = firmId;
                                         ref.invalidate(dashboardAnalyticsProvider);
                                         if (context.mounted) {
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             SnackBar(
                                               content: Text('Switched to company: $firmName'),
                                               backgroundColor: Colors.green,
                                             ),
                                           );
                                           context.go('/dashboard');
                                         }
                                       },
                                       child: const Text('Switch'),
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

            // Testing & Demo Data Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
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
                          ref.invalidate(dashboardAnalyticsProvider);
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

            // Safe Wipe Data Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Text(
                          'Wipe Firm Data',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Clear all customers, items, sales, and transaction registers for the current active firm (${prefs.getString('firm_name_$activeFirmId') ?? "Default Company"}). This will not affect other firms, and will prevent demo data from re-seeding.',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Wipe Current Firm Data', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _showWipeDataDialog(prefs, activeFirmId),
                    ),
                  ],
                ),
              ),
            ),
            // Bank Accounts Manager Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Bank Accounts Manager',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditBankAccountDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Account'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ref.watch(bankAccountsListProvider).when(
                      data: (accounts) {
                        final activeAccounts = accounts.where((a) => !a.isDeleted).toList();
                        if (activeAccounts.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No bank accounts configured. Add one to enable bank transfers, receipts, and payments.',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeAccounts.length,
                          separatorBuilder: (context, index) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final acc = activeAccounts[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                acc.accountName ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${acc.bankName ?? ""} | A/c: ${acc.accountNumber ?? ""}'),
                                  Text('IFSC: ${acc.ifscCode ?? ""} | Branch: ${acc.branchName ?? "N/A"}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${(acc.currentBalance ?? 0.0).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showAddEditBankAccountDialog(acc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () => _showDeleteBankAccountDialog(acc),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading accounts: $e'),
                    ),
                  ],
                ),
              ),
            ),
             const SizedBox(height: 20),

            // Firebase Cloud Sync Configuration Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_sync_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Firebase Cloud Sync Configuration',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Firebase Database Kaise Connect Karein (Guide):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Firebase Console (https://console.firebase.google.com/) par naya project banayein.\n'
                            '2. BUILD -> FIRESTORE DATABASE par click karke database ko "Test Mode" me create karein.\n'
                            '3. Firestore -> RULES tab me paste karein:\n'
                            '   allow read, write: if request.time < timestamp.date(2026, 8, 16);\n'
                            '4. BUILD -> AUTHENTICATION -> SIGN-IN METHOD me ANONYMOUS login ko "Enable" karein.\n'
                            '5. Project Settings me select karein aur dynamic web app key variables copy karein.\n'
                            '6. Save karke Application ko restart karein.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showFirebaseConfigDialog(prefs),
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Configure Firebase Keys'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reset Firebase Data?'),
                                content: const Text(
                                  'Kya aap sachme cloud database se is company ka sara data delete karna chahte hain? '
                                  'Isse aapka local database safe rahega, but cloud data clean ho jayega.'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Reset Now', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 12),
                                          Text('Deleting Cloud Data...'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              try {
                                await ref.read(syncServiceProvider).clearCloudData();
                                if (mounted) {
                                  Navigator.of(context).pop(); // dismiss loading dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Firebase data cleared successfully!')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // dismiss loading dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error clearing data: $e')),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_forever, color: Colors.white),
                          label: const Text('Reset Firebase Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[800],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // App Version Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
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

  void _showCreateFirmDialog(dynamic prefs, List<String> firmsList) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Company / Firm'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Company / Firm Name',
            hintText: 'e.g. Shaj Traders',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final newFirmId = 'firm_${DateTime.now().millisecondsSinceEpoch}';
              
              final updatedFirms = List<String>.from(firmsList)..add(newFirmId);
              await prefs.setStringList('firms_list', updatedFirms);
              await prefs.setString('firm_name_$newFirmId', name);
              
              // Set this firm as demo seeded (so it starts completely empty without re-seeding)
              await prefs.setBool('demo_seeded_$newFirmId', true);

              if (mounted) {
                setState(() {});
                Navigator.pop(context);
              }

              // Switch to the newly created firm
              final db = ref.read(databaseServiceProvider);
              await db.switchFirm(newFirmId, prefs);
              ref.read(activeFirmIdProvider.notifier).state = newFirmId;
              ref.invalidate(dashboardAnalyticsProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created and switched to company: $name'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.go('/dashboard');
              }
            },
            child: const Text('Create & Switch'),
          ),
        ],
      ),
    );
  }

  void _showEditFirmDialog(String firmId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Company / Firm'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Company / Firm Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.setString('firm_name_$firmId', newName);
              if (mounted) {
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFirmDialog(String firmId, String firmName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Company / Firm?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the company "$firmName"? This will permanently delete its local database and all of its records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = ref.read(sharedPreferencesProvider);
              final firmsList = prefs.getStringList('firms_list') ?? ['firm_default'];
              final activeFirmId = prefs.getString('active_firm_id') ?? 'firm_default';

              if (firmsList.length <= 1) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot delete the only remaining company.')),
                  );
                  Navigator.pop(context);
                }
                return;
              }

              // Remove from list
              final updatedFirmsList = List<String>.from(firmsList)..remove(firmId);
              await prefs.setStringList('firms_list', updatedFirmsList);
              await prefs.remove('firm_name_$firmId');
              await prefs.remove('demo_seeded_$firmId');

              // If deleted firm was active, switch to another firm
              if (firmId == activeFirmId) {
                final fallbackFirmId = updatedFirmsList.first;
                final db = ref.read(databaseServiceProvider);
                await db.switchFirm(fallbackFirmId, prefs);
                ref.read(activeFirmIdProvider.notifier).state = fallbackFirmId;
                ref.invalidate(dashboardAnalyticsProvider);
              }

              if (mounted) {
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Company "$firmName" deleted.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWipeDataDialog(dynamic prefs, String activeFirmId) {
    final firmName = prefs.getString('firm_name_$activeFirmId') ?? "Default Company";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Wipe Current Firm Data?'),
          ],
        ),
        content: Text(
          'This will permanently delete all records (invoices, purchases, products, payments, and contacts) in the company "$firmName". This action cannot be undone.',
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

                // Prevent demo seeding by marking as seeded
                await prefs.setBool('demo_seeded_$activeFirmId', true);

                ref.invalidate(dashboardAnalyticsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All data cleared successfully in company "$firmName"! Ready for fresh entries.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  context.go('/dashboard');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to wipe data: $e')),
                  );
                }
              }
            },
            child: const Text('Wipe Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditBankAccountDialog([BankAccount? account]) {
    final accountNameController = TextEditingController(text: account?.accountName);
    final bankNameController = TextEditingController(text: account?.bankName);
    final accountNumberController = TextEditingController(text: account?.accountNumber);
    final ifscController = TextEditingController(text: account?.ifscCode);
    final branchController = TextEditingController(text: account?.branchName);
    final openingController = TextEditingController(
      text: account == null ? '0' : (account.openingBalance ?? 0.0).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(account == null ? 'Add Bank Account' : 'Edit Bank Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: accountNameController,
                decoration: const InputDecoration(labelText: 'Account Display Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountNumberController,
                decoration: const InputDecoration(labelText: 'Account Number *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ifscController,
                decoration: const InputDecoration(labelText: 'IFSC Code *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: branchController,
                decoration: const InputDecoration(labelText: 'Branch Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: openingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Opening Balance', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final accName = accountNameController.text.trim();
              final bankName = bankNameController.text.trim();
              final accNum = accountNumberController.text.trim();
              final ifsc = ifscController.text.trim();
              final branch = branchController.text.trim();
              final opening = double.tryParse(openingController.text.trim()) ?? 0.0;

              if (accName.isEmpty || bankName.isEmpty || accNum.isEmpty || ifsc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required (*) fields.')),
                );
                return;
              }

              final repo = ref.read(bankAccountRepositoryProvider);
              if (account == null) {
                final newAccount = BankAccount()
                  ..uuid = '${DateTime.now().millisecondsSinceEpoch}'
                  ..accountName = accName
                  ..bankName = bankName
                  ..accountNumber = accNum
                  ..ifscCode = ifsc
                  ..branchName = branch
                  ..currentBalance = opening;
                await repo.create(newAccount);
              } else {
                account.accountName = accName;
                account.bankName = bankName;
                account.accountNumber = accNum;
                account.ifscCode = ifsc;
                account.branchName = branch;
                account.openingBalance = opening;
                account.currentBalance = opening; // simplest update
                account.updatedAt = DateTime.now();
                await repo.update(account);
              }

              ref.invalidate(bankAccountsListProvider);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBankAccountDialog(BankAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: Text('Are you sure you want to delete "${account.accountName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final repo = ref.read(bankAccountRepositoryProvider);
              account.isDeleted = true;
              account.updatedAt = DateTime.now();
              await repo.update(account);
              ref.invalidate(bankAccountsListProvider);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFirebaseConfigDialog(dynamic prefs) {
    final apiKeyController = TextEditingController(text: prefs.getString('firebase_api_key') ?? '');
    final projectIdController = TextEditingController(text: prefs.getString('firebase_project_id') ?? '');
    final appIdController = TextEditingController(text: prefs.getString('firebase_app_id') ?? '');
    final senderIdController = TextEditingController(text: prefs.getString('firebase_sender_id') ?? '');
    final storageBucketController = TextEditingController(text: prefs.getString('firebase_storage_bucket') ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Configure Firebase Sync'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: projectIdController,
                decoration: const InputDecoration(
                  labelText: 'Project ID *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: appIdController,
                decoration: const InputDecoration(
                  labelText: 'App ID *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: senderIdController,
                decoration: const InputDecoration(
                  labelText: 'Messaging Sender ID (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: storageBucketController,
                decoration: const InputDecoration(
                  labelText: 'Storage Bucket (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = apiKeyController.text.trim();
              final projectId = projectIdController.text.trim();
              final appId = appIdController.text.trim();
              final senderId = senderIdController.text.trim();
              final storageBucket = storageBucketController.text.trim();

              if (apiKey.isEmpty || projectId.isEmpty || appId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required (*) fields.')),
                );
                return;
              }

              await prefs.setString('firebase_api_key', apiKey);
              await prefs.setString('firebase_project_id', projectId);
              await prefs.setString('firebase_app_id', appId);
              if (senderId.isNotEmpty) {
                await prefs.setString('firebase_sender_id', senderId);
              } else {
                await prefs.remove('firebase_sender_id');
              }
              if (storageBucket.isNotEmpty) {
                await prefs.setString('firebase_storage_bucket', storageBucket);
              } else {
                await prefs.remove('firebase_storage_bucket');
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Firebase config saved! Restart the app to initialize Firebase connection.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
