import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/sync_provider.dart';
import 'package:business_sahaj_erp/presentation/providers/connectivity_provider.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';

// Import local DB models for type-casting if needed, but we check sync_queue
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';

class SyncCenterScreen extends ConsumerStatefulWidget {
  const SyncCenterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends ConsumerState<SyncCenterScreen> {
  List<SyncQueue> _queueItems = [];
  bool _isLoadingQueue = false;

  @override
  void initState() {
    super.initState();
    _refreshQueue();
  }

  Future<void> _refreshQueue() async {
    setState(() => _isLoadingQueue = true);
    try {
      final queueService = ref.read(syncQueueServiceProvider);
      final items = await queueService.getPendingQueue();
      setState(() {
        _queueItems = items;
      });
    } catch (_) {}
    setState(() => _isLoadingQueue = false);
  }

  @override
  Widget build(BuildContext context) {
    final syncStateAsync = ref.watch(syncStateProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalPending = _queueItems.length;
    final totalFailed = _queueItems.where((item) => item.retryCount >= 5).length;
    final totalRetrying = _queueItems.where((item) => item.retryCount > 0 && item.retryCount < 5).length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshQueue();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Sync Center',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitor database synchronization status and cloud queues.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Top Firebase Sync Master Control Card
              Consumer(
                builder: (context, ref, _) {
                  final prefs = ref.watch(sharedPreferencesProvider);
                  final isCloudSyncEnabled = prefs.getBool('enable_firebase_cloud_sync') ?? true;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isCloudSyncEnabled ? Colors.blue.withOpacity(0.3) : Colors.orange.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    color: isCloudSyncEnabled
                        ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCloudSyncEnabled ? Colors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCloudSyncEnabled ? Icons.cloud_sync_rounded : Icons.cloud_off_rounded,
                              color: isCloudSyncEnabled ? Colors.blue : Colors.orange.shade800,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Firebase Cloud Synchronization',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCloudSyncEnabled ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isCloudSyncEnabled ? 'ONLINE CLOUD SYNC' : '100% LOCAL STORAGE MODE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isCloudSyncEnabled ? Colors.green.shade800 : Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isCloudSyncEnabled
                                      ? 'Firebase cloud database active. All entries are auto-synced across devices.'
                                      : 'Firebase cloud sync is turned OFF. All invoices, items, and parties save exclusively to local offline storage.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Switch.adaptive(
                            value: isCloudSyncEnabled,
                            activeColor: Colors.blue,
                            onChanged: (bool val) async {
                              await prefs.setBool('enable_firebase_cloud_sync', val);
                              if (val) {
                                ref.read(syncServiceProvider).syncAll();
                              }
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? '🌐 Firebase Cloud Sync Enabled! Automatic syncing activated.'
                                        : '💾 Firebase Cloud Sync Turned OFF! Operating in 100% Local Storage Mode.',
                                  ),
                                  backgroundColor: val ? Colors.green : Colors.orange.shade800,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Re-evaluate State
              syncStateAsync.when(
                data: (syncState) {
                  final lastSyncText = syncState.lastSyncTime != null && syncState.lastSyncTime!.millisecondsSinceEpoch > 0
                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format(syncState.lastSyncTime!)
                      : 'Never';

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _buildMetricCard(
                        title: 'Last Sync',
                        value: lastSyncText,
                        icon: Icons.access_time_rounded,
                        iconColor: Colors.blue,
                      ),
                      _buildMetricCard(
                        title: 'Pending Uploads',
                        value: '$totalPending items',
                        icon: Icons.backup_outlined,
                        iconColor: Colors.orange,
                      ),
                      _buildMetricCard(
                        title: 'Failed/Blocked',
                        value: '$totalFailed items',
                        icon: Icons.error_outline_rounded,
                        iconColor: Colors.red,
                      ),
                      _buildMetricCard(
                        title: 'Pending Retries',
                        value: '$totalRetrying items',
                        icon: Icons.cached_rounded,
                        iconColor: Colors.purple,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading sync details: $err'),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: isSyncing || !isOnline
                        ? null
                        : () async {
                            await ref.read(syncServiceProvider).syncDataFromCloud();
                            await _refreshQueue();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('⚡ Remote cloud data downloaded successfully!')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_download_rounded),
                    label: const Text('Sync Data from Cloud'),
                  ),
                  ElevatedButton.icon(
                    onPressed: isSyncing || !isOnline
                        ? null
                        : () async {
                            await ref.read(syncServiceProvider).forceLocalDataToCloud();
                            await _refreshQueue();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('🚀 Local database records pushed to cloud!')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      foregroundColor: theme.colorScheme.onTertiaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Force Local Data to Cloud'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () async {
                            await ref.read(syncQueueServiceProvider).resetAllRetries();
                            await _refreshQueue();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('🔄 Sync Queue Retries reset successfully!')),
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset Retries'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Queue List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sync Queue Logs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshQueue,
                  ),
                ],
              ),
              const Divider(),

              _isLoadingQueue
                  ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
                  : _queueItems.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green[600]),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Sync Queue is Empty!',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('All changes are fully uploaded to Firebase.'),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _queueItems.length,
                          itemBuilder: (context, index) {
                            final item = _queueItems[index];
                            IconData icon;
                            Color color;

                            switch (item.operation) {
                              case 'Insert':
                                icon = Icons.add_circle_outline;
                                color = Colors.green;
                                break;
                              case 'Update':
                                icon = Icons.edit_outlined;
                                color = Colors.blue;
                                break;
                              case 'Delete':
                                icon = Icons.delete_outline;
                                color = Colors.red;
                                break;
                              default:
                                icon = Icons.help_outline;
                                color = Colors.grey;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: ListTile(
                                leading: Icon(icon, color: color),
                                title: Text('${item.entityType} (${item.operation})'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('UUID: ${item.entityUuid}'),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Retries: ${item.retryCount}/5' +
                                      (item.lastAttempt != null
                                          ? ' • Last: ${DateFormat('HH:mm:ss').format(item.lastAttempt!)}'
                                          : ''),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: item.retryCount >= 5
                                    ? Tooltip(
                                        message: 'Upload blocked. Max retries exceeded.',
                                        child: Icon(Icons.warning_amber_rounded, color: Colors.red[600]),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 24),

              // Firebase Configuration Setup Card
              Consumer(
                builder: (context, ref, _) {
                  final prefs = ref.watch(sharedPreferencesProvider);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cloud_sync_rounded, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                'Configure Firebase Cloud Connection',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Input your own Firebase connection parameters to link this app instance with your custom cloud database environment.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showFirebaseConfigDialog(prefs),
                                icon: const Icon(Icons.settings_outlined),
                                label: const Text('Configure Firebase Keys'),
                              ),
                              OutlinedButton.icon(
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
                                    try {
                                      await ref.read(syncServiceProvider).clearCloudData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Firebase data cleared successfully!')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error clearing data: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                label: const Text('Reset Firebase Data', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
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

              await prefs.setString('firebase_api_key', apiKey);
              await prefs.setString('firebase_project_id', projectId);
              await prefs.setString('firebase_app_id', appId);
              if (senderId.isNotEmpty) {
                await prefs.setString('firebase_sender_id', senderId);
              }
              if (storageBucket.isNotEmpty) {
                await prefs.setString('firebase_storage_bucket', storageBucket);
              }

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚡ Connecting to Firebase Cloud Database...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }

              // Trigger immediate live re-initialization & firm sync
              try {
                final firebaseService = ref.read(firebaseServiceProvider);
                await firebaseService.initializeFirebase();
                final syncService = ref.read(syncServiceProvider);
                await syncService.syncFirms();
                await syncService.syncAll();
                await _refreshQueue();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Firebase connected & remote firms synced successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Firebase connection error: $e'),
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
                }
              }
            },
            child: const Text('Save & Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
