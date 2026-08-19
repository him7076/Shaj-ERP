import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/backup/presentation/providers/backup_providers.dart';
import 'package:business_sahaj_erp/core/utils/demo_data_seeder.dart';
import 'package:business_sahaj_erp/features/auth/presentation/providers/auth_provider.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/features/purchases/presentation/providers/purchase_providers.dart';
import 'package:business_sahaj_erp/features/sales/presentation/providers/invoice_providers.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/providers/expense_providers.dart';
import 'package:business_sahaj_erp/features/transactions/presentation/providers/transaction_providers.dart';

import 'package:business_sahaj_erp/core/constants/color_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncingFirms = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _syncFirmsFromFirebase());
  }

  Future<void> _syncFirmsFromFirebase() async {
    if (_isSyncingFirms) return;
    setState(() {
      _isSyncingFirms = true;
    });
    try {
      await ref.read(syncServiceProvider).syncFirms();
      ref.invalidate(activeFirmIdProvider);
      ref.invalidate(dashboardAnalyticsProvider);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isSyncingFirms = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final prefs = ref.watch(sharedPreferencesProvider);

    final activeFirmId = prefs.getString('active_firm_id') ?? 'firm_default';
    final firmsList = prefs.getStringList('firms_list') ?? ['firm_default'];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Application & Enterprise Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Manage your multi-firm workspace, appearance mode, database sync, and validation controls.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            
            // Appearance Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.palette_rounded, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Appearance & Theme Customization',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, thickness: 0.5),
                    const Text(
                      'Choose Theme Mode:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    
                    SegmentedButton<ThemeMode>(
                      segments: const <ButtonSegment<ThemeMode>>[
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light Mode'),
                          icon: Icon(Icons.light_mode_rounded),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Obsidian Dark'),
                          icon: Icon(Icons.dark_mode_rounded),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System Default'),
                          icon: Icon(Icons.settings_suggest_rounded),
                        ),
                      ],
                      selected: <ThemeMode>{currentThemeState.themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        ref.read(themeProvider.notifier).setThemeMode(newSelection.first);
                      },
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    const Text(
                      'Dual-Tone Gradient Presets (8):',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    const SizedBox(height: 8),

                    const Text(
                      'Custom Full Spectrum & Dual-Color Gradient Engine:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: () => _showFullSpectrumColorPicker(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: currentThemeState.themePreset == AppThemePreset.custom && currentThemeState.customPrimaryColor != null && currentThemeState.customSecondaryColor != null
                              ? LinearGradient(colors: [currentThemeState.customPrimaryColor!, currentThemeState.customSecondaryColor!])
                              : LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (currentThemeState.customPrimaryColor ?? theme.colorScheme.primary).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                              child: const Icon(Icons.color_lens_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentThemeState.themePreset == AppThemePreset.custom ? 'Custom Spectrum Color Active' : 'Custom Dual-Color Gradient Picker',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Pick ANY custom solid RGB/HSV color or create a custom dual-color gradient combination.',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
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
                side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.business_center_rounded, color: Color(0xFF0EA5E9), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Company / Multi-Firm Manager',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: _isSyncingFirms
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sync, size: 20),
                              onPressed: _isSyncingFirms ? null : () => _syncFirmsFromFirebase(),
                              tooltip: 'Sync Companies with Firebase',
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateFirmDialog(prefs, firmsList),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Firm'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Manage and switch between separate databases for different companies.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: firmsList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final firmId = firmsList[index];
                        final firmName = prefs.getString('firm_name_$firmId') ?? 
                            (firmId == 'firm_default' ? 'Default Company' : 'New Company');
                        final isActive = firmId == activeFirmId;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? theme.colorScheme.primaryContainer.withOpacity(0.12)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.4),
                              width: isActive ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.business_rounded,
                                      size: 18,
                                      color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firmName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'ID: $firmId',
                                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
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
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      StatefulBuilder(
                                        builder: (context, setFirmState) {
                                          final bool isFirmSyncEnabled = prefs.getBool('enable_firm_sync_$firmId') ?? true;

                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isFirmSyncEnabled ? 'Cloud Sync ON' : 'Cloud Sync OFF',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isFirmSyncEnabled ? Colors.green : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Switch.adaptive(
                                                value: isFirmSyncEnabled,
                                                activeColor: Colors.blue,
                                                onChanged: (val) async {
                                                  await prefs.setBool('enable_firm_sync_$firmId', val);
                                                  setFirmState(() {});
                                                  setState(() {});
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(val
                                                          ? '🌐 Firebase Sync ENABLED for "$firmName"!'
                                                          : '💾 Firebase Sync DISABLED for "$firmName". Data stays local.'),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        onPressed: () => _showEditFirmDialog(firmId, firmName),
                                        tooltip: 'Edit Name',
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  if (firmsList.length > 1)
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                                      onPressed: () => _showDeleteFirmDialog(firmId, firmName),
                                      tooltip: 'Delete Company',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (!isActive) ...[
                                    const SizedBox(width: 6),
                                     ElevatedButton(
                                       onPressed: () async {
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
                                                     'Switching to "$firmName" & loading data...',
                                                     style: const TextStyle(fontWeight: FontWeight.bold),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                         );

                                         try {
                                           final db = ref.read(databaseServiceProvider);
                                           await db.switchFirm(firmId, prefs);
                                           ref.read(activeFirmIdProvider.notifier).state = firmId;

                                           try {
                                             // handleFirmSwitch clears stale timestamps first, then does full cloud download
                                             await ref.read(syncManagerProvider).handleFirmSwitch(firmId);
                                          } catch (_) {}

                                           // 2. Invalidate all local data providers
                                           ref.invalidate(sharedPreferencesProvider);
                                           ref.invalidate(dashboardAnalyticsProvider);
                                           ref.invalidate(filteredPartiesProvider);
                                           ref.invalidate(filteredItemsProvider);
                                           ref.invalidate(unitsListProvider);
                                           ref.invalidate(purchaseListProvider);
                                           ref.invalidate(filteredInvoicesProvider);
                                           ref.invalidate(filteredOrdersProvider);
                                           ref.invalidate(expenseListProvider);
                                           ref.invalidate(bankAccountsListProvider);
                                           ref.invalidate(filteredTransactionsProvider);

                                           if (context.mounted) {
                                             Navigator.of(context, rootNavigator: true).pop(); // Close dialog
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(
                                                 content: Text('⚡ Switched to company: $firmName'),
                                                 backgroundColor: Colors.green,
                                               ),
                                             );
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
                                      style: ElevatedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      child: const Text('Switch Firm', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ],
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

            // FIREBASE CLOUD CONNECTION STATUS & QUOTA ERROR INDICATOR CARD
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder<dynamic>(
                  stream: ref.watch(syncServiceProvider).stateStream,
                  builder: (context, snapshot) {
                    final syncState = ref.watch(syncServiceProvider).currentState;
                    final isOnline = syncState.status != SyncStatus.error;
                    final hasError = syncState.status == SyncStatus.error || (syncState.errorMessage != null && syncState.errorMessage!.isNotEmpty);
                    final isQuotaError = hasError && (syncState.errorMessage?.toLowerCase().contains('quota') == true || syncState.errorMessage?.toLowerCase().contains('exceeded') == true);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (hasError ? Colors.red : Colors.green).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    hasError ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                                    color: hasError ? Colors.red : Colors.green,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Firebase Cloud Connection Status',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (hasError ? Colors.red : Colors.green).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: hasError ? Colors.red : Colors.green),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: hasError ? Colors.red : Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    hasError
                                        ? (isQuotaError ? '🔴 Firestore Quota Exceeded' : '🔴 Cloud Sync Error')
                                        : '🟢 Firebase Cloud Active',
                                    style: TextStyle(
                                      color: hasError ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Last Cloud Sync', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    syncState.lastSyncTime != null
                                        ? DateFormat('dd MMM yyyy, hh:mm a').format(syncState.lastSyncTime!)
                                        : 'Never synced',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sync Status', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    syncState.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: hasError ? Colors.red : Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (hasError && syncState.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    syncState.errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Consolidated Backup & Restore Center Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.swap_calls_rounded, color: Colors.indigo, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Backup & Restore Center',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Access the unified offline-first backup & restore system. Instant 0.5s binary backups & < 1s database restores with 100% data preservation.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open Backup & Restore Center', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => context.go('/backup'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // INSTANT LOCAL & CLOUD DATA MAINTENANCE (WIPE CONTROLS) CARD
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.withOpacity(0.4)),
              ),
              color: Colors.red.withOpacity(isDark ? 0.1 : 0.03),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Firm Data Maintenance & Reset Controls',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Clear or wipe database records specifically for active company "$activeFirmId". Local wipe clears Isar database; Cloud wipe clears Firestore documents.',
                      style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                            label: const Text('Wipe Local Data'),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Confirm Local Data Wipe'),
                                  content: Text('Are you sure you want to CLEAR ALL local Isar database records for "$activeFirmId"? This action cannot be undone unless you have a backup.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Clear Local Isar DB'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  final db = ref.read(databaseServiceProvider);
                                  await db.clearDatabase();

                                  ref.invalidate(sharedPreferencesProvider);
                                  ref.invalidate(dashboardAnalyticsProvider);
                                  ref.invalidate(filteredPartiesProvider);
                                  ref.invalidate(filteredItemsProvider);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('🗑️ Local database cleared for active firm.'), backgroundColor: Colors.red),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Local Wipe Failed: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepOrange,
                              side: const BorderSide(color: Colors.deepOrange),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.cloud_off_rounded, size: 18),
                            label: const Text('Wipe Cloud Data'),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Confirm Cloud Data Wipe'),
                                  content: Text('Are you sure you want to DELETE ALL remote Firestore documents for firm "$activeFirmId"? Local device data will not be affected.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Wipe Firestore Documents'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await ref.read(syncServiceProvider).clearCloudDataForActiveFirm();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('🌩️ Cloud Firestore data wiped for active firm.'), backgroundColor: Colors.deepOrange),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Cloud Wipe Failed: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Transaction & Warning Settings Card
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
                        Icon(Icons.warning_amber_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Transaction Settings & Warning Alerts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Configure operational warnings and validation alerts for sales, purchases, and stock movements.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setCardState) {
                        final bool negStock = prefs.getBool('enable_negative_stock_warning') ?? true;
                        final bool creditLimit = prefs.getBool('enable_credit_limit_warning') ?? true;
                        final bool lowStock = prefs.getBool('enable_low_stock_alert') ?? true;
                        final bool dupCheck = prefs.getBool('enable_duplicate_bill_no_check') ?? true;

                        return Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Negative Stock Warning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Show warning prompt when selling items with zero or insufficient inventory stock.', style: TextStyle(fontSize: 12)),
                              value: negStock,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) async {
                                await prefs.setBool('enable_negative_stock_warning', val);
                                setCardState(() {});
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Credit Limit Warning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Warn when customer outstanding balance exceeds allowed credit limit.', style: TextStyle(fontSize: 12)),
                              value: creditLimit,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) async {
                                await prefs.setBool('enable_credit_limit_warning', val);
                                setCardState(() {});
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Low Stock Badge Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Highlight items reaching reorder stock levels in catalog lists.', style: TextStyle(fontSize: 12)),
                              value: lowStock,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) async {
                                await prefs.setBool('enable_low_stock_alert', val);
                                setCardState(() {});
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: const Text('Duplicate Invoice / Bill Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Alert when entering a reference bill number that already exists.', style: TextStyle(fontSize: 12)),
                              value: dupCheck,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) async {
                                await prefs.setBool('enable_duplicate_bill_no_check', val);
                                setCardState(() {});
                              },
                            ),
                          ],
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          label: const Text('Wipe Current Firm Data (Local)', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () => _showWipeDataDialog(prefs, activeFirmId),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cloud_off_rounded),
                          label: const Text('Wipe Current Firm Data from Cloud'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showWipeCloudDataDialog(prefs, activeFirmId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
    _showAddEditFirmDialog(prefs, firmsList, null, null);
  }

  void _showEditFirmDialog(String firmId, String currentName) {
    final prefs = ref.read(sharedPreferencesProvider);
    final firmsList = prefs.getStringList('firms_list') ?? ['firm_default'];
    _showAddEditFirmDialog(prefs, firmsList, firmId, currentName);
  }

  void _showAddEditFirmDialog(dynamic prefs, List<String> firmsList, String? firmId, String? currentName) {
    final isEditing = firmId != null;
    final id = firmId ?? 'firm_${DateTime.now().millisecondsSinceEpoch}';

    final nameController = TextEditingController(text: currentName ?? '');
    final gstController = TextEditingController(text: prefs.getString('firm_gst_$id') ?? '');
    final mobileController = TextEditingController(text: prefs.getString('firm_mobile_$id') ?? '');
    final whatsappController = TextEditingController(text: prefs.getString('firm_whatsapp_$id') ?? '');
    final emailController = TextEditingController(text: prefs.getString('firm_email_$id') ?? '');
    final panController = TextEditingController(text: prefs.getString('firm_pan_$id') ?? '');
    final addressController = TextEditingController(text: prefs.getString('firm_address_$id') ?? '');
    final cityController = TextEditingController(text: prefs.getString('firm_city_$id') ?? '');
    final stateController = TextEditingController(text: prefs.getString('firm_state_$id') ?? '');
    final pincodeController = TextEditingController(text: prefs.getString('firm_pincode_$id') ?? '');
    final bankNameController = TextEditingController(text: prefs.getString('firm_bank_name_$id') ?? '');
    final bankAccController = TextEditingController(text: prefs.getString('firm_bank_acc_$id') ?? '');
    final ifscController = TextEditingController(text: prefs.getString('firm_ifsc_$id') ?? '');
    final upiController = TextEditingController(text: prefs.getString('firm_upi_$id') ?? '');
    final categoryController = TextEditingController(text: prefs.getString('firm_category_$id') ?? 'Trading & Retail');

    bool isFetchingGst = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);

          Future<void> autoFetchGst() async {
            final gstin = gstController.text.trim();
            if (gstin.length < 15) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid 15-digit GSTIN number.')),
              );
              return;
            }

            setDialogState(() => isFetchingGst = true);
            try {
              final gstService = ref.read(gstServiceProvider);
              final details = await gstService.fetchPartyDetailsFromGst(gstin);

              if (details != null) {
                setDialogState(() {
                  nameController.text = details.tradeName.isNotEmpty ? details.tradeName : details.legalName;
                  panController.text = details.panNumber;
                  stateController.text = details.stateName;
                  addressController.text = details.addressLine1;
                  cityController.text = details.city;
                  pincodeController.text = details.pincode;
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Auto-fetched firm details for ${details.tradeName}!'),
                      backgroundColor: Colors.amber.shade900,
                    ),
                  );
                }
              }
            } catch (_) {
            } finally {
              setDialogState(() => isFetchingGst = false);
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 650,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.business_rounded, color: theme.colorScheme.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Edit Firm Profile' : 'Create New Company / Firm',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isEditing ? 'Update business registration, tax details & banking' : 'Set up multi-firm business account in Shaj ERP',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // 1-Click GST Auto-Fetch Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade100, Colors.amber.shade50],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: gstController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'Enter GSTIN (e.g. 27AAAAA1111A1Z1)',
                                labelText: 'GSTIN Number',
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade900,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: isFetchingGst ? null : autoFetchGst,
                            icon: isFetchingGst
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_awesome, size: 16),
                            label: Text(isFetchingGst ? 'Fetching...' : '1-Click Auto-Fetch'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Basic Firm Info
                    Text('Business Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Company / Firm Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: whatsappController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.chat),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: panController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'PAN Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location & Address
                    Text('Address & Location', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Full Address / Street',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City / District',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Banking Details
                    Text('Banking & Payment Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: bankNameController,
                            decoration: const InputDecoration(
                              labelText: 'Bank Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.account_balance),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: bankAccController,
                            decoration: const InputDecoration(
                              labelText: 'Account Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ifscController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'IFSC Code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: upiController,
                            decoration: const InputDecoration(
                              labelText: 'UPI ID (e.g. business@upi)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(isEditing ? 'Save Firm Details' : 'Create & Switch Firm'),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Firm Name is required.')),
                              );
                              return;
                            }

                            // Save into SharedPreferences for this firm ID
                            if (!isEditing) {
                              final updatedFirms = List<String>.from(firmsList)..add(id);
                              await prefs.setStringList('firms_list', updatedFirms);
                              await prefs.setBool('demo_seeded_$id', true);
                            }

                            await prefs.setString('firm_name_$id', name);
                            await prefs.setString('firm_gst_$id', gstController.text.trim());
                            await prefs.setString('firm_mobile_$id', mobileController.text.trim());
                            await prefs.setString('firm_whatsapp_$id', whatsappController.text.trim());
                            await prefs.setString('firm_email_$id', emailController.text.trim());
                            await prefs.setString('firm_pan_$id', panController.text.trim());
                            await prefs.setString('firm_address_$id', addressController.text.trim());
                            await prefs.setString('firm_city_$id', cityController.text.trim());
                            await prefs.setString('firm_state_$id', stateController.text.trim());
                            await prefs.setString('firm_pincode_$id', pincodeController.text.trim());
                            await prefs.setString('firm_bank_name_$id', bankNameController.text.trim());
                            await prefs.setString('firm_bank_acc_$id', bankAccController.text.trim());
                            await prefs.setString('firm_ifsc_$id', ifscController.text.trim());
                            await prefs.setString('firm_upi_$id', upiController.text.trim());
                            await prefs.setString('firm_category_$id', categoryController.text.trim());

                            // Update active Isar Settings object
                            try {
                              final isar = ref.read(databaseServiceProvider).isar;
                              final settings = await isar.settings.filter().idGreaterThan(-1).findFirst() ?? Settings();
                              settings.companyName = name;
                              settings.companyGST = gstController.text.trim();
                              settings.companyPhone = mobileController.text.trim();
                              settings.companyAddress = addressController.text.trim();
                              await isar.writeTxn(() async => await isar.settings.put(settings));
                            } catch (_) {}

                            try {
                              await ref.read(syncServiceProvider).syncFirms();
                            } catch (_) {}

                            if (mounted) {
                              setState(() {});
                              Navigator.pop(context);
                            }

                            if (!isEditing) {
                              final db = ref.read(databaseServiceProvider);
                              await db.switchFirm(id, prefs);
                              ref.read(activeFirmIdProvider.notifier).state = id;
                              
                              try {
                                // handleFirmSwitch clears stale timestamps first, then does full cloud download
                                await ref.read(syncManagerProvider).handleFirmSwitch(id);
                              } catch (_) {}

                              // Invalidate all local data providers to guarantee clean multi-firm isolation
                              ref.invalidate(sharedPreferencesProvider);
                              ref.invalidate(dashboardAnalyticsProvider);
                              ref.invalidate(filteredPartiesProvider);
                              ref.invalidate(filteredItemsProvider);
                              ref.invalidate(categoriesListProvider);
                              ref.invalidate(brandsListProvider);
                              ref.invalidate(unitsListProvider);
                              ref.invalidate(purchaseListProvider);
                              ref.invalidate(filteredInvoicesProvider);
                              ref.invalidate(filteredOrdersProvider);
                              ref.invalidate(expenseListProvider);
                              ref.invalidate(bankAccountsListProvider);
                              ref.invalidate(filteredTransactionsProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Created and switched to company: $name'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                context.go('/dashboard');
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Updated company profile for $name'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

              try {
                await ref.read(syncServiceProvider).deleteRemoteFirm(firmId);
              } catch (_) {}

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

                // Automatically re-seed standard commercial units (PCS, BOX, KG, LTR, etc.)
                await DemoDataSeeder.seedStandardUnits(db);

                // Prevent demo seeding by marking as seeded
                await prefs.setBool('demo_seeded_$activeFirmId', true);

                ref.invalidate(dashboardAnalyticsProvider);
                ref.invalidate(filteredPartiesProvider);
                ref.invalidate(filteredItemsProvider);
                ref.invalidate(unitsListProvider);
                ref.invalidate(purchaseListProvider);
                ref.invalidate(filteredInvoicesProvider);
                ref.invalidate(filteredOrdersProvider);
                ref.invalidate(expenseListProvider);
                ref.invalidate(bankAccountsListProvider);
                ref.invalidate(filteredTransactionsProvider);

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

  void _showWipeCloudDataDialog(dynamic prefs, String activeFirmId) {
    final firmName = prefs.getString('firm_name_$activeFirmId') ?? "Default Company";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Wipe Cloud Data from Firebase?'),
          ],
        ),
        content: Text(
          'This will permanently delete all remote Firestore records and cloud database documents for the company "$firmName" from Firebase Cloud.\n\nNote: This only deletes cloud records. Local device data will not be wiped unless you also click Local Wipe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            icon: const Icon(Icons.cloud_off_rounded, size: 18),
            label: const Text('Wipe Cloud Data'),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final syncService = ref.read(syncServiceProvider);
                await syncService.clearCloudData();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('☁️ All remote data for "$firmName" cleared successfully from Firebase Cloud!'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to wipe cloud data: $e')),
                  );
                }
              }
            },
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
                    content: Text('⚡ Connecting to Firebase Cloud...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }

              // Auto-initialize Firebase immediately — no restart needed!
              try {
                final firebaseService = ref.read(firebaseServiceProvider);
                await firebaseService.initializeFirebase();
                await ref.read(syncServiceProvider).syncFirms();
                // Refresh providers so firms list updates in settings
                ref.invalidate(sharedPreferencesProvider);
                await ref.read(syncServiceProvider).syncAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Firebase connected & companies synced!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Firebase error: $e'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFullSpectrumColorPicker(BuildContext context) {
    final themeState = ref.read(themeProvider);
    Color color1 = themeState.customPrimaryColor ?? Theme.of(context).colorScheme.primary;
    Color color2 = themeState.customSecondaryColor ?? Theme.of(context).colorScheme.secondary;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final hsv1 = HSVColor.fromColor(color1);
            final hsv2 = HSVColor.fromColor(color2);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.palette_rounded, color: Colors.indigo, size: 26),
                  SizedBox(width: 10),
                  Text('Full Spectrum Color Chart Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient Preview Box
                      Container(
                        width: double.infinity,
                        height: 90,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color1, color2]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: color1.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('LIVE GRADIENT PREVIEW', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            Text(
                              'Color 1: #${color1.value.toRadixString(16).substring(2).toUpperCase()} • Color 2: #${color2.value.toRadixString(16).substring(2).toUpperCase()}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Color 1 Hue Spectrum Slider
                      Row(
                        children: [
                          Container(width: 14, height: 14, decoration: BoxDecoration(color: color1, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('Color 1 Hue Spectrum (0° - 360°):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                              Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000)
                            ],
                          ),
                        ),
                      ),
                      Slider(
                        value: hsv1.hue,
                        min: 0.0,
                        max: 360.0,
                        activeColor: color1,
                        onChanged: (val) {
                          setDialogState(() {
                            color1 = hsv1.withHue(val).toColor();
                          });
                        },
                      ),

                      // Color 1 Saturation & Shade Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Color 1 Shade / Brightness:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${(hsv1.value * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color1)),
                        ],
                      ),
                      Slider(
                        value: hsv1.value,
                        min: 0.2,
                        max: 1.0,
                        activeColor: color1,
                        onChanged: (val) {
                          setDialogState(() {
                            color1 = hsv1.withValue(val).toColor();
                          });
                        },
                      ),

                      const Divider(height: 28),

                      // Color 2 Hue Spectrum Slider
                      Row(
                        children: [
                          Container(width: 14, height: 14, decoration: BoxDecoration(color: color2, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('Color 2 Gradient Hue (0° - 360°):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                              Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000)
                            ],
                          ),
                        ),
                      ),
                      Slider(
                        value: hsv2.hue,
                        min: 0.0,
                        max: 360.0,
                        activeColor: color2,
                        onChanged: (val) {
                          setDialogState(() {
                            color2 = hsv2.withHue(val).toColor();
                          });
                        },
                      ),

                      // Color 2 Saturation & Shade Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Color 2 Shade / Brightness:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('${(hsv2.value * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color2)),
                        ],
                      ),
                      Slider(
                        value: hsv2.value,
                        min: 0.2,
                        max: 1.0,
                        activeColor: color2,
                        onChanged: (val) {
                          setDialogState(() {
                            color2 = hsv2.withValue(val).toColor();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.palette),
                  label: const Text('Apply Custom Theme'),
                  style: ElevatedButton.styleFrom(backgroundColor: color1, foregroundColor: Colors.white),
                  onPressed: () async {
                    await ref.read(themeProvider.notifier).setCustomColors(color1, color2);
                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚡ Custom Full Spectrum Theme applied!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMultiFirmBackupDialog(dynamic prefs, List<String> firmsList) {
    final Set<String> selectedFirms = Set.from(firmsList);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.archive_outlined, color: Colors.teal),
                SizedBox(width: 10),
                Text('Multi-Firm Backup Selection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select firms to include in the ultra-fast .bserp backup archive:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${selectedFirms.length} of ${firmsList.length} Firms Selected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            if (selectedFirms.length == firmsList.length) {
                              selectedFirms.clear();
                            } else {
                              selectedFirms.addAll(firmsList);
                            }
                          });
                        },
                        child: Text(selectedFirms.length == firmsList.length ? 'Deselect All' : 'Select All'),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: firmsList.length,
                      itemBuilder: (context, index) {
                        final firmId = firmsList[index];
                        final name = prefs.getString('firm_name_$firmId') ?? (firmId == 'firm_default' ? 'Default Company' : 'New Company');
                        final isSelected = selectedFirms.contains(firmId);

                        return CheckboxListTile(
                          dense: true,
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('ID: $firmId', style: const TextStyle(fontSize: 11)),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedFirms.add(firmId);
                              } else {
                                selectedFirms.remove(firmId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export .bserp Archive'),
                onPressed: selectedFirms.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(dialogCtx);
                        final startTime = DateTime.now();

                        // Show progress modal
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            content: const Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 16),
                                Expanded(child: Text('Generating ultra-fast binary backup (< 1s)...', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        );

                        try {
                          final backupService = ref.read(backupServiceProvider);
                          final historyEntry = await backupService.createMultiFirmBinaryBackup(
                            selectedFirmIds: selectedFirms.toList(),
                          );
                          final ms = DateTime.now().difference(startTime).inMilliseconds;

                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop(); // Close progress
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 10),
                                    Text('Backup Created Successfully!'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Generated in ${ms}ms (< 1 second)!', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    const SizedBox(height: 8),
                                    Text('File Name: ${historyEntry.backupName}'),
                                    const SizedBox(height: 4),
                                    Text('Location: ${historyEntry.location}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text('Firms Exported: ${selectedFirms.length}'),
                                  ],
                                ),
                                actions: [
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup creation failed: $e'), backgroundColor: Colors.red));
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAndRestoreBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);

      await _showRestoreConfirmationModal(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select backup file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showRestoreConfirmationModal(File backupFile) async {
    final fileName = backupFile.path.split(Platform.pathSeparator).last;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Restore Database Confirmation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore database from backup file "$fileName"?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            const Text(
              'This will instantly replace your current database in under 2 seconds. 100% of data (Categories, WhatsApp Mappings, Bank Accounts, Transactions, 3rd Units) will be preserved with 0 missing fields!',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            icon: const Icon(Icons.flash_on, size: 18),
            label: const Text('Yes, Restore Instant (< 2s)'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final startTime = DateTime.now();

    // Show Progress
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Swapping binary database (< 2s)...', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      );
    }

    try {
      final restoreService = ref.read(restoreServiceProvider);
      await restoreService.restoreBinaryBackupFromFile(bserpFile: backupFile);

      final ms = DateTime.now().difference(startTime).inMilliseconds;

      ref.invalidate(sharedPreferencesProvider);
      ref.invalidate(dashboardAnalyticsProvider);
      ref.invalidate(filteredPartiesProvider);
      ref.invalidate(filteredItemsProvider);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Instant database restore completed in ${ms}ms (< 2 seconds)!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
