import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/features/backup/presentation/providers/backup_providers.dart';
import 'package:business_sahaj_erp/features/backup/presentation/screens/backup_history_screen.dart';
import 'package:business_sahaj_erp/features/backup/presentation/screens/restore_screen.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _encryptBackup = false;
  bool _includeImages = true;
  bool _uploadToCloud = false;

  @override
  void dispose() {
    _passwordController.dispose();
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

  void _triggerBackupProcess() async {
    final historyNotifier = ref.read(backupHistoryNotifierProvider.notifier);
    final theme = Theme.of(context);

    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 24),
              Text('Generating secure backup archive...'),
            ],
          ),
        );
      },
    );

    try {
      final password = _encryptBackup ? _passwordController.text : null;
      final entry = await historyNotifier.triggerBackup(
        password: password,
        includeImages: _includeImages,
        uploadToCloud: _uploadToCloud,
      );

      // Close dialog
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.primaryContainer,
            content: Text(
              'Backup Successful: ${entry.backupName} (${_formatBytes(entry.size)})',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
        );
        setState(() {
          _passwordController.clear();
          _encryptBackup = false;
        });
      }
    } catch (e) {
      // Close dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.errorContainer,
            content: Text(
              'Backup Failed: $e',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
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
        title: const Text('Backup & Recovery'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Integrity Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          historyAsync.when(
                            data: (history) {
                              if (history.isEmpty) {
                                return const Text('No backups recorded. Please create a backup.');
                              }
                              final lastBackup = history.first;
                              final dateText = DateFormat('yyyy-MM-dd HH:mm').format(lastBackup.date);
                              return Text(
                                'Last Backup: $dateText (${_formatBytes(lastBackup.size)})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                            loading: () => const Text('Loading backups status...'),
                            error: (_, __) => const Text('Error loading backup status.'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Google Drive Auth Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_to_drive_rounded,
                      color: driveState.isSignedIn ? Colors.green : theme.colorScheme.outline,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driveState.isSignedIn
                                ? 'Connected to Google Drive'
                                : 'Google Drive Backup',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            driveState.isSignedIn
                                ? '${driveState.userEmail} ${driveState.isSimulation ? "(Simulated Mode)" : ""}'
                                : 'Secure your backups in the cloud automatically.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    driveState.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () async {
                              final notifier = ref.read(googleDriveNotifierProvider.notifier);
                              if (driveState.isSignedIn) {
                                await notifier.logout();
                              } else {
                                await notifier.login();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: driveState.isSignedIn
                                  ? theme.colorScheme.surfaceVariant
                                  : theme.colorScheme.primary,
                              foregroundColor: driveState.isSignedIn
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onPrimary,
                              elevation: 0,
                            ),
                            child: Text(driveState.isSignedIn ? 'Disconnect' : 'Connect'),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Configurations Header
            Text(
              'Backup Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Options Checklist
            SwitchListTile(
              title: const Text('Include product/logo media images'),
              subtitle: const Text('Adds images directory to compressed archive'),
              value: _includeImages,
              onChanged: (val) {
                setState(() => _includeImages = val);
              },
            ),
            SwitchListTile(
              title: const Text('Auto-sync backup to cloud'),
              subtitle: const Text('Uploads to Google Drive automatically on creation'),
              value: _uploadToCloud,
              onChanged: driveState.isSignedIn
                  ? (val) {
                      setState(() => _uploadToCloud = val);
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('Secure backup file with password'),
              subtitle: const Text('Applies AES-256 encryption algorithm'),
              value: _encryptBackup,
              onChanged: (val) {
                setState(() {
                  _encryptBackup = val;
                  if (!val) _passwordController.clear();
                });
              },
            ),

            if (_encryptBackup) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Backup Password',
                  hintText: 'Enter secret password to encrypt file',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.password_rounded),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Main Actions Buttons
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _encryptBackup && _passwordController.text.trim().isEmpty
                    ? null
                    : _triggerBackupProcess,
                icon: const Icon(Icons.backup_rounded),
                label: const Text('Create Local Backup (.bserp)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BackupHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('View History'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RestoreScreen()),
                      );
                    },
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore Data'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
