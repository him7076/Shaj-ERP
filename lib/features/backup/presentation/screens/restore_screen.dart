import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:business_sahaj_erp/features/backup/presentation/providers/backup_providers.dart';
import 'package:business_sahaj_erp/domain/models/backup_metadata.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  final String? initialFilePath;
  final String? initialDriveId;
  final String? initialFilename;

  const RestoreScreen({
    Key? key,
    this.initialFilePath,
    this.initialDriveId,
    this.initialFilename,
  }) : super(key: key);

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  String? _selectedFilePath;
  bool _isDriveSource = false;
  String? _driveFileId;
  String? _driveFilename;

  BackupMetadata? _validatedMeta;
  bool _isValidating = false;
  String? _validationError;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();

  // Selective Restore variables
  bool _restoreParties = true;
  bool _restoreItems = true;
  bool _restoreOrders = true;
  bool _restoreInvoices = true;
  bool _restoreSettings = true;

  // Duplicate Strategy
  String _duplicateStrategy = 'replace'; // replace, merge, skip

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      _selectedFilePath = widget.initialFilePath;
      _triggerValidation();
    } else if (widget.initialDriveId != null) {
      _isDriveSource = true;
      _driveFileId = widget.initialDriveId;
      _driveFilename = widget.initialFilename;
      _triggerValidationForDrive();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  Future<void> _pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow selection of any file to let them pick .bserp
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _isDriveSource = false;
          _validatedMeta = null;
          _validationError = null;
          _passwordController.clear();
        });
        _triggerValidation();
      }
    } catch (e) {
      setState(() {
        _validationError = 'Failed to open file picker: $e';
      });
    }
  }

  Future<void> _triggerValidation() async {
    if (_selectedFilePath == null) return;
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      final progressNotifier = ref.read(restoreProgressNotifierProvider.notifier);
      final meta = await progressNotifier.validateFile(
        _selectedFilePath!,
        password: _passwordController.text,
      );
      setState(() {
        _validatedMeta = meta;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        if (e.toString().contains('password') || e.toString().contains('Password')) {
          _validationError = 'Password required or incorrect decryption key.';
        } else {
          _validationError = 'Validation failed: $e';
        }
      });
    }
  }

  Future<void> _triggerValidationForDrive() async {
    // Note: For cloud files, we download a small chunk or the file first to validate.
    // In our provider we download the entire file during actual restore,
    // so we can download it to a temp path for validation.
    if (_driveFileId == null) return;
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      final driveNotifier = ref.read(googleDriveNotifierProvider.notifier);
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/temp_validate_${_driveFilename}';
      
      await driveNotifier.downloadCloudFile(_driveFileId!, tempPath);
      setState(() {
        _selectedFilePath = tempPath;
      });
      await _triggerValidation();
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = 'Failed to validate cloud file: $e';
      });
    }
  }

  void _runRestorationProcess() async {
    final progressNotifier = ref.read(restoreProgressNotifierProvider.notifier);
    final historyNotifier = ref.read(backupHistoryNotifierProvider.notifier);
    final theme = Theme.of(context);

    // Confirmation warning dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Overwrite Database?'),
            ],
          ),
          content: Text(
            _duplicateStrategy == 'replace'
                ? 'WARNING: This will replace matching local records with the data from the backup file. This operation cannot be undone.'
                : 'This will merge backup records with local data based on version numbers. Proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: Colors.white),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Execute restore
    try {
      if (_isDriveSource) {
        await progressNotifier.restoreFromDrive(
          driveFileId: _driveFileId!,
          filename: _driveFilename!,
          password: _passwordController.text,
          restoreParties: _restoreParties,
          restoreItems: _restoreItems,
          restoreOrders: _restoreOrders,
          restoreInvoices: _restoreInvoices,
          restoreSettings: _restoreSettings,
          duplicateStrategy: _duplicateStrategy,
        );
      } else {
        await progressNotifier.runRestore(
          filePath: _selectedFilePath!,
          password: _passwordController.text,
          restoreParties: _restoreParties,
          restoreItems: _restoreItems,
          restoreOrders: _restoreOrders,
          restoreInvoices: _restoreInvoices,
          restoreSettings: _restoreSettings,
          duplicateStrategy: _duplicateStrategy,
        );
      }

      // Reload local backups list
      await historyNotifier.loadHistory();

      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Restore Successful'),
              content: const Text(
                'ERP local database has been updated. '
                'It is highly recommended to restart the app to ensure all modules refresh state.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // return to dashboard/backup screen
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.errorContainer,
            content: Text(
              'Restoration failed: $e',
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
    final restoreState = ref.watch(restoreProgressNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Backup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Source Section
            Text(
              'Select Backup Source',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isDriveSource ? Icons.cloud_download_rounded : Icons.folder_open_rounded,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isDriveSource ? 'Google Drive Cloud File' : 'Local File Picker',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isDriveSource
                                    ? (_driveFilename ?? 'Loading...')
                                    : (_selectedFilePath ?? 'No file selected'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickBackupFile,
                          style: ElevatedButton.styleFrom(elevation: 0),
                          child: const Text('Choose File'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Validation status / Password entry
            if (_isValidating) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Validating backup integrity and password...'),
                    ],
                  ),
                ),
              ),
            ] else if (_validationError != null) ...[
              Card(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 12),
                          const Text(
                            'Validation Error',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _validationError!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                      if (_validationError!.contains('Password') || _validationError!.contains('decryption')) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Enter Backup Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: _triggerValidation,
                            ),
                          ),
                          onSubmitted: (_) => _triggerValidation(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else if (_validatedMeta != null) ...[
              // Display Validated Metadata Details
              Card(
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup File Verified',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildMetaRow(
                        'Backup Date',
                        DateFormat('yyyy-MM-dd HH:mm').format(_validatedMeta!.backupDate),
                      ),
                      _buildMetaRow('Database Schema Version', 'v${_validatedMeta!.databaseVersion}'),
                      _buildMetaRow('App Target Version', _validatedMeta!.appVersion),
                      _buildMetaRow('Contains Images', _validatedMeta!.includeImages ? 'Yes' : 'No'),
                      _buildMetaRow('Encryption Lock', _validatedMeta!.hasPassword ? 'Yes (AES-256)' : 'None'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Restore Configuration Setup
              Text(
                'Restoration Strategy',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _duplicateStrategy,
                decoration: InputDecoration(
                  labelText: 'Duplicate Handling',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'replace', child: Text('Replace Existing (Overwrite Local matches)')),
                  DropdownMenuItem(value: 'merge', child: Text('Merge (Keep newest record by version)')),
                  DropdownMenuItem(value: 'skip', child: Text('Skip (Keep local, ignore backup duplicate)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _duplicateStrategy = val);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Selective Restore Checklist
              Text(
                'Select Elements to Restore',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                title: const Text('Parties & Customers'),
                value: _restoreParties,
                onChanged: (val) => setState(() => _restoreParties = val ?? false),
              ),
              CheckboxListTile(
                title: const Text('Items, Categories & Units'),
                value: _restoreItems,
                onChanged: (val) => setState(() => _restoreItems = val ?? false),
              ),
              CheckboxListTile(
                title: const Text('Sales Orders'),
                value: _restoreOrders,
                onChanged: (val) => setState(() => _restoreOrders = val ?? false),
              ),
              CheckboxListTile(
                title: const Text('Sales Invoices & Cash Bills'),
                value: _restoreInvoices,
                onChanged: (val) => setState(() => _restoreInvoices = val ?? false),
              ),
              CheckboxListTile(
                title: const Text('System Settings & Company details'),
                value: _restoreSettings,
                onChanged: (val) => setState(() => _restoreSettings = val ?? false),
              ),
              const SizedBox(height: 32),

              // Trigger Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: restoreState.status == RestoreStatus.restoring ||
                          (!_restoreParties && !_restoreItems && !_restoreOrders && !_restoreInvoices && !_restoreSettings)
                      ? null
                      : _runRestorationProcess,
                  icon: const Icon(Icons.restore_rounded),
                  label: Text(restoreState.status == RestoreStatus.restoring ? 'Restoring...' : 'Run Restoration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

              if (restoreState.status == RestoreStatus.restoring || restoreState.status == RestoreStatus.extracting) ...[
                const SizedBox(height: 24),
                LinearProgressIndicator(value: restoreState.progress),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    restoreState.message,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
