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
  bool _wasOffline = false;
  bool? _lastIsOnline;

  // Static singleton so repositories can trigger upload from anywhere without DI
  static SyncManager? _instance;

  /// Triggers a debounced background upload. Call this after any local save.
  /// Safe to call even if SyncManager is not yet initialized (no-op).
  static void triggerUpload() {
    Future.microtask(() {
      try {
        _instance?.onLocalSave();
      } catch (_) {}
    });
  }

  SyncManager(this._syncService, this._queueService);

  /// Initializes all background sync listeners and timers
  void initialize() {
    logger.info('Initializing SyncManager background loops...');
    // Register static instance so repositories can trigger uploads
    _instance = this;

    // 1. Trigger pending upload on app startup if offline changes exist
    _triggerStartupSync();

    // 2. Monitor Internet connectivity changes to trigger FULL bidirectional sync on reconnect
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      
      // Prevent rapid fire loops from connectivity_plus bug causing UI starvation
      if (_lastIsOnline == isOnline) return;
      _lastIsOnline = isOnline;
      
      logger.info('Connectivity changed. Device is ${isOnline ? "Online" : "Offline"}');
      
      if (!isOnline) {
        _wasOffline = true;
      }
      
      if (isOnline && _wasOffline) {
        _wasOffline = false;
        logger.info('Connectivity recovered after offline. Running full bidirectional sync...');
        // Full sync: uploads local changes AND downloads remote changes
        _syncService.syncAll();
      } else if (isOnline) {
        // Quick upload of pending changes if we were already online
        _syncService.syncPendingChangesQuietly();
      }
    });

    // 3. Periodic Quiet Background Upload Timer (Every 30 minutes)
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      logger.info('Background upload timer fired. Uploading pending local changes...');
      _syncService.syncPendingChangesQuietly();
    });

    // 4. Retry Backoff Poller (Every 5 minutes — reduced from 60s to avoid competing with UI thread)
    _retryTimer = Timer.periodic(const Duration(seconds: 300), (timer) {
      _checkAndTriggerRetries();
    });
  }

  void _triggerStartupSync() {
    // Delay 10 seconds after boot so UI & dashboard render instantly first
    // Before: 3s was too aggressive, sync DB operations competed with UI thread
    Future.delayed(const Duration(seconds: 10), () {
      Connectivity().checkConnectivity().then((results) {
        final isOnline = results.any((result) => result != ConnectivityResult.none);
        if (isOnline) {
          logger.info('Initial online connectivity detected. Uploading pending local changes...');
          _syncService.syncPendingChangesQuietly();
        }
      }).catchError((e) {
        logger.warning('Connectivity check failed on startup: $e');
      });
    });
  }

  /// Called by repository save/update/delete methods to trigger real-time cloud upload.
  /// Debounced internally by SyncService to batch rapid saves.
  void onLocalSave() {
    _syncService.syncPendingChangesQuietly(delay: const Duration(seconds: 1));
  }

  /// Iterates through failed queue items, checking backoff schedules
  Future<void> _checkAndTriggerRetries() async {
    // Skip DB query entirely if a sync is already running to avoid lock contention
    if (_syncService.currentState.status == SyncStatus.syncing) return;

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

  /// Call this when user switches to a different firm.
  /// Clears stale timestamps for the new firm so a full fresh download happens.
  Future<void> handleFirmSwitch(String newFirmId) async {
    logger.info('Firm switched to: $newFirmId. Clearing stale timestamps and triggering full cloud download...');
    await _syncService.clearAllFirmTimestamps(newFirmId);
    // Give DB time to switch
    await Future.delayed(const Duration(milliseconds: 500));
    await _syncService.syncDataFromCloud();
  }

  /// Cancels all background schedules on disposal
  void dispose() {
    _instance = null;
    _autoSyncTimer?.cancel();
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    logger.info('SyncManager background loops stopped.');
  }
}
