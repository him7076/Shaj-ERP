import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:business_sahaj_erp/core/services/sync_service.dart';
import 'package:business_sahaj_erp/core/services/sync_queue_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class SyncManager {
  final SyncService _syncService;
  final SyncQueueService _queueService;
  
  Timer? _autoSyncTimer;
  Timer? _retryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncManager(this._syncService, this._queueService);

  /// Initializes all background sync listeners and timers
  void initialize() {
    logger.info('Initializing SyncManager background loops...');

    // 1. Trigger sync on app startup (if online)
    _triggerStartupSync();

    // 2. Monitor Internet connectivity changes to trigger sync on reconnect
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      logger.info('Connectivity changed. Device is ${isOnline ? "Online" : "Offline"}');
      
      if (isOnline) {
        logger.info('Connectivity recovered. Triggering auto-sync...');
        _syncService.syncAll();
      }
    });

    // 3. Periodic Auto-Sync Timer (Every 5 minutes)
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      logger.info('Auto-sync timer fired. Starting sync cycle...');
      _syncService.syncAll();
    });

    // 4. Retry Backoff Poller (Every 60 seconds)
    _retryTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkAndTriggerRetries();
    });
  }

  void _triggerStartupSync() {
    // Check initial connectivity and run sync if online
    Connectivity().checkConnectivity().then((results) {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      if (isOnline) {
        logger.info('Initial online connectivity detected. Running startup sync...');
        _syncService.syncAll();
      }
    });
  }

  /// Iterates through failed queue items, checking backoff schedules
  Future<void> _checkAndTriggerRetries() async {
    final queueItems = await _queueService.getPendingQueue();
    if (queueItems.isEmpty) return;

    final now = DateTime.now();
    bool shouldTriggerSync = false;

    for (var item in queueItems) {
      if (item.retryCount > 0 && item.retryCount < 5 && item.lastAttempt != null) {
        // Calculate backoff delay
        Duration backoff;
        if (item.retryCount == 1) {
          backoff = const Duration(minutes: 1);
        } else if (item.retryCount == 2) {
          backoff = const Duration(minutes: 5);
        } else {
          backoff = const Duration(minutes: 15);
        }

        final nextDueTime = item.lastAttempt!.add(backoff);
        if (now.isAfter(nextDueTime)) {
          logger.info('SyncQueue item ID ${item.id} is due for retry attempt #${item.retryCount + 1}.');
          // Reset retryCount count temporarily to allow the upload process to retry uploading it
          item.retryCount = 0;
          await _queueService.updateAttempt(item, 'Triggering retry');
          shouldTriggerSync = true;
        }
      }
    }

    if (shouldTriggerSync) {
      logger.info('Found pending items due for retry. Running sync cycle...');
      _syncService.syncAll();
    }
  }

  /// Call this when a user logs in to trigger sync
  void handleUserLogin() {
    logger.info('User login detected. Triggering immediate post-login sync...');
    _syncService.syncAll();
  }

  /// Cancels all background schedules on disposal
  void dispose() {
    _autoSyncTimer?.cancel();
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    logger.info('SyncManager background loops stopped.');
  }
}
