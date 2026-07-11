import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/backup/presentation/providers/backup_providers.dart';
import 'package:business_sahaj_erp/features/backup/presentation/screens/restore_screen.dart';
import 'package:business_sahaj_erp/domain/models/backup_history_entry.dart';

class BackupHistoryScreen extends ConsumerStatefulWidget {
  const BackupHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BackupHistoryScreen> createState() => _BackupHistoryScreenState();
}

class _BackupHistoryScreenState extends ConsumerState<BackupHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Refresh lists on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupHistoryNotifierProvider.notifier).loadHistory();
      ref.read(googleDriveNotifierProvider.notifier).fetchCloudBackups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes / 1024).floor();
    var count = 0;
    while (bytes >= 1024 && count < suffixes.length - 1) {
      bytes = (bytes / 1024).floor();
      count++;
    }
    return "$bytes ${suffixes[count]}";
  }

  void _localUploadToCloud(BackupHistoryEntry entry) async {
    final driveNotifier = ref.read(googleDriveNotifierProvider.notifier);
    final theme = Theme.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Uploading backup archive to Google Drive...'),
          ],
        ),
      ),
    );

    try {
      final file = File(entry.location);
      if (await file.exists()) {
        await driveNotifier.uploadLocalFile(file, entry.backupName);
        if (mounted) Navigator.pop(context); // Close dialog

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.colorScheme.primaryContainer,
              content: Text(
                'Successfully synced to Google Drive!',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
        throw Exception('Backup file does not exist locally.');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.errorContainer,
            content: Text(
              'Upload failed: $e',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        );
      }
    }
  }

  void _confirmDelete(BackupHistoryEntry entry) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: Text('Are you sure you want to permanently delete "${entry.backupName}"? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (entry.isCloud) {
        final driveNotifier = ref.read(googleDriveNotifierProvider.notifier);
        await driveNotifier.deleteCloudFile(entry.location);
      } else {
        final historyNotifier = ref.read(backupHistoryNotifierProvider.notifier);
        await historyNotifier.deleteBackup(entry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(backupHistoryNotifierProvider);
    final driveState = ref.watch(googleDriveNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Local Storage'),
            Tab(text: 'Google Drive'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Local Storage Tab
          RefreshIndicator(
            onRefresh: () => ref.read(backupHistoryNotifierProvider.notifier).loadHistory(),
            child: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return _buildEmptyState('No local backups found.', Icons.folder_off_outlined);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return _buildBackupCard(entry, isCloud: false);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading history: $err')),
            ),
          ),

          // Google Drive Tab
          RefreshIndicator(
            onRefresh: () => ref.read(googleDriveNotifierProvider.notifier).fetchCloudBackups(),
            child: !driveState.isSignedIn
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          const Text(
                            'Google Drive Disconnected',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please connect your Google Account in Backup settings to view cloud backups.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : driveState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : driveState.cloudBackups.isEmpty
                        ? _buildEmptyState('No cloud backups found.', Icons.cloud_queue_rounded)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: driveState.cloudBackups.length,
                            itemBuilder: (context, index) {
                              final entry = driveState.cloudBackups[index];
                              return _buildBackupCard(entry, isCloud: true);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                text,
                style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackupCard(BackupHistoryEntry entry, {required bool isCloud}) {
    final theme = Theme.of(context);
    final dateText = DateFormat('yyyy-MM-dd HH:mm').format(entry.date);
    final driveState = ref.watch(googleDriveNotifierProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                Expanded(
                  child: Text(
                    entry.backupName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Lock Icon indicating encryption
                if (entry.isEncrypted)
                  Icon(Icons.lock_outline_rounded, size: 18, color: Colors.blue[700])
                else
                  Icon(Icons.lock_open_rounded, size: 18, color: theme.colorScheme.outline),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  dateText,
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  _formatBytes(entry.size),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 24),

            // Actions bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Upload local backup to Cloud
                if (!isCloud && driveState.isSignedIn) ...[
                  IconButton(
                    tooltip: 'Upload to Google Drive',
                    icon: Icon(Icons.cloud_upload_rounded, color: theme.colorScheme.primary),
                    onPressed: () => _localUploadToCloud(entry),
                  ),
                  const SizedBox(width: 8),
                ],

                // Delete Button
                IconButton(
                  tooltip: 'Delete Backup',
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                  onPressed: () => _confirmDelete(entry),
                ),
                const SizedBox(width: 8),

                // Restore Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => isCloud
                            ? RestoreScreen(initialDriveId: entry.location, initialFilename: entry.backupName)
                            : RestoreScreen(initialFilePath: entry.location),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restore'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
