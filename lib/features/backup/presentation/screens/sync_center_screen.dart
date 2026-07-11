import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
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

              // Network Connection Banner
              Card(
                color: isOnline
                    ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                    : theme.colorScheme.errorContainer.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: isOnline ? theme.colorScheme.primary : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isOnline
                              ? 'Device is Connected. Auto-sync is active.'
                              : 'Device is Offline. All edits are being saved locally.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isOnline
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSyncing || !isOnline
                          ? null
                          : () async {
                              await ref.read(syncServiceProvider).syncAll();
                              await _refreshQueue();
                            },
                      icon: isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(isSyncing ? 'Syncing...' : 'Force Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSyncing || totalPending == 0
                          ? null
                          : () async {
                              await ref.read(syncQueueServiceProvider).resetAllRetries();
                              await ref.read(syncServiceProvider).syncAll();
                              await _refreshQueue();
                            },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reset Retries'),
                    ),
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
            ],
          ),
        ),
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
