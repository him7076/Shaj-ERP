import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/features/reports/presentation/providers/report_providers.dart';
import 'package:business_sahaj_erp/features/parties/presentation/providers/party_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';
import 'package:business_sahaj_erp/core/services/snapshot_backup_service.dart';

class SnapshotBackupScreen extends ConsumerStatefulWidget {
  const SnapshotBackupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SnapshotBackupScreen> createState() => _SnapshotBackupScreenState();
}

class _SnapshotBackupScreenState extends ConsumerState<SnapshotBackupScreen> {
  bool _isCreatingBackup = false;
  bool _isRestoringBackup = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Snapshot Backup & Restore'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sd_storage_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Full Database Snapshot (.sahaj)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fast, zero-data-loss, cross-compatible binary snapshot backup & instant restoration across Mobile and Web.',
                          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Export Section Card
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
                            color: Colors.teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.upload_file_rounded, color: Colors.teal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Export Full Snapshot Archive',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Captures the entire active database into a portable `.sahaj` archive containing database tables and system manifest. Perfect for offline archiving or migrating to another device.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isCreatingBackup
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(_isCreatingBackup ? 'Generating Snapshot...' : 'Export .sahaj Snapshot', style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isCreatingBackup ? null : () => _exportSnapshotBackup(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Restore Section Card
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
                          child: const Icon(Icons.settings_backup_restore_rounded, color: Colors.indigo, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Restore Snapshot Database',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Select any valid `.sahaj` file from your device or browser to instantly replace local database tables with 100% data preservation.',
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
                        icon: _isRestoringBackup
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.folder_open_rounded, size: 18),
                        label: Text(_isRestoringBackup ? 'Restoring Database...' : 'Select & Restore .sahaj File', style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isRestoringBackup ? null : () => _pickAndRestoreSnapshotFile(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSnapshotBackup() async {
    setState(() => _isCreatingBackup = true);
    final startTime = DateTime.now();

    try {
      final snapshotService = ref.read(snapshotBackupServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      final sharedPrefs = ref.read(sharedPreferencesProvider);

      final result = await snapshotService.createSnapshotBackup(
        dbService: dbService,
        prefs: sharedPrefs,
      );

      final ms = DateTime.now().difference(startTime).inMilliseconds;

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Snapshot Exported!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generated in ${ms}ms!', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                Text('File Name: ${result.fileName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Location: ${result.filePath}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Size: ${(result.byteSize / 1024).toStringAsFixed(1)} KB'),
              ],
            ),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export snapshot: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _pickAndRestoreSnapshotFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final selectedFile = result.files.single;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Confirm Database Restore'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Restore database from snapshot "${selectedFile.name}"?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              const Text(
                'This will replace your database with 100% data preservation! Current data will be safely backed up before replacement.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              icon: const Icon(Icons.flash_on, size: 18),
              label: const Text('Yes, Restore Database'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isRestoringBackup = true);
      final startTime = DateTime.now();

      final snapshotService = ref.read(snapshotBackupServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      final sharedPrefs = ref.read(sharedPreferencesProvider);

      if (kIsWeb) {
        if (selectedFile.bytes == null) {
          throw Exception('Web file bytes empty.');
        }
        await snapshotService.restoreSnapshotBackupFromBytes(
          bytes: selectedFile.bytes!,
          dbService: dbService,
          prefs: sharedPrefs,
        );
      } else {
        if (selectedFile.path == null) {
          throw Exception('File path empty.');
        }
        await snapshotService.restoreSnapshotBackupFromFile(
          sahajFile: File(selectedFile.path!),
          dbService: dbService,
          prefs: sharedPrefs,
        );
      }

      final ms = DateTime.now().difference(startTime).inMilliseconds;

      ref.invalidate(sharedPreferencesProvider);
      ref.invalidate(dashboardAnalyticsProvider);
      ref.invalidate(filteredPartiesProvider);
      ref.invalidate(filteredItemsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Complete database snapshot restore finished successfully in ${ms}ms!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoringBackup = false);
    }
  }
}
