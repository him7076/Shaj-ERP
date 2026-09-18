import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart' hide Query;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order, Settings, Transaction;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/firebase_service.dart';
import 'package:business_sahaj_erp/core/services/sync_queue_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/constants/app_constants.dart';
import 'package:business_sahaj_erp/core/utils/demo_data_seeder.dart';

// Collections
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/user_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/whatsapp_mapping_collection.dart';

enum SyncStatus { idle, syncing, success, failure }

class SyncState {
  final SyncStatus status;
  final String message;
  final DateTime? lastSyncTime;
  final double progress; // 0.0 to 1.0
  final int currentStep;
  final int totalSteps;

  const SyncState({
    required this.status,
    required this.message,
    this.lastSyncTime,
    this.progress = 0.0,
    this.currentStep = 0,
    this.totalSteps = 0,
  });

  int get percentage => (progress * 100).clamp(0, 100).toInt();

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSyncTime,
    double? progress,
    int? currentStep,
    int? totalSteps,
  }) {
    return SyncState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }
}

class SyncService {
  final FirebaseService _firebaseService;
  final SyncQueueService _queueService;
  final DatabaseService _dbService;
  final SharedPreferences _prefs;

  /// Helper to fetch items from Isar in chunks to avoid blocking the Web Wasm thread
  Future<List<T>> _chunkedFindAll<T>(Future<List<T>> Function(int offset, int limit) queryFn) async {
    final List<T> results = [];
    int offset = 0;
    const int limit = 500;
    while(true) {
      final chunk = await queryFn(offset, limit);
      if (chunk.isEmpty) break;
      results.addAll(chunk);
      offset += limit;
      await Future.delayed(const Duration(milliseconds: 10));
    }
    return results;
  }

  final _stateController = StreamController<SyncState>.broadcast();
  bool _isRecalculating = false; // Lock flag to prevent concurrent stock recalculations
  SyncState _currentState = const SyncState(
    status: SyncStatus.idle,
    message: 'System ready for sync',
  );
  DateTime _lastSyncCompleteTime = DateTime.fromMillisecondsSinceEpoch(0);

  SyncService(
    this._firebaseService,
    this._queueService,
    this._dbService,
    this._prefs,
  ) {
    _currentState = SyncState(
      status: SyncStatus.idle,
      message: 'System ready for sync',
      lastSyncTime: _loadLastSyncTime(),
    );
    _stateController.add(_currentState);
  }

  Stream<SyncState> get syncStateStream => _stateController.stream;
  SyncState get currentState => _currentState;

  void _updateState(SyncState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  DateTime _loadLastSyncTime() {
    final activeFirmId = _dbService.activeFirmId;
    final timestamp = _prefs.getInt('${AppConstants.keyLastSyncTime}_$activeFirmId') ?? _prefs.getInt(AppConstants.keyLastSyncTime);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    final activeFirmId = _dbService.activeFirmId;
    await _prefs.setInt('${AppConstants.keyLastSyncTime}_$activeFirmId', time.millisecondsSinceEpoch);
    _currentState = _currentState.copyWith(lastSyncTime: time);
  }

  /// Clears ALL per-entity cloud sync timestamps for a given firm.
  /// Call this on firm switch or before force-full-download so incremental filters are reset.
  Future<void> clearAllFirmTimestamps(String firmId) async {
    final allEntityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 'Transaction',
      'BankAccount', 'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem',
      'StockAdjustment', 'WhatsAppMapping',
    ];
    for (final et in allEntityTypes) {
      await _prefs.remove('last_cloud_sync_timestamp_${firmId}_$et');
      // Also clear legacy non-firm-specific keys
      await _prefs.remove('last_cloud_sync_timestamp_$et');
    }
    await _prefs.remove('${AppConstants.keyLastSyncTime}_$firmId');
    logger.info('Cleared all sync timestamps for firm: $firmId');
  }

  /// Synchronizes company/firm definitions with Firestore `firms` collection
  Future<List<String>> syncFirms() async {
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) {
      logger.warning('Skipping firm sync: Firebase not authenticated.');
      return _prefs.getStringList('firms_list') ?? ['firm_default'];
    }

    try {
      logger.info('Syncing company/firm definitions with Firebase Firestore...');
      final companyId = _firebaseService.companyId;

      // 1. Download remote firms from Firestore with 5s timeout
      final querySnapshot = await _firebaseService.firestore
          .collection('firms')
          .where('companyId', isEqualTo: companyId)
          .get()
          .timeout(const Duration(seconds: 5));

      final localFirms = List<String>.from(_prefs.getStringList('firms_list') ?? ['firm_default']);
      final Set<String> updatedFirmsSet = Set.from(localFirms);
      final Set<String> remoteDeletedFirms = {};
      final Set<String> existingRemoteIds = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final firmId = data['firmId'] as String? ?? doc.id;
        final firmName = data['firmName'] as String?;
        final isDeleted = data['isDeleted'] as bool? ?? false;
        existingRemoteIds.add(firmId);

        if (isDeleted) {
          remoteDeletedFirms.add(firmId);
          updatedFirmsSet.remove(firmId);
          await _prefs.remove('firm_name_$firmId');
        } else {
          updatedFirmsSet.add(firmId);
          if (firmName != null && firmName.isNotEmpty) {
            await _prefs.setString('firm_name_$firmId', firmName);
          }
        }
      }

      if (updatedFirmsSet.isEmpty) {
        updatedFirmsSet.add('firm_default');
      }

      final updatedFirmsList = updatedFirmsSet.toList();

      // 2. Upload local firms to Firestore ONLY if missing in Firestore and NOT deleted remotely
      final batch = _firebaseService.firestore.batch();
      bool hasUploads = false;

      for (var firmId in updatedFirmsList) {
        if (existingRemoteIds.contains(firmId) || remoteDeletedFirms.contains(firmId)) {
          continue; // Do NOT overwrite existing remote firms or resurrect deleted firms!
        }
        final isFirmSyncEnabled = _prefs.getBool('enable_firm_sync_$firmId') ?? true;
        if (!isFirmSyncEnabled) {
          continue; // Do NOT auto-upload local firm definition to cloud if firm sync toggle is OFF!
        }

        final firmName = _prefs.getString('firm_name_$firmId') ??
            (firmId == 'firm_default' ? 'Default Company' : 'New Company');

        final docRef = _firebaseService.firestore.collection('firms').doc(firmId);
        batch.set(
          docRef,
          {
            'firmId': firmId,
            'firmName': firmName,
            'companyId': companyId,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'isDeleted': false,
            'lastModifiedBy': _firebaseService.currentUserEmail ?? 'admin@sahaj.com',
          },
          SetOptions(merge: true),
        );
        hasUploads = true;
      }

      if (hasUploads) {
        await batch.commit();
      }

      await _prefs.setStringList('firms_list', updatedFirmsList);
      logger.info('Firm definitions synced successfully: $updatedFirmsList');
      return updatedFirmsList;
    } catch (e, stackTrace) {
      logger.error('Failed to sync firms with Firestore', e, stackTrace);
      return _prefs.getStringList('firms_list') ?? ['firm_default'];
    }
  }

  /// Mark firm document as isDeleted: true in Firestore
  Future<void> deleteRemoteFirm(String firmId) async {
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) return;
    try {
      final docRef = _firebaseService.firestore.collection('firms').doc(firmId);
      await docRef.set({
        'firmId': firmId,
        'companyId': _firebaseService.companyId,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
        'lastModifiedBy': _firebaseService.currentUserEmail ?? 'admin@sahaj.com',
      }, SetOptions(merge: true));
      logger.info('Marked firm $firmId as isDeleted: true in Firestore.');
    } catch (e) {
      logger.error('Failed to mark firm $firmId as deleted in Firestore', e);
    }
  }

  Timer? _quietSyncDebounceTimer;
  bool _isUploadingQuietly = false;

  /// Non-blocking, debounced background queue upload.
  /// Batches multiple rapid saves into a single background upload cycle,
  /// preventing browser freezes, event-loop starvation, and Isar DB lock contention.
  void syncPendingChangesQuietly({Duration delay = const Duration(seconds: 2)}) {
    // Early abort to save CPU and event loop if sync is entirely off
    if (!_firebaseService.isSyncConfigured) return;
    final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
    if (!cloudSyncEnabled) return;
    final activeFirmId = _dbService.activeFirmId;
    final isFirmSyncEnabled = _prefs.getBool('enable_firm_sync_$activeFirmId') ?? true;
    if (!isFirmSyncEnabled) return;

    _quietSyncDebounceTimer?.cancel();
    _quietSyncDebounceTimer = Timer(delay, () async {
      if (_currentState.status == SyncStatus.syncing) return;
      if (_isUploadingQuietly) return; // Prevent concurrent quiet uploads
      // Cooldown: skip if a full syncAll just completed within last 5 seconds
      if (DateTime.now().difference(_lastSyncCompleteTime).inSeconds < 5) return;

      _isUploadingQuietly = true;
      try {
        await _firebaseService.ensureAuthenticated();
        if (_firebaseService.isAuthenticated) {
          await _uploadLocalChanges(silent: true);
        }
      } catch (e) {
        logger.warning('Quiet background upload encountered non-fatal error: $e');
      } finally {
        _isUploadingQuietly = false;
      }
    });
  }

  /// Triggers full synchronization of all collections: upload edits, download changes, resolve conflicts
  Future<void> syncAll() async {
    if (!_firebaseService.isSyncConfigured) {
      logger.info('Firebase keys not configured in Sync Center. Bypassing cloud sync.');
      _updateState(const SyncState(
        status: SyncStatus.idle,
        message: 'Local Offline Mode (Firebase Not Configured)',
      ));
      return;
    }

    final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
    if (!cloudSyncEnabled) {
      logger.info('Firebase Cloud Sync is turned OFF by user. Bypassing cloud sync.');
      _updateState(const SyncState(
        status: SyncStatus.idle,
        message: 'Local Storage Mode Active (Cloud Sync OFF)',
      ));
      return;
    }

    final activeFirmId = _dbService.activeFirmId;
    final isFirmSyncEnabled = _prefs.getBool('enable_firm_sync_$activeFirmId') ?? true;
    if (!isFirmSyncEnabled) {
      logger.info('Cloud sync is OFF for active firm ($activeFirmId). Bypassing cloud sync.');
      _updateState(SyncState(
        status: SyncStatus.idle,
        message: 'Firm Cloud Sync OFF for firm ($activeFirmId)',
      ));
      return;
    }

    if (_currentState.status == SyncStatus.syncing) {
      logger.warning('Sync already in progress. Ignoring request.');
      return;
    }

    await _firebaseService.ensureAuthenticated();

    if (!_firebaseService.isAuthenticated) {
      logger.warning('Bypassing sync: User not authenticated.');
      _updateState(const SyncState(
        status: SyncStatus.failure,
        message: 'Sync failed: User not logged in',
      ));
      return;
    }

    logger.info('Starting Firebase synchronization engine...');
    _updateState(SyncState(
      status: SyncStatus.syncing,
      message: 'Synchronizing with Firebase...',
      lastSyncTime: _currentState.lastSyncTime,
    ));

    try {
      // 0. Sync company/firm definitions first
      await syncFirms();

      // 1. Upload local changes to Firestore
      await _uploadLocalChanges();

      // 2. Download remote updates from Firestore via Instant Low-Quota Delta Sync Engine
      final lastSync = _currentState.lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final newSyncTime = DateTime.now();

      await _downloadDeltaRemoteUpdates(lastSync);

      // 3. Persist successful sync time
      await _saveLastSyncTime(newSyncTime);
      
      // 4. Log successful synchronization
      await _logSyncEvent('Success', 'Full sync completed successfully.');

      logger.info('Firebase sync cycle completed successfully.');
      _lastSyncCompleteTime = DateTime.now();
      _updateState(SyncState(
        status: SyncStatus.success,
        message: 'Sync completed successfully (100%)',
        lastSyncTime: newSyncTime,
        progress: 1.0,
        currentStep: 22,
        totalSteps: 22,
      ));
    } catch (e, stackTrace) {
      logger.error('Firebase synchronization failed', e, stackTrace);
      await _logSyncEvent('Failure', 'Sync cycle failed: $e');
      
      _updateState(SyncState(
        status: SyncStatus.failure,
        message: 'Sync failed: ${e.toString()}',
        lastSyncTime: _currentState.lastSyncTime,
      ));
      rethrow;
    }
  }

  /// Downloads remote updates from Firestore into local Isar DB (Pull Cloud -> Local)
  /// Safety Action: Wipes local DB for the active firm first, then pulls ALL cloud data freshly!
  Future<void> syncDataFromCloud() async {
    final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
    if (!cloudSyncEnabled) {
      _updateState(const SyncState(
        status: SyncStatus.idle,
        message: 'Local Storage Mode Active (Cloud Sync OFF)',
      ));
      return;
    }

    if (_currentState.status == SyncStatus.syncing) return;
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) return;

    logger.info('Purging local database and downloading fresh data from Firebase Cloud...');
    _updateState(SyncState(
      status: SyncStatus.syncing,
      message: 'Purging local DB & Downloading fresh Cloud data...',
      lastSyncTime: _currentState.lastSyncTime,
    ));

    try {
      // 1. Clear ALL sync timestamps (main + per-entity) so incremental filter is FULLY disabled.
      //    This is critical — stale entity timestamps cause filterCutoff to block full download!
      //    NOTE: We NEVER purge local DB here — existing local offline data must be preserved!
      final activeFirmId = _dbService.activeFirmId;
      await _prefs.remove('${AppConstants.keyLastSyncTime}_$activeFirmId');
      await _prefs.remove(AppConstants.keyLastSyncTime);

      // Clear all firm-specific per-entity timestamps to force full fresh download
      final allEntityTypes = [
        'Category', 'Unit', 'Brand', 'Party', 'Item',
        'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
        'Purchase', 'PurchaseItem', 'Expense', 'ExpenseItem', 'Transaction',
        'BankAccount', 'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem',
        'StockAdjustment', 'WhatsAppMapping',
      ];
      for (final et in allEntityTypes) {
        // Clear both old non-firm-specific keys AND new firm-specific keys
        await _prefs.remove('last_cloud_sync_timestamp_$et');
        await _prefs.remove('last_cloud_sync_timestamp_${activeFirmId}_$et');
      }
      logger.info('Cleared all entity-level sync timestamps for firm: $activeFirmId — forcing full fresh download.');

      // 3. Re-seed standard commercial units in local DB
      await DemoDataSeeder.seedStandardUnits(_dbService);

      // 4. Download remote firm definitions & all Firestore collections for active firm
      await syncFirms();
      final epochStart = DateTime.fromMillisecondsSinceEpoch(0);
      final newSyncTime = DateTime.now();
      await _downloadRemoteUpdates(epochStart, forceFullDownload: true);
      await _saveLastSyncTime(newSyncTime);

      _updateState(SyncState(
        status: SyncStatus.success,
        message: 'Local DB purged & fresh cloud data downloaded successfully!',
        lastSyncTime: newSyncTime,
      ));
    } catch (e, stackTrace) {
      logger.error('Failed to download cloud data', e, stackTrace);
      _updateState(SyncState(
        status: SyncStatus.failure,
        message: 'Cloud download failed: ${e.toString()}',
        lastSyncTime: _currentState.lastSyncTime,
      ));
      rethrow;
    }
  }

  /// Forces all local records to be uploaded to Firebase Cloud (Push Local -> Cloud)
  /// Safety Action: Wipes cloud Firestore data for the active firm first, then pushes ALL local records!
  Future<void> forceLocalDataToCloud() async {
    final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
    if (!cloudSyncEnabled) {
      _updateState(const SyncState(
        status: SyncStatus.idle,
        message: 'Local Storage Mode Active (Cloud Sync OFF)',
      ));
      return;
    }

    if (_currentState.status == SyncStatus.syncing) return;
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) return;

    logger.info('Wiping cloud data and pushing local records to Firebase Cloud...');
    _updateState(SyncState(
      status: SyncStatus.syncing,
      message: 'Wiping cloud DB & Pushing local data to Cloud...',
      lastSyncTime: _currentState.lastSyncTime,
    ));

    try {
      // 1. Wipe remote Firestore data for active firm first
      await clearCloudDataForActiveFirm();

      // 2. Reset sync queue retries and enqueue all local records for upload
      await _queueService.resetAllRetries();
      await _enqueueAllLocalRecordsForUpload(forceAll: true);
      await _uploadLocalChanges();

      final newSyncTime = DateTime.now();
      await _saveLastSyncTime(newSyncTime);

      _updateState(SyncState(
        status: SyncStatus.success,
        message: 'Cloud data wiped & local data pushed successfully!',
        lastSyncTime: newSyncTime,
      ));
    } catch (e, stackTrace) {
      logger.error('Failed to push local data to cloud', e, stackTrace);
      _updateState(SyncState(
        status: SyncStatus.failure,
        message: 'Cloud upload failed: ${e.toString()}',
        lastSyncTime: _currentState.lastSyncTime,
      ));
      rethrow;
    }
  }

  /// Helper to enqueue unsynced or all local records into SyncQueue
  Future<void> _enqueueAllLocalRecordsForUpload({bool forceAll = false}) async {
    final uuidGen = Uuid();
    final isar = _dbService.isar;

    Future<void> processEnqueuing<T>(
        Future<List<T>> Function(int offset, int limit) queryFn,
        String entityType,
        String? Function(T) getUuid,
        int Function(T) getId) async {
      int offset = 0;
      const int limit = 500;
      while (true) {
        final chunk = await queryFn(offset, limit);
        if (chunk.isEmpty) break;
        
        final queues = chunk.map((item) => SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = entityType
          ..entityId = getId(item)
          ..entityUuid = getUuid(item)
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()).toList();

        await isar.writeTxn(() async {
          await isar.syncQueues.putAll(queues);
        });
        
        offset += limit;
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    await processEnqueuing<Party>((o, l) => forceAll ? isar.partys.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.partys.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Party', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Item>((o, l) => forceAll ? isar.items.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.items.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Item', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Invoice>((o, l) => forceAll ? isar.invoices.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.invoices.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Invoice', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Order>((o, l) => forceAll ? isar.orders.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.orders.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Order', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Purchase>((o, l) => forceAll ? isar.purchases.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.purchases.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Purchase', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<InvoiceItem>((o, l) => forceAll ? isar.invoiceItems.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.invoiceItems.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'InvoiceItem', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<PurchaseItem>((o, l) => forceAll ? isar.purchaseItems.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.purchaseItems.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'PurchaseItem', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Expense>((o, l) => forceAll ? isar.expenses.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.expenses.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Expense', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<ExpenseItem>((o, l) => isar.expenseItems.filter().idGreaterThan(-1).offset(o).limit(l).findAll().then((list) => list.where((ei) => forceAll || !ei.isSynced).toList()), 'ExpenseItem', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<StockAdjustment>((o, l) => isar.collection<StockAdjustment>().filter().idGreaterThan(-1).offset(o).limit(l).findAll().then((list) => list.where((sa) => forceAll || !sa.isSynced).toList()), 'StockAdjustment', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<CreditNote>((o, l) => isar.creditNotes.filter().idGreaterThan(-1).offset(o).limit(l).findAll().then((list) => list.where((cn) => forceAll || !cn.isSynced).toList()), 'CreditNote', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<CreditNoteItem>((o, l) => isar.creditNoteItems.filter().idGreaterThan(-1).offset(o).limit(l).findAll().then((list) => list.where((cni) => forceAll || !cni.isSynced).toList()), 'CreditNoteItem', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<WhatsAppMapping>((o, l) => isar.whatsAppMappings.filter().idGreaterThan(-1).offset(o).limit(l).findAll().then((list) => list.where((wm) => forceAll || !wm.isSynced).toList()), 'WhatsAppMapping', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<DebitNote>((o, l) => isar.debitNotes.filter().idGreaterThan(-1).offset(o).limit(l).findAll().then((list) => list.where((dn) => forceAll || !dn.isSynced).toList()), 'DebitNote', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<DebitNoteItem>((o, l) => isar.debitNoteItems.filter().idGreaterThan(-1).offset(o).limit(l).findAll().then((list) => list.where((dni) => forceAll || !dni.isSynced).toList()), 'DebitNoteItem', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Transaction>((o, l) => forceAll ? isar.transactions.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.transactions.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Transaction', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Category>((o, l) => forceAll ? isar.categorys.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.categorys.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Category', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Unit>((o, l) => forceAll ? isar.units.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.units.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Unit', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Brand>((o, l) => forceAll ? isar.brands.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.brands.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Brand', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<Settings>((o, l) => forceAll ? isar.settings.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.settings.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'Settings', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<User>((o, l) => forceAll ? isar.users.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.users.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'User', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<BankAccount>((o, l) => forceAll ? isar.bankAccounts.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.bankAccounts.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'BankAccount', (e) => e.uuid, (e) => e.id);
    await processEnqueuing<OrderItem>((o, l) => forceAll ? isar.orderItems.filter().idGreaterThan(-1).offset(o).limit(l).findAll() : isar.orderItems.filter().isSyncedEqualTo(false).offset(o).limit(l).findAll(), 'OrderItem', (e) => e.uuid, (e) => e.id);
  }

  /// Deletes or soft-deletes all documents belonging to the active company context from Firestore.
  Future<void> clearCloudData() async {
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) {
      throw StateError('Firebase authentication failed. Enable Anonymous login in console.');
    }

    final companyId = _firebaseService.companyId;
    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'Transaction', 'BankAccount',
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem', 'WhatsAppMapping'
    ];

    for (var entityType in entityTypes) {
      final collectionName = _getFirestoreCollection(entityType);
      QuerySnapshot? querySnapshot;

      try {
        querySnapshot = await _firebaseService.firestore
            .collection(collectionName)
            .where('companyId', isEqualTo: companyId)
            .get();
      } catch (e1) {
        logger.warning('Cloud wipe query for $entityType failed: $e1. Trying full collection query limit 500.');
        try {
          querySnapshot = await _firebaseService.firestore
              .collection(collectionName)
              .limit(500)
              .get();
        } catch (_) {}
      }

      if (querySnapshot == null || querySnapshot.docs.isEmpty) continue;

      try {
        // Chunk batch deletes to max 450
        for (var i = 0; i < querySnapshot.docs.length; i += 450) {
          final chunk = querySnapshot.docs.skip(i).take(450);
          final batch = _firebaseService.firestore.batch();
          for (var doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          await Future.delayed(const Duration(milliseconds: 50)); // Yield
        }
      } catch (e) {
        logger.warning('Physical batch delete failed for $entityType ($e). Falling back to soft delete...');
        try {
          for (var i = 0; i < querySnapshot.docs.length; i += 450) {
            final chunk = querySnapshot.docs.skip(i).take(450);
            final batch = _firebaseService.firestore.batch();
            for (var doc in chunk) {
              batch.set(
                doc.reference,
                {
                  'isDeleted': true,
                  'updatedAt': DateTime.now().toIso8601String(),
                },
                SetOptions(merge: true),
              );
            }
            await batch.commit();
            await Future.delayed(const Duration(milliseconds: 50)); // Yield
          }
        } catch (softErr) {
          logger.error('Soft delete fallback failed for $entityType', softErr);
        }
      }
    }

    // Reset local sync state so next sync starts fresh
    await _prefs.remove(AppConstants.keyLastSyncTime);
    _currentState = _currentState.copyWith(lastSyncTime: DateTime.fromMillisecondsSinceEpoch(0));
    _stateController.add(_currentState);
  }

  /// Deletes all documents belonging to the active firm from Firestore
  Future<void> clearCloudDataForActiveFirm() async {
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) return;

    final companyId = _firebaseService.companyId;
    final activeFirmId = _dbService.activeFirmId;
    logger.info('Wiping all remote Firestore documents for firm: $activeFirmId');

    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'Transaction', 'BankAccount',
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem', 'WhatsAppMapping'
    ];

    for (var entityType in entityTypes) {
      final collectionName = _getFirestoreCollection(entityType);
      QuerySnapshot? querySnapshot;

      try {
        querySnapshot = await _firebaseService.firestore
            .collection(collectionName)
            .where('companyId', isEqualTo: companyId)
            .where('firmId', isEqualTo: activeFirmId)
            .get();
      } catch (e1) {
        logger.warning('Primary firm wipe query failed for $entityType: $e1. Trying firmId-only query.');
        try {
          querySnapshot = await _firebaseService.firestore
              .collection(collectionName)
              .where('firmId', isEqualTo: activeFirmId)
              .get();
        } catch (e2) {
          logger.warning('Secondary firm wipe query failed for $entityType: $e2. Trying companyId query.');
          try {
            querySnapshot = await _firebaseService.firestore
                .collection(collectionName)
                .where('companyId', isEqualTo: companyId)
                .get();
          } catch (_) {}
        }
      }

      if (querySnapshot == null || querySnapshot.docs.isEmpty) continue;

      try {
        // Chunk batch deletes to max 450
        for (var i = 0; i < querySnapshot.docs.length; i += 450) {
          final chunk = querySnapshot.docs.skip(i).take(450);
          final batch = _firebaseService.firestore.batch();
          for (var doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          await Future.delayed(const Duration(milliseconds: 50)); // Yield
        }
      } catch (e) {
        logger.warning('Physical batch delete failed for firm $activeFirmId ($entityType): $e. Falling back to soft delete...');
        try {
          for (var i = 0; i < querySnapshot.docs.length; i += 450) {
            final chunk = querySnapshot.docs.skip(i).take(450);
            final batch = _firebaseService.firestore.batch();
            for (var doc in chunk) {
              batch.set(
                doc.reference,
                {
                  'isDeleted': true,
                  'updatedAt': DateTime.now().toIso8601String(),
                },
                SetOptions(merge: true),
              );
            }
            await batch.commit();
            await Future.delayed(const Duration(milliseconds: 50)); // Yield
          }
        } catch (softErr) {
          logger.error('Soft delete fallback failed for firm $activeFirmId ($entityType)', softErr);
        }
      }
    }
  }

  /// Uploads all dirty local records marked isSynced == false via batched WriteBatch (max 200 docs per batch)
  /// [silent] = true when called from background quiet sync — avoids polluting global state
  Future<void> _uploadLocalChanges({bool silent = false}) async {
    logger.info('Uploading local dirty changes to Firestore...');
    final uploadStartTime = DateTime.now();

    if (!silent) {
      _updateState(SyncState(
        status: SyncStatus.syncing,
        message: 'Checking pending queue...',
        lastSyncTime: _currentState.lastSyncTime,
        progress: 0.05,
        currentStep: 1,
        totalSteps: 22,
      ));
    }
    await Future.delayed(Duration.zero); // Yield before heavy DB work

    // NOTE: We do NOT call _enqueueAllLocalRecordsForUpload here.
    // Records are enqueued by repositories during save/update/delete.
    // The full sweep is only needed for forceLocalDataToCloud().

    final allQueueItems = await _queueService.getPendingQueue();

    if (allQueueItems.isEmpty) {
      logger.info('No pending changes to upload.');
      return;
    }

    logger.info('Found ${allQueueItems.length} queue items to process.');

    final isar = _dbService.isar;
    final List<Map<String, dynamic>> syncedItems = [];
    final List<int> completedQueueIds = [];

    // Deduplicate queue items to minimize Firebase Writes — with event-loop yielding
    if (!silent) {
      _updateState(SyncState(
        status: SyncStatus.syncing,
        message: 'Deduplicating ${allQueueItems.length} queue items...',
        lastSyncTime: _currentState.lastSyncTime,
        progress: 0.07,
        currentStep: 1,
        totalSteps: 22,
      ));
    }
    await Future.delayed(Duration.zero);

    final uniqueItemsToProcess = <String, SyncQueue>{};
    for (var i = 0; i < allQueueItems.length; i++) {
      final q = allQueueItems[i];
      if (q.retryCount >= 5) continue;
      
      final key = '${q.entityType}_${q.entityUuid}';
      if (q.operation == 'Delete') {
        if (uniqueItemsToProcess.containsKey(key)) {
          completedQueueIds.add(uniqueItemsToProcess[key]!.id);
        }
        uniqueItemsToProcess[key] = q;
      } else {
        if (uniqueItemsToProcess.containsKey(key)) {
          if (uniqueItemsToProcess[key]!.operation == 'Delete') {
             completedQueueIds.add(q.id);
          } else {
             completedQueueIds.add(uniqueItemsToProcess[key]!.id);
             uniqueItemsToProcess[key] = q;
          }
        } else {
          uniqueItemsToProcess[key] = q;
        }
      }

      // Yield every 200 items to prevent browser freeze during deduplication
      if (i % 200 == 0 && i > 0) {
        await Future.delayed(Duration.zero);
      }
    }

    final queueItems = uniqueItemsToProcess.values.toList();
    final totalItems = queueItems.length;
    logger.info('Deduplicated to $totalItems unique items for upload.');

    WriteBatch currentBatch = _firebaseService.firestore.batch();
    int batchOpsCount = 0;
    int totalUploaded = 0;
    int totalFailed = 0;
    
    List<Map<String, dynamic>> currentBatchSyncedItems = [];
    List<int> currentBatchCompletedIds = [];
    List<SyncQueue> currentBatchQueueItems = [];

    for (int i = 0; i < queueItems.length; i++) {
      final queueItem = queueItems[i];

      // Yield event loop every 5 items for responsive UI
      if (i % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
      // Update progress every 25 items
      if (i % 25 == 0 && !silent) {
        final p = 0.10 + ((i / totalItems) * 0.30); // 10% to 40% range
        _updateState(SyncState(
          status: SyncStatus.syncing,
          message: 'Uploading to cloud ($i/$totalItems)...',
          lastSyncTime: _currentState.lastSyncTime,
          progress: p,
          currentStep: 2,
          totalSteps: 22,
        ));
      }

      try {
        final entityType = queueItem.entityType!;
        final entityId = queueItem.entityId!;

        dynamic entity;
        switch (entityType) {
          case 'Party': entity = await isar.partys.get(entityId); break;
          case 'Item': entity = await isar.items.get(entityId); break;
          case 'Category': entity = await isar.categorys.get(entityId); break;
          case 'Unit': entity = await isar.units.get(entityId); break;
          case 'Brand': entity = await isar.brands.get(entityId); break;
          case 'Order': entity = await isar.orders.get(entityId); break;
          case 'OrderItem': entity = await isar.orderItems.get(entityId); break;
          case 'Invoice': entity = await isar.invoices.get(entityId); break;
          case 'InvoiceItem': entity = await isar.invoiceItems.get(entityId); break;
          case 'Settings': entity = await isar.settings.get(entityId); break;
          case 'User': entity = await isar.users.get(entityId); break;
          case 'Purchase': entity = await isar.purchases.get(entityId); break;
          case 'PurchaseItem': entity = await isar.purchaseItems.get(entityId); break;
          case 'Expense': entity = await isar.expenses.get(entityId); break;
          case 'ExpenseItem': entity = await isar.collection<ExpenseItem>().get(entityId); break;
          case 'Transaction': entity = await isar.transactions.get(entityId); break;
          case 'BankAccount': entity = await isar.bankAccounts.get(entityId); break;
          case 'CreditNote': entity = await isar.creditNotes.get(entityId); break;
          case 'CreditNoteItem': entity = await isar.creditNoteItems.get(entityId); break;
          case 'DebitNote': entity = await isar.debitNotes.get(entityId); break;
          case 'DebitNoteItem': entity = await isar.debitNoteItems.get(entityId); break;
          case 'StockAdjustment': entity = await isar.collection<StockAdjustment>().get(entityId); break;
          case 'WhatsAppMapping': entity = await isar.whatsAppMappings.get(entityId); break;
        }

        if (entity == null && queueItem.operation != 'Delete') {
          logger.warning('Sync queue item ID ${queueItem.id} not found in database. Skipping.');
          currentBatchCompletedIds.add(queueItem.id);
          continue;
        }

        final firestoreCollection = _getFirestoreCollection(entityType);
        final docRef = _firebaseService.firestore.collection(firestoreCollection).doc(queueItem.entityUuid);

        if (queueItem.operation == 'Delete') {
          currentBatch.delete(docRef);
        } else {
          final map = await _mapEntityToMap(entityType, entity);
          currentBatch.set(docRef, map, SetOptions(merge: true));
        }

        batchOpsCount++;
        if (entity != null) {
          currentBatchSyncedItems.add({'entityType': entityType, 'entity': entity});
        }
        currentBatchCompletedIds.add(queueItem.id);
        currentBatchQueueItems.add(queueItem);
      } catch (e) {
        logger.error('Failed to map queue item ID ${queueItem.id}', e);
        await _queueService.updateAttempt(queueItem, e.toString());
        totalFailed++;
      }

      // Commit WriteBatch if 200 items reached OR if it's the last item
      if (batchOpsCount >= 200 || (i == queueItems.length - 1 && batchOpsCount > 0)) {
        try {
          if (!silent) {
            _updateState(SyncState(
              status: SyncStatus.syncing,
              message: 'Committing batch to Firebase ($totalUploaded/$totalItems)...',
              lastSyncTime: _currentState.lastSyncTime,
              progress: 0.10 + ((i / totalItems) * 0.30),
              currentStep: 2,
              totalSteps: 22,
            ));
          }
          await currentBatch.commit().timeout(const Duration(seconds: 30));
          totalUploaded += batchOpsCount;
          // Only if commit succeeds, we add them to the global lists to be marked as synced locally
          syncedItems.addAll(currentBatchSyncedItems);
          completedQueueIds.addAll(currentBatchCompletedIds);
          logger.info('Batch committed: $batchOpsCount items (total: $totalUploaded/$totalItems)');
        } catch (e) {
          logger.error('Failed committing write batch to Firestore. Continuing with next batch...', e);
          totalFailed += currentBatchQueueItems.length;
          // Mark attempts for all items in this failed batch
          for (var q in currentBatchQueueItems) {
            await _queueService.updateAttempt(q, e.toString());
          }
          // NON-FATAL: Continue with remaining batches instead of aborting entire sync
        }

        // Reset batch state
        currentBatch = _firebaseService.firestore.batch();
        batchOpsCount = 0;
        currentBatchSyncedItems.clear();
        currentBatchCompletedIds.clear();
        currentBatchQueueItems.clear();
        await Future.delayed(const Duration(milliseconds: 50)); // Brief pause between batches
      }
    }

    // Mark synced items in local DB — chunked with yields
    if (!silent) {
      _updateState(SyncState(
        status: SyncStatus.syncing,
        message: 'Updating local sync status ($totalUploaded items)...',
        lastSyncTime: _currentState.lastSyncTime,
        progress: 0.42,
        currentStep: 3,
        totalSteps: 22,
      ));
    }

    if (syncedItems.isNotEmpty || completedQueueIds.isNotEmpty) {
      if (syncedItems.isNotEmpty) {
        for (var i = 0; i < syncedItems.length; i += 200) {
          final chunk = syncedItems.skip(i).take(200);
          await isar.writeTxn(() async {
            for (var itemMap in chunk) {
              final entityType = itemMap['entityType'] as String;
              final entity = itemMap['entity'];
              entity.isSynced = true;
              switch (entityType) {
                case 'Party': await isar.partys.put(entity as Party); break;
                case 'Item': await isar.items.put(entity as Item); break;
                case 'Category': await isar.categorys.put(entity as Category); break;
                case 'Unit': await isar.units.put(entity as Unit); break;
                case 'Brand': await isar.brands.put(entity as Brand); break;
                case 'Order': await isar.orders.put(entity as Order); break;
                case 'Invoice': await isar.invoices.put(entity as Invoice); break;
                case 'Settings': await isar.settings.put(entity as Settings); break;
                case 'User': await isar.users.put(entity as User); break;
                case 'Purchase': await isar.purchases.put(entity as Purchase); break;
                case 'Expense': await isar.expenses.put(entity as Expense); break;
                case 'Transaction': await isar.transactions.put(entity as Transaction); break;
                case 'BankAccount': await isar.bankAccounts.put(entity as BankAccount); break;
                case 'CreditNote': await isar.creditNotes.put(entity as CreditNote); break;
                case 'DebitNote': await isar.debitNotes.put(entity as DebitNote); break;
                case 'WhatsAppMapping': await isar.whatsAppMappings.put(entity as WhatsAppMapping); break;
              }
            }
          });
          await Future.delayed(const Duration(milliseconds: 20)); // Yield between DB chunks
        }
      }

      if (completedQueueIds.isNotEmpty) {
        for (var i = 0; i < completedQueueIds.length; i += 200) {
          final chunk = completedQueueIds.skip(i).take(200).toList();
          await isar.writeTxn(() async {
            await isar.syncQueues.deleteAll(chunk);
          });
          await Future.delayed(const Duration(milliseconds: 20)); // Yield
        }
      }

      // Atomic Queue Clearing before upload start time to prevent clearing edits made during upload
      await _queueService.removeQueueItemsBefore(uploadStartTime);

      logger.info('Upload complete: $totalUploaded succeeded, $totalFailed failed out of $totalItems items.');
    }
  }

  /// INSTANT LOW-QUOTA DELTA SYNC ENGINE
  /// Downloads and reconciles remote updates modified after lastSync (where updatedAt > lastSyncTimestamp)
  Future<void> _downloadDeltaRemoteUpdates(DateTime lastSync) async {
    await _downloadRemoteUpdates(lastSync, forceFullDownload: false);
  }

  /// Downloads and reconciles remote updates since lastSync (Pull Cloud -> Local)
  /// [forceFullDownload] = true: ignores all per-entity timestamps, downloads everything.
  Future<void> _downloadRemoteUpdates(DateTime lastSync, {bool forceFullDownload = false}) async {
    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'Invoice', 'Settings', 'User',
      'Purchase', 'Expense', 'ExpenseItem', 'Transaction', 'BankAccount',
      'CreditNote', 'DebitNote', 'StockAdjustment', 'WhatsAppMapping'
    ];
    final activeFirmId = _dbService.activeFirmId;
    final companyId = _firebaseService.companyId;
    final totalSteps = entityTypes.length + 2;

    logger.info('Starting _downloadRemoteUpdates: firm=$activeFirmId, companyId=$companyId, forceFullDownload=$forceFullDownload');

    for (int i = 0; i < entityTypes.length; i++) {
      final entityType = entityTypes[i];
      final stepIndex = i + 2;
      final progress = stepIndex / totalSteps;
      final percentage = (progress * 100).toInt();

      _updateState(SyncState(
        status: SyncStatus.syncing,
        message: 'Syncing $entityType ($percentage%)...',
        lastSyncTime: _currentState.lastSyncTime,
        progress: progress,
        currentStep: stepIndex,
        totalSteps: totalSteps,
      ));

      final collectionName = _getFirestoreCollection(entityType);
      // Use firm-specific timestamp key to prevent cross-firm pollution
      final timestampKey = 'last_cloud_sync_timestamp_${activeFirmId}_$entityType';
      logger.info('Downloading $collectionName (firm: $activeFirmId, companyId: $companyId)...');

      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // Determine filterCutoff — ONLY for incremental sync, NEVER for forceFullDownload
        DateTime? filterCutoff;
        if (!forceFullDownload) {
          final String? lastCloudSyncStr = prefs.getString(timestampKey);
          if (lastCloudSyncStr != null && lastCloudSyncStr.isNotEmpty) {
            final parsed = DateTime.tryParse(lastCloudSyncStr);
            if (parsed != null && parsed.millisecondsSinceEpoch > 0) {
              // Subtract 30 seconds (not 2 minutes) as safety overlap — less wasteful reads
              filterCutoff = parsed.subtract(const Duration(seconds: 30));
            }
          }
        }

        dynamic querySnapshot;

        // Step 1: Compound query (companyId + firmId + filterCutoff) — primary path for delta sync
        try {
          var query = _firebaseService.firestore
              .collection(collectionName)
              .where('companyId', isEqualTo: companyId)
              .where('firmId', isEqualTo: activeFirmId);

          if (filterCutoff != null) {
            query = query.where('updatedAt', isGreaterThan: filterCutoff.toUtc().toIso8601String());
          }
          querySnapshot = await query.get().timeout(const Duration(seconds: 15));
        } catch (e1) {
          logger.warning('Primary query failed or timed out for $entityType: $e1. Trying firmId-only query...');
        }

        // Step 2: Fallback to firmId query WITH filterCutoff (preserves delta sync, just drops companyId filter)
        if (querySnapshot == null || querySnapshot.docs.isEmpty) {
          try {
            var firmQuery = _firebaseService.firestore
                .collection(collectionName)
                .where('firmId', isEqualTo: activeFirmId);
            if (filterCutoff != null) {
              firmQuery = firmQuery.where('updatedAt', isGreaterThan: filterCutoff.toUtc().toIso8601String());
            }
            querySnapshot = await firmQuery.get().timeout(const Duration(seconds: 15));
          } catch (e2) {
            logger.warning('Firm-only query also failed for $entityType: $e2. Skipping this entity type.');
          }
        }

        // REMOVED Steps 3 & 4: No more companyId-only or full-collection fallbacks.
        // Those were downloading ALL documents every sync cycle, wasting Firebase reads.

        // Only update timestamp AFTER we've confirmed we got results
        if (querySnapshot == null || querySnapshot.docs.isEmpty) {
          logger.info('  No documents found for $entityType (companyId=$companyId, firmId=$activeFirmId).');
          continue;
        }

        logger.info('  Found ${querySnapshot.docs.length} documents for $entityType — processing...');
        await prefs.setString(timestampKey, DateTime.now().toUtc().toIso8601String());

        for (int d = 0; d < querySnapshot.docs.length; d++) {
          if (kIsWeb ? (d % 5 == 0) : (d % 10 == 0)) await Future.delayed(Duration.zero);

          try {
            final doc = querySnapshot.docs[d];
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            final uuid = data['uuid'] as String?;
            if (uuid == null || uuid.isEmpty) continue;

            // Robust firm-wise & company-wise filtering in Dart code:
            // Match if doc's firmId equals activeFirmId, OR doc has no firmId, OR activeFirmId is firm_default
            final docFirmId = data['firmId'] as String?;
            if (docFirmId != null &&
                docFirmId.isNotEmpty &&
                docFirmId != activeFirmId &&
                activeFirmId != 'firm_default') {
              continue;
            }

            final isar = _dbService.isar;
            dynamic localRecord;

            switch (entityType) {
              case 'Party': localRecord = await isar.partys.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Item': localRecord = await isar.items.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Category': localRecord = await isar.categorys.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Unit': localRecord = await isar.units.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Brand': localRecord = await isar.brands.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Order': localRecord = await isar.orders.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Invoice': localRecord = await isar.invoices.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Settings': localRecord = await isar.settings.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'User': localRecord = await isar.users.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Purchase': localRecord = await isar.purchases.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Expense': localRecord = await isar.expenses.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'Transaction': localRecord = await isar.transactions.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'BankAccount': localRecord = await isar.bankAccounts.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'CreditNote': localRecord = await isar.creditNotes.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'DebitNote': localRecord = await isar.debitNotes.filter().uuidEqualTo(uuid).findFirst(); break;
              case 'StockAdjustment': localRecord = await isar.collection<StockAdjustment>().filter().uuidEqualTo(uuid).findFirst(); break;
              case 'WhatsAppMapping': localRecord = await isar.whatsAppMappings.filter().uuidEqualTo(uuid).findFirst(); break;
            }

            if (localRecord != null) {
              // Local Dirty Lock: If local edit is unsynced (isSynced == false), preserve local draft edits!
              if (localRecord.isSynced == false) {
                logger.info('Conflict: Local Wins (Unsynced Local Draft Lock) for $entityType UUID: $uuid. Keeping local draft.');
                await _logConflictEvent(entityType, uuid, data['version'] as int? ?? 1, localRecord.version, 'Local Wins (Unsynced Draft Lock)');
                continue;
              }

              final localVersion = (localRecord.version as int?) ?? 1;
              final remoteVersion = data['version'] as int? ?? 1;
              final localUpdated = (localRecord.updatedAt as DateTime?) ?? DateTime.fromMillisecondsSinceEpoch(0);
              final remoteUpdated = DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? DateTime.now();

              bool remoteWins = false;
              if (remoteVersion > localVersion) {
                remoteWins = true;
              } else if (remoteVersion == localVersion) {
                if (remoteUpdated.isAfter(localUpdated)) {
                  remoteWins = true;
                }
              }

              if (remoteWins) {
                logger.info('Conflict: Remote wins for $entityType UUID: $uuid. Overwriting local.');
                await _overwriteLocalRecord(entityType, localRecord.id, data);
                await _logConflictEvent(entityType, uuid, remoteVersion, localVersion, 'Remote Wins');
              } else {
                logger.info('Conflict: Local wins for $entityType UUID: $uuid.');
                await _logConflictEvent(entityType, uuid, remoteVersion, localVersion, 'Local Wins');
              }
            } else {
              if (data['isDeleted'] == true) continue;
              await _insertLocalRecord(entityType, data);
            }
          } catch (docErr) {
            logger.warning('Skipped bad $entityType doc: $docErr');
          }
        }
      } catch (e) {
        logger.warning('Skipped $entityType sync query due to timeout or network: $e');
      }
    }

    // Post-download pass: Re-link relations and recalculate stocks
    // ONLY run during full download — during delta sync this is wasteful O(N²) overhead
    // that loads ALL records into memory and causes the "96% hang"
    if (forceFullDownload) {
      try {
        _updateState(SyncState(
          status: SyncStatus.syncing,
          message: 'Relinking database relationships (96%)...',
          lastSyncTime: _currentState.lastSyncTime,
          progress: 0.96,
          currentStep: totalSteps - 1,
          totalSteps: totalSteps,
        ));
        await Future.delayed(Duration.zero);
        try {
          await _relinkAllRelations();
        } catch (relErr) {
          logger.warning('Relink relations warning: $relErr');
        }

        _updateState(SyncState(
          status: SyncStatus.syncing,
          message: 'Recalculating inventory stock balances (98%)...',
          lastSyncTime: _currentState.lastSyncTime,
          progress: 0.98,
          currentStep: totalSteps,
          totalSteps: totalSteps,
        ));
        await Future.delayed(Duration.zero);
        try {
          await recalculateAllItemStocksFromTransactions();
          await recalculateAllPartyBalancesFromTransactions();
        } catch (recalcErr) {
          logger.warning('Recalculate balances warning: $recalcErr');
        }
      } catch (e, stackTrace) {
        logger.warning('Post-download relation re-linking or stock recalculation warning: $e', e, stackTrace);
      }
    } else {
      logger.info('Delta sync: skipping relinking & stock recalculation (not needed for incremental changes).');
    }
  }

  /// Post-sync pass: Relinks all unlinked line items (InvoiceItem, PurchaseItem, OrderItem)
  /// Post-sync pass: Relinks all unlinked line items (InvoiceItem, PurchaseItem, OrderItem)
  /// with their respective parent documents by UUID/ID in local DB.
  Future<void> _relinkAllRelations() async {
    final isar = _dbService.isar;
    logger.info('Executing post-sync pass to re-link all line items to parents...');

    try {
      final allInvoices = await _chunkedFindAll((o, l) => isar.invoices.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final Map<String, Invoice> invoiceByUuid = {};
      final Map<int, Invoice> invoiceById = {};

      for (int i = 0; i < allInvoices.length; i++) {
        final inv = allInvoices[i];
        if (inv.uuid != null && inv.uuid!.isNotEmpty) {
          invoiceByUuid[inv.uuid!] = inv;
        }
        invoiceById[inv.id] = inv;
      }

      final allInvoiceItems = await _chunkedFindAll((o, l) => isar.invoiceItems.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final List<InvoiceItem> modifiedInvItems = [];

      for (int i = 0; i < allInvoiceItems.length; i++) {
        final item = allInvoiceItems[i];
        Invoice? parent = item.invoice.value;

        if (parent == null && item.parentInvoiceUuid != null && item.parentInvoiceUuid!.isNotEmpty) {
          parent = invoiceByUuid[item.parentInvoiceUuid!];
        }

        if (parent == null && item.parentInvoiceId != null) {
          parent = invoiceById[item.parentInvoiceId!];
        }

        if (parent != null) {
          item.invoice.value = parent;
          item.parentInvoiceId = parent.id;
          item.parentInvoiceUuid = parent.uuid;
          modifiedInvItems.add(item);
        }
      }

      if (modifiedInvItems.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.invoiceItems.putAll(modifiedInvItems);
        });
      }

      // Relink PurchaseItems
      final allPurchases = await _chunkedFindAll((o, l) => isar.purchases.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final Map<String, Purchase> purchaseByUuid = {};
      final Map<int, Purchase> purchaseById = {};

      for (int i = 0; i < allPurchases.length; i++) {
        final pur = allPurchases[i];
        if (pur.uuid != null && pur.uuid!.isNotEmpty) {
          purchaseByUuid[pur.uuid!] = pur;
        }
        purchaseById[pur.id] = pur;
      }

      final allPurchaseItems = await _chunkedFindAll((o, l) => isar.purchaseItems.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final List<PurchaseItem> modifiedPurItems = [];

      for (int i = 0; i < allPurchaseItems.length; i++) {
        final item = allPurchaseItems[i];
        Purchase? parent = item.purchase.value;

        if (parent == null && item.purchaseUuid != null && item.purchaseUuid!.isNotEmpty) {
          parent = purchaseByUuid[item.purchaseUuid!];
        }

        if (parent == null && item.purchaseId != null) {
          parent = purchaseById[item.purchaseId!];
        }

        if (parent != null) {
          item.purchase.value = parent;
          item.purchaseId = parent.id;
          item.purchaseUuid = parent.uuid;
          modifiedPurItems.add(item);
        }
      }

      if (modifiedPurItems.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.purchaseItems.putAll(modifiedPurItems);
        });
      }
    } catch (e) {
      logger.error('Error during post-sync relation re-linking pass', e);
    }
  }

  /// Recalculates party outstanding balances dynamically from transactions & invoices
  Future<void> recalculateAllPartyBalancesFromTransactions() async {
    final isar = _dbService.isar;
    logger.info('Recalculating party outstanding balances dynamically from transactions...');

    try {
      final parties = await _chunkedFindAll((o, l) => isar.partys.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      if (parties.isEmpty) return;

      final invoices = await _chunkedFindAll((o, l) => isar.invoices.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final purchases = await _chunkedFindAll((o, l) => isar.purchases.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());

      final Map<int, String> partyIdToUuid = {};
      for (var p in parties) {
        if (p.uuid != null && p.uuid!.isNotEmpty) {
          partyIdToUuid[p.id] = p.uuid!;
        }
      }

      final Map<String, double> uuidPending = {};
      final Map<int, double> idPending = {};

      for (var inv in invoices) {
        if (inv.paymentStatus == 'Cancelled') continue;
        final pending = inv.pendingAmount ?? ((inv.grandTotal ?? 0.0) - (inv.paidAmount ?? 0.0));
        if (pending > 0) {
          String? pUuid = inv.party.value?.uuid;
          if ((pUuid == null || pUuid.isEmpty) && inv.partyId != null) {
            pUuid = partyIdToUuid[inv.partyId!];
          }
          if (pUuid != null && pUuid.isNotEmpty) uuidPending[pUuid] = (uuidPending[pUuid] ?? 0.0) + pending;
          if (inv.partyId != null && inv.partyId! > 0) idPending[inv.partyId!] = (idPending[inv.partyId!] ?? 0.0) + pending;
        }
      }

      for (var pur in purchases) {
        if (pur.paymentStatus == 'Cancelled') continue;
        final pending = pur.pendingAmount ?? ((pur.grandTotal ?? 0.0) - (pur.paidAmount ?? 0.0));
        if (pending > 0) {
          String? pUuid = pur.party.value?.uuid;
          if ((pUuid == null || pUuid.isEmpty) && pur.partyId != null) {
            pUuid = partyIdToUuid[pur.partyId!];
          }
          if (pUuid != null && pUuid.isNotEmpty) uuidPending[pUuid] = (uuidPending[pUuid] ?? 0.0) + pending;
          if (pur.partyId != null && pur.partyId! > 0) idPending[pur.partyId!] = (idPending[pur.partyId!] ?? 0.0) + pending;
        }
      }

      final transactions = await _chunkedFindAll((o, l) => isar.transactions.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final Map<String, double> uuidUnlinkedCredits = {};
      final Map<int, double> idUnlinkedCredits = {};

      for (var tx in transactions) {
        if (tx.isDeleted == true) continue;
        final amt = tx.amount ?? 0.0;
        if (amt <= 0) continue;
        final type = tx.transactionType;
        final isUnlinked = tx.linkedBillUuid == null || tx.linkedBillUuid!.isEmpty || tx.linkedBillUuid == '{}';

        if (isUnlinked && (type == 'Receipt' || type == 'Payment In' || type == 'Payment' || type == 'Payment Out')) {
          String? pUuid = tx.partyUuid;
          if (pUuid != null && pUuid.isNotEmpty) {
            uuidUnlinkedCredits[pUuid] = (uuidUnlinkedCredits[pUuid] ?? 0.0) + amt;
          }
        }
      }

      final List<Party> partiesToUpdate = [];
      for (var p in parties) {
        final hasUuid = p.uuid != null && p.uuid!.isNotEmpty;
        final invPending = hasUuid 
            ? (uuidPending[p.uuid] ?? 0.0) 
            : (p.id > 0 ? (idPending[p.id] ?? 0.0) : 0.0);

        final uUnlinked = hasUuid ? (uuidUnlinkedCredits[p.uuid] ?? 0.0) : 0.0;
        final rawBalance = invPending > 0 ? invPending : (p.openingBalance ?? 0.0);
        final netPending = rawBalance - uUnlinked;
        final newBal = netPending < 0 ? 0.0 : netPending;

        if ((p.outstandingBalance ?? 0.0) != newBal) {
          p.outstandingBalance = newBal;
          p.updatedAt = DateTime.now();
          partiesToUpdate.add(p);
        }
      }

      if (partiesToUpdate.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.partys.putAll(partiesToUpdate);
        });
      }
    } catch (e) {
      logger.warning('Party balance recalculation error: $e');
    }
  }

  /// Dynamically computes real current stock for all items from local transactions:
  /// Current Stock = (openingStock ?? 0) + (Purchases) - (Sales) + (Sales Returns) - (Purchase Returns)
  Future<void> recalculateAllItemStocksFromTransactions() async {
    if (_isRecalculating) {
      logger.info('Stock recalculation already in progress, skipping duplicate run.');
      return;
    }
    _isRecalculating = true;
    final isar = _dbService.isar;
    logger.info('Recalculating item stocks dynamically from local transactions...');

    try {
      final allItems = await _chunkedFindAll((o, l) => isar.items.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      if (allItems.isEmpty) return;

      final allInvItems = await _chunkedFindAll((o, l) => isar.invoiceItems.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final allPurItems = await _chunkedFindAll((o, l) => isar.purchaseItems.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final allCreditNoteItems = await _chunkedFindAll((o, l) => isar.creditNoteItems.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final allDebitNoteItems = await _chunkedFindAll((o, l) => isar.debitNoteItems.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());

      // Load item links for accuracy with non-blocking async yielding
      final Map<int, String> itemIdToUuid = {
        for (var item in allItems)
          if (item.id != null && item.uuid != null) item.id!: item.uuid!
      };

      // Filter out deleted parent invoices/purchases
      final allInvoices = await _chunkedFindAll((o, l) => isar.invoices.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final validInvIds = allInvoices.map((i) => i.id).toSet();
      final validInvUuids = allInvoices.map((i) => i.uuid).whereType<String>().toSet();

      final allPurchases = await _chunkedFindAll((o, l) => isar.purchases.filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());
      final validPurIds = allPurchases.map((p) => p.id).toSet();
      final validPurUuids = allPurchases.map((p) => p.uuid).whereType<String>().toSet();

      final allStockAdjustments = await _chunkedFindAll((o, l) => isar.collection<StockAdjustment>().filter().isDeletedEqualTo(false).offset(o).limit(l).findAll());

      final List<Item> itemsToUpdate = [];

      for (int k = 0; k < allItems.length; k++) {
        if (k % 5 == 0) await Future.delayed(Duration.zero);
        final item = allItems[k];
        final itemUuid = item.uuid;
        final itemNameLower = item.itemName?.trim().toLowerCase() ?? '';

        double _toPrimaryQty(String? lineUnit, double rawQty) {
          if (rawQty <= 0) return 0.0;
          final secUnit = item.secondaryUnit?.trim().toLowerCase();
          final conv = item.conversionFactor;
          final lineUnitLower = lineUnit?.trim().toLowerCase();

          if (secUnit != null && secUnit.isNotEmpty && lineUnitLower != null && lineUnitLower == secUnit && conv != null && conv > 0) {
            return conv >= 1.0 ? rawQty / conv : rawQty * conv;
          }
          return rawQty;
        }

        // 1. Total Sales (InvoiceItems)
        double totalSales = 0.0;
        for (var ii in allInvItems) {
          final isValidParent = (ii.parentInvoiceId != null && validInvIds.contains(ii.parentInvoiceId)) ||
              (ii.parentInvoiceUuid != null && validInvUuids.contains(ii.parentInvoiceUuid)) ||
              ii.invoice.value != null;
          if (!isValidParent) continue;

          final linkedUuid = ii.itemId != null ? itemIdToUuid[ii.itemId!] : ii.item.value?.uuid;
          bool isMatch = false;
          if (ii.itemId != null) {
            isMatch = ii.itemId == item.id;
          } else if (linkedUuid != null && linkedUuid.isNotEmpty) {
            isMatch = linkedUuid == itemUuid;
          } else {
            isMatch = (ii.itemName != null && ii.itemName!.trim().toLowerCase() == itemNameLower);
          }

          if (isMatch) {
            totalSales += _toPrimaryQty(ii.unit, ii.quantity ?? 0.0);
          }
        }

        // 2. Total Purchases (PurchaseItems)
        double totalPurchases = 0.0;
        for (var pi in allPurItems) {
          final isValidParent = (pi.purchaseId != null && validPurIds.contains(pi.purchaseId)) ||
              (pi.purchaseUuid != null && validPurUuids.contains(pi.purchaseUuid)) ||
              pi.purchase.value != null;
          if (!isValidParent) continue;

          final linkedUuid = pi.itemId != null ? itemIdToUuid[pi.itemId!] : pi.item.value?.uuid;
          bool isMatch = false;
          if (pi.itemId != null) {
            isMatch = pi.itemId == item.id;
          } else if (linkedUuid != null && linkedUuid.isNotEmpty) {
            isMatch = linkedUuid == itemUuid;
          } else {
            isMatch = (pi.itemName != null && pi.itemName!.trim().toLowerCase() == itemNameLower);
          }

          if (isMatch) {
            totalPurchases += _toPrimaryQty(pi.unit, pi.quantity ?? 0.0);
          }
        }

        // 3. Sales Returns / Credit Notes (Stock In)
        double totalSalesReturns = 0.0;
        for (var cni in allCreditNoteItems) {
          final linkedUuid = cni.itemId != null ? itemIdToUuid[cni.itemId!] : cni.item.value?.uuid;
          bool isMatch = false;
          if (cni.itemId != null) {
            isMatch = cni.itemId == item.id;
          } else if (linkedUuid != null && linkedUuid.isNotEmpty) {
            isMatch = linkedUuid == itemUuid;
          } else {
            isMatch = (cni.itemName != null && cni.itemName!.trim().toLowerCase() == itemNameLower);
          }
          if (isMatch) {
            totalSalesReturns += _toPrimaryQty(cni.unit, cni.quantity ?? 0.0);
          }
        }

        // 4. Purchase Returns / Debit Notes (Stock Out)
        double totalPurchaseReturns = 0.0;
        for (var dni in allDebitNoteItems) {
          final linkedUuid = dni.itemId != null ? itemIdToUuid[dni.itemId!] : dni.item.value?.uuid;
          bool isMatch = false;
          if (dni.itemId != null) {
            isMatch = dni.itemId == item.id;
          } else if (linkedUuid != null && linkedUuid.isNotEmpty) {
            isMatch = linkedUuid == itemUuid;
          } else {
            isMatch = (dni.itemName != null && dni.itemName!.trim().toLowerCase() == itemNameLower);
          }
          if (isMatch) {
            totalPurchaseReturns += _toPrimaryQty(dni.unit, dni.quantity ?? 0.0);
          }
        }

        // 5. Manual Stock Adjustments (Stock In / Stock Out)
        double totalAdjustments = 0.0;
        for (var adj in allStockAdjustments) {
          bool isMatch = false;
          if (adj.itemId != null) {
            isMatch = adj.itemId == item.id;
          } else if (adj.itemUuid != null && adj.itemUuid!.isNotEmpty) {
            isMatch = adj.itemUuid == itemUuid;
          } else {
            isMatch = (adj.itemName != null && adj.itemName!.trim().toLowerCase() == itemNameLower);
          }
          if (isMatch) {
            final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
            final qty = _toPrimaryQty(adj.unit, adj.quantity ?? 0.0);
            if (isAdd) {
              totalAdjustments += qty;
            } else {
              totalAdjustments -= qty;
            }
          }
        }

        // Real Calculated Current Stock Formula
        final opening = item.openingStock ?? 0.0;
        final computedStock = opening + totalPurchases - totalSales + totalSalesReturns - totalPurchaseReturns + totalAdjustments;

        if (totalSales > 0 || totalPurchases > 0 || totalSalesReturns > 0 || totalPurchaseReturns > 0 || totalAdjustments != 0 || item.currentStock == 0.0) {
          item.currentStock = computedStock;
          itemsToUpdate.add(item);
        }
      }

      if (itemsToUpdate.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.items.putAll(itemsToUpdate);
        });
      }

      logger.info('Recalculated stocks for ${allItems.length} items from local transactions successfully.');
    } catch (e, stackTrace) {
      logger.error('Failed to recalculate item stocks from transactions', e, stackTrace);
    } finally {
      _isRecalculating = false;
    }
  }

  /// Helper to check count of local records for an entity
  Future<int> _getLocalRecordCount(String entityType) async {
    final isar = _dbService.isar;
    try {
      switch (entityType) {
        case 'Party': return await isar.partys.filter().idGreaterThan(-1).count();
        case 'Item': return await isar.items.filter().idGreaterThan(-1).count();
        case 'Category': return await isar.categorys.filter().idGreaterThan(-1).count();
        case 'Unit': return await isar.units.filter().idGreaterThan(-1).count();
        case 'Brand': return await isar.brands.filter().idGreaterThan(-1).count();
        case 'Order': return await isar.orders.filter().idGreaterThan(-1).count();
        case 'Invoice': return await isar.invoices.filter().idGreaterThan(-1).count();
        case 'Purchase': return await isar.purchases.filter().idGreaterThan(-1).count();
        case 'Expense': return await isar.expenses.filter().idGreaterThan(-1).count();
        case 'ExpenseItem': return await isar.collection<ExpenseItem>().count();
        case 'Transaction': return await isar.transactions.filter().idGreaterThan(-1).count();
        default: return 0;
      }
    } catch (_) {
      return 0;
    }
  }

  /// Helper to find maximum updatedAt timestamp among local records for an entity
  Future<DateTime?> _getMaxLocalUpdatedAt(String entityType) async {
    final isar = _dbService.isar;
    try {
      switch (entityType) {
        case 'Party':
          final r = await isar.partys.filter().idGreaterThan(-1).sortByUpdatedAtDesc().findFirst();
          return r?.updatedAt;
        case 'Item':
          final r = await isar.items.filter().idGreaterThan(-1).sortByUpdatedAtDesc().findFirst();
          return r?.updatedAt;
        case 'Invoice':
          final r = await isar.invoices.filter().idGreaterThan(-1).sortByUpdatedAtDesc().findFirst();
          return r?.updatedAt;
        case 'Purchase':
          final r = await isar.purchases.filter().idGreaterThan(-1).sortByUpdatedAtDesc().findFirst();
          return r?.updatedAt;
        case 'Order':
          final r = await isar.orders.filter().idGreaterThan(-1).sortByUpdatedAtDesc().findFirst();
          return r?.updatedAt;
        case 'Expense':
          final r = await isar.expenses.filter().idGreaterThan(-1).sortByUpdatedAtDesc().findFirst();
          return r?.updatedAt;
        case 'ExpenseItem':
          final list = await _chunkedFindAll((o, l) => isar.collection<ExpenseItem>().where().offset(o).limit(l).findAll());
          if (list.isEmpty) return null;
          list.sort((a, b) => (a.updatedAt ?? DateTime(1970)).compareTo(b.updatedAt ?? DateTime(1970)));
          return list.last.updatedAt;
        case 'Transaction':
          final r = await isar.transactions.filter().idGreaterThan(-1).sortByUpdatedAtDesc().findFirst();
          return r?.updatedAt;
      }
    } catch (_) {}
    return null;
  }

  /// Helper mapping collection class names to firestore endpoints
  String _getFirestoreCollection(String entityType) {
    switch (entityType) {
      case 'Party': return 'parties';
      case 'Item': return 'items';
      case 'Category': return 'categories';
      case 'Unit': return 'units';
      case 'Brand': return 'brands';
      case 'Order': return 'orders';
      case 'OrderItem': return 'order_items';
      case 'Invoice': return 'invoices';
      case 'InvoiceItem': return 'invoice_items';
      case 'Settings': return 'settings';
      case 'User': return 'users';
      case 'Purchase': return 'purchases';
      case 'PurchaseItem': return 'purchase_items';
      case 'Expense': return 'expenses';
      case 'ExpenseItem': return 'expense_items';
      case 'Transaction': return 'transactions';
      case 'BankAccount': return 'bank_accounts';
      case 'CreditNote': return 'credit_notes';
      case 'CreditNoteItem': return 'credit_note_items';
      case 'DebitNote': return 'debit_notes';
      case 'DebitNoteItem': return 'debit_note_items';
      case 'StockAdjustment': return 'stock_adjustments';
      case 'WhatsAppMapping': return 'whatsapp_mappings';
      default: return entityType.toLowerCase();
    }
  }

  String? _safeGetLinkUuid(dynamic link) {
    if (link == null) return null;
    try {
      return link.value?.uuid;
    } catch (_) {
      return null;
    }
  }

  String? _safeGetLinkShortName(dynamic link) {
    if (link == null) return null;
    try {
      return link.value?.shortName ?? link.value?.unitName;
    } catch (_) {
      return null;
    }
  }

  /// Maps Isar entity to JSON map for Firestore
  Future<Map<String, dynamic>> _mapEntityToMap(String entityType, dynamic entity) async {
    final baseMap = {
      'uuid': entity.uuid,
      'createdAt': entity.createdAt.toUtc().toIso8601String(),
      'updatedAt': entity.updatedAt.toUtc().toIso8601String(),
      'version': entity.version,
      'isDeleted': entity.isDeleted,
      'deviceId': _firebaseService.deviceId,
      'lastModifiedBy': _firebaseService.currentUserEmail ?? 'admin@sahaj.com',
      'companyId': _firebaseService.companyId,
      'firmId': _dbService.activeFirmId,
    };

    switch (entityType) {
      case 'Party':
        final e = entity as Party;
        return baseMap..addAll({
          'partyCode': e.partyCode,
          'partyName': e.partyName,
          'partyType': e.partyType,
          'mobileNumber': e.mobileNumber,
          'whatsappNumber': e.whatsappNumber,
          'email': e.email,
          'gstType': e.gstType,
          'gstNumber': e.gstNumber,
          'panNumber': e.panNumber,
          'addressLine1': e.addressLine1,
          'addressLine2': e.addressLine2,
          'city': e.city,
          'state': e.state,
          'pincode': e.pincode,
          'latitude': e.latitude,
          'longitude': e.longitude,
          'locationAddress': e.locationAddress,
          'googleMapUrl': e.googleMapUrl,
          'openingBalance': e.openingBalance,
          'balanceType': e.balanceType,
          'creditLimit': e.creditLimit,
          'outstandingBalance': e.outstandingBalance,
          'paymentTerms': e.paymentTerms,
          'dueDays': e.dueDays,
          'contactPerson': e.contactPerson,
          'businessCategory': e.businessCategory,
          'notes': e.notes,
          'shopPhotos': e.shopPhotos,
          'shopPhotoUrls': e.shopPhotoUrls,
        });
      case 'Item':
        final e = entity as Item;
        return baseMap..addAll({
          'itemCode': e.itemCode,
          'itemName': e.itemName,
          'shortName': e.shortName,
          'description': e.description,
          'hsnCode': e.hsnCode,
          'gstApplicable': e.gstApplicable,
          'gstRate': e.gstRate,
          'cessRate': e.cessRate,
          'buyRate': e.buyRate,
          'mrp': e.mrp,
          'sellRate': e.sellRate,
          'wholesaleRate': e.wholesaleRate,
          'minimumSellingPrice': e.minimumSellingPrice,
          'openingStock': e.openingStock,
          'currentStock': e.currentStock,
          'stock': e.currentStock,
          'reorderLevel': e.reorderLevel,
          'minimumStock': e.minimumStock,
          'hasSubItems': e.hasSubItems,
          'subItems': e.subItems?.map((s) => {
            'uuid': s.uuid,
            'name': s.name,
            'localPhotoPath': s.localPhotoPath,
            'googlePhotoLink': s.googlePhotoLink,
            'buyPrice': s.buyPrice,
            'sellPrice': s.sellPrice,
          }).toList(),
          'primaryUnitName': e.primaryUnitName ?? _safeGetLinkShortName(e.unit),
          'secondaryUnit': e.secondaryUnit,
          'tertiaryUnit': e.tertiaryUnit,
          'conversionFactor': e.conversionFactor,
          'secondaryToTertiaryConversion': e.secondaryToTertiaryConversion,
          'barcode': e.barcode,
          'sku': e.sku,
          'skuCode': e.skuCode,
          'imagePaths': e.imagePaths,
          'firebaseImageUrls': e.firebaseImageUrls,
          'thumbnailImage': e.thumbnailImage,
          'categoryUuid': _safeGetLinkUuid(e.category),
          'unitUuid': _safeGetLinkUuid(e.unit),
          'brandUuid': _safeGetLinkUuid(e.brand),
          'weight': e.weight,
          'dimensions': e.dimensions,
          'notes': e.notes,
          'enableBatchTracking': e.enableBatchTracking,
          'defaultBatchNumber': e.defaultBatchNumber,
          'isBundle': e.isBundle,
          'itemType': e.itemType,
          'bundleComponentUuids': e.bundleComponentUuids,
          'bundleComponentQuantities': e.bundleComponentQuantities,
          'bundleComponentUnits': e.bundleComponentUnits,
        });
      case 'Category':
        final e = entity as Category;
        return baseMap..addAll({
          'categoryName': e.categoryName,
          'description': e.description,
        });
      case 'Unit':
        final e = entity as Unit;
        return baseMap..addAll({
          'unitName': e.unitName,
          'shortName': e.shortName,
        });
      case 'Brand':
        final e = entity as Brand;
        return baseMap..addAll({
          'brandName': e.brandName,
        });
      case 'Order':
        final e = entity as Order;
        final isarRef = _dbService.isar;
        final query = isarRef.orderItems.filter().isDeletedEqualTo(false).and().group((q) {
          var sq = q.orderIdEqualTo(e.id);
          if (e.uuid != null && e.uuid!.isNotEmpty) {
            sq = sq.or().orderUuidEqualTo(e.uuid!);
          }
          return sq;
        });
        final rawItems = await query.findAll();

        final itemsMapList = rawItems.map((item) => {
          'uuid': item.uuid,
          'itemId': item.itemId,
          'itemName': item.itemName,
          'hsnCode': item.hsnCode,
          'quantity': item.quantity,
          'freeQuantity': item.freeQuantity,
          'unit': item.unit,
          'rate': item.rate,
          'discountPercent': item.discountPercent,
          'discountAmount': item.discountAmount,
          'taxableAmount': item.taxableAmount,
          'gstPercent': item.gstPercent,
          'gstAmount': item.gstAmount,
          'totalAmount': item.totalAmount,
        }).toList();

        return baseMap..addAll({
          'orderNumber': e.orderNumber,
          'orderDate': e.orderDate?.toIso8601String(),
          'status': e.status,
          'partyId': e.partyId,
          'partyName': e.partyName,
          'mobileNumber': e.mobileNumber,
          'gstNumber': e.gstNumber,
          'latitude': e.latitude,
          'longitude': e.longitude,
          'locationAddress': e.locationAddress,
          'locationUrl': e.locationUrl,
          'subtotal': e.subtotal,
          'discountAmount': e.discountAmount,
          'discountPercent': e.discountPercent,
          'totalGST': e.totalGST,
          'roundOff': e.roundOff,
          'grandTotal': e.grandTotal,
          'remarks': e.remarks,
          'internalNotes': e.internalNotes,
          'cancelledBy': e.cancelledBy,
          'cancelledDate': e.cancelledDate?.toIso8601String(),
          'cancellationReason': e.cancellationReason,
          'createdBy': e.createdBy,
          'editedBy': e.editedBy,
          'editTime': e.editTime?.toIso8601String(),
          'partyUuid': _safeGetLinkUuid(e.party),
          'items': itemsMapList,
        });
      case 'OrderItem':
        final e = entity as OrderItem;
        return baseMap..addAll({
          'itemId': e.itemId,
          'itemName': e.itemName,
          'hsnCode': e.hsnCode,
          'quantity': e.quantity,
          'freeQuantity': e.freeQuantity,
          'unit': e.unit,
          'rate': e.rate,
          'discountPercent': e.discountPercent,
          'discountAmount': e.discountAmount,
          'taxableAmount': e.taxableAmount,
          'gstPercent': e.gstPercent,
          'gstAmount': e.gstAmount,
          'totalAmount': e.totalAmount,
          'orderUuid': _safeGetLinkUuid(e.order),
          'itemUuid': _safeGetLinkUuid(e.item),
        });
      case 'Invoice':
        final e = entity as Invoice;
        final isarRef = _dbService.isar;
        final query = isarRef.invoiceItems.filter().isDeletedEqualTo(false).and().group((q) {
          var sq = q.parentInvoiceIdEqualTo(e.id);
          if (e.uuid != null && e.uuid!.isNotEmpty) {
            sq = sq.or().parentInvoiceUuidEqualTo(e.uuid!);
          }
          return sq;
        });
        final rawItems = await query.findAll();

        final itemsMapList = rawItems.map((item) => {
          'uuid': item.uuid,
          'itemId': item.itemId,
          'itemName': item.itemName,
          'hsnCode': item.hsnCode,
          'quantity': item.quantity,
          'freeQuantity': item.freeQuantity,
          'unit': item.unit,
          'rate': item.rate,
          'discount': item.discount,
          'taxableAmount': item.taxableAmount,
          'gstRate': item.gstRate,
          'gstAmount': item.gstAmount,
          'totalAmount': item.totalAmount,
          'batchNumber': item.batchNumber,
          'expiryDate': item.expiryDate,
          'mfgDate': item.mfgDate,
        }).toList();

        return baseMap..addAll({
          'invoiceNumber': e.invoiceNumber,
          'invoiceDate': e.invoiceDate?.toIso8601String(),
          'invoiceType': e.invoiceType,
          'invoiceStatus': e.invoiceStatus,
          'sourceOrderId': e.sourceOrderId,
          'sourceOrderNumber': e.sourceOrderNumber,
          'partyId': e.partyId,
          'partyName': e.partyName,
          'gstNumber': e.gstNumber,
          'address': e.address,
          'subtotal': e.subtotal,
          'discountAmount': e.discountAmount,
          'taxableAmount': e.taxableAmount,
          'cgstAmount': e.cgstAmount,
          'sgstAmount': e.sgstAmount,
          'igstAmount': e.igstAmount,
          'totalGST': e.totalGST,
          'roundOff': e.roundOff,
          'grandTotal': e.grandTotal,
          'paymentStatus': e.paymentStatus,
          'paidAmount': e.paidAmount,
          'pendingAmount': e.pendingAmount,
          'dueDate': e.dueDate?.toIso8601String(),
          'remarks': e.remarks,
          'termsAndConditions': e.termsAndConditions,
          'cancelledBy': e.cancelledBy,
          'cancelledDate': e.cancelledDate?.toIso8601String(),
          'cancellationReason': e.cancellationReason,
          'createdBy': e.createdBy,
          'editedBy': e.editedBy,
          'editTime': e.editTime?.toIso8601String(),
          'partyUuid': _safeGetLinkUuid(e.party),
          'orderUuid': _safeGetLinkUuid(e.order),
          'items': itemsMapList,
        });
      case 'InvoiceItem':
        final e = entity as InvoiceItem;
        String? invUuid = _safeGetLinkUuid(e.invoice);
        if ((invUuid == null || invUuid.isEmpty) && e.parentInvoiceId != null) {
          final parentInv = await _dbService.isar.invoices.get(e.parentInvoiceId!);
          invUuid = parentInv?.uuid;
        }
        return baseMap..addAll({
          'itemId': e.itemId,
          'itemName': e.itemName,
          'hsnCode': e.hsnCode,
          'parentInvoiceId': e.parentInvoiceId,
          'parentInvoiceUuid': invUuid,
          'invoiceUuid': invUuid,
          'selectedSubItemUuid': e.selectedSubItemUuid,
          'selectedSubItemName': e.selectedSubItemName,
          'quantity': e.quantity,
          'freeQuantity': e.freeQuantity,
          'unit': e.unit,
          'rate': e.rate,
          'discount': e.discount,
          'taxableAmount': e.taxableAmount,
          'gstRate': e.gstRate,
          'gstAmount': e.gstAmount,
          'totalAmount': e.totalAmount,
          'batchNumber': e.batchNumber,
          'expiryDate': e.expiryDate,
          'mfgDate': e.mfgDate,
          'itemUuid': _safeGetLinkUuid(e.item),
        });
      case 'Settings':
        final e = entity as Settings;
        return baseMap..addAll({
          'companyName': e.companyName,
          'companyGST': e.companyGST,
          'companyAddress': e.companyAddress,
          'companyPhone': e.companyPhone,
          'companyEmail': e.companyEmail,
          'logoPath': e.logoPath,
          'themeMode': e.themeMode,
        });
      case 'User':
        final e = entity as User;
        return baseMap..addAll({
          'name': e.name,
          'email': e.email,
          'role': e.role,
        });
      case 'Purchase':
        final e = entity as Purchase;
        final isarRefP = _dbService.isar;
        final query = isarRefP.purchaseItems.filter().isDeletedEqualTo(false).and().group((q) {
          var sq = q.purchaseIdEqualTo(e.id);
          if (e.uuid != null && e.uuid!.isNotEmpty) {
            sq = sq.or().purchaseUuidEqualTo(e.uuid!);
          }
          return sq;
        });
        final rawPItems = await query.findAll();

        final pItemsMapList = rawPItems.map((item) => {
          'uuid': item.uuid,
          'itemId': item.itemId,
          'itemName': item.itemName,
          'hsnCode': item.hsnCode,
          'quantity': item.quantity,
          'rate': item.rate,
          'discount': item.discount,
          'taxableAmount': item.taxableAmount,
          'gstRate': item.gstRate,
          'gstAmount': item.gstAmount,
          'totalAmount': item.totalAmount,
          'unit': item.unit,
          'batchNumber': item.batchNumber,
          'expiryDate': item.expiryDate,
          'mfgDate': item.mfgDate,
        }).toList();

        return baseMap..addAll({
          'purchaseNumber': e.purchaseNumber,
          'supplierInvoiceNumber': e.supplierInvoiceNumber,
          'purchaseDate': e.purchaseDate?.toIso8601String(),
          'partyId': e.partyId,
          'partyName': e.partyName,
          'gstNumber': e.gstNumber,
          'address': e.address,
          'subtotal': e.subtotal,
          'discountAmount': e.discountAmount,
          'taxableAmount': e.taxableAmount,
          'cgstAmount': e.cgstAmount,
          'sgstAmount': e.sgstAmount,
          'igstAmount': e.igstAmount,
          'totalGST': e.totalGST,
          'roundOff': e.roundOff,
          'grandTotal': e.grandTotal,
          'paymentStatus': e.paymentStatus,
          'paidAmount': e.paidAmount,
          'pendingAmount': e.pendingAmount,
          'remarks': e.remarks,
          'partyUuid': _safeGetLinkUuid(e.party),
          'items': pItemsMapList,
        });
      case 'PurchaseItem':
        final e = entity as PurchaseItem;
        String? pUuid = e.purchaseUuid ?? _safeGetLinkUuid(e.purchase);
        if ((pUuid == null || pUuid.isEmpty) && e.purchaseId != null) {
          final parentP = await _dbService.isar.purchases.get(e.purchaseId!);
          pUuid = parentP?.uuid;
        }
        return baseMap..addAll({
          'itemId': e.itemId,
          'itemName': e.itemName,
          'hsnCode': e.hsnCode,
          'purchaseId': e.purchaseId,
          'purchaseUuid': pUuid,
          'quantity': e.quantity,
          'rate': e.rate,
          'discount': e.discount,
          'taxableAmount': e.taxableAmount,
          'gstRate': e.gstRate,
          'gstAmount': e.gstAmount,
          'totalAmount': e.totalAmount,
          'unit': e.unit,
          'batchNumber': e.batchNumber,
          'expiryDate': e.expiryDate,
          'mfgDate': e.mfgDate,
          'itemUuid': _safeGetLinkUuid(e.item),
        });
      case 'Expense':
        final e = entity as Expense;
        dynamic parsedItems;
        if (e.itemsJson != null && e.itemsJson!.isNotEmpty) {
          try {
            parsedItems = jsonDecode(e.itemsJson!);
          } catch (_) {}
        }
        return baseMap..addAll({
          'voucherNo': e.voucherNo,
          'partyName': e.partyName,
          'category': e.category,
          'subtotal': e.subtotal,
          'roundOff': e.roundOff,
          'amount': e.amount,
          'expenseDate': e.expenseDate?.toIso8601String(),
          'paymentMode': e.paymentMode,
          'remarks': e.remarks,
          'itemsJson': e.itemsJson,
          'items': parsedItems ?? [],
        });
      case 'ExpenseItem':
        final e = entity as ExpenseItem;
        return baseMap..addAll({
          'itemName': e.itemName,
          'defaultRate': e.defaultRate,
        });
      case 'Transaction':
        final e = entity as Transaction;
        return baseMap..addAll({
          'transactionNumber': e.transactionNumber,
          'transactionDate': e.transactionDate?.toIso8601String(),
          'partyUuid': e.partyUuid,
          'partyName': e.partyName,
          'transactionType': e.transactionType,
          'amount': e.amount,
          'paymentMode': e.paymentMode,
          'referenceNumber': e.referenceNumber,
          'remarks': e.remarks,
          'linkedBillUuid': e.linkedBillUuid,
          'linkedBillNumber': e.linkedBillNumber,
          'targetPartyUuid': e.targetPartyUuid,
          'targetPartyName': e.targetPartyName,
        });
      case 'BankAccount':
        final e = entity as BankAccount;
        return baseMap..addAll({
          'accountName': e.accountName,
          'bankName': e.bankName,
          'accountNumber': e.accountNumber,
          'ifscCode': e.ifscCode,
          'branchName': e.branchName,
          'openingBalance': e.openingBalance,
          'currentBalance': e.currentBalance,
        });
      case 'CreditNote':
        final e = entity as CreditNote;
        return baseMap..addAll({
          'creditNoteNumber': e.creditNoteNumber,
          'creditNoteDate': e.creditNoteDate?.toIso8601String(),
          'originalInvoiceNumber': e.originalInvoiceNumber,
          'originalInvoiceUuid': e.originalInvoiceUuid,
          'partyId': e.partyId,
          'partyName': e.partyName,
          'gstNumber': e.gstNumber,
          'address': e.address,
          'subtotal': e.subtotal,
          'discountAmount': e.discountAmount,
          'taxableAmount': e.taxableAmount,
          'cgstAmount': e.cgstAmount,
          'sgstAmount': e.sgstAmount,
          'igstAmount': e.igstAmount,
          'totalGST': e.totalGST,
          'roundOff': e.roundOff,
          'grandTotal': e.grandTotal,
          'remarks': e.remarks,
          'createdBy': e.createdBy,
          'partyUuid': e.party.value?.uuid,
        });
      case 'CreditNoteItem':
        final e = entity as CreditNoteItem;
        return baseMap..addAll({
          'itemId': e.itemId,
          'itemName': e.itemName,
          'hsnCode': e.hsnCode,
          'quantity': e.quantity,
          'freeQuantity': e.freeQuantity,
          'rate': e.rate,
          'discount': e.discount,
          'taxableAmount': e.taxableAmount,
          'gstRate': e.gstRate,
          'gstAmount': e.gstAmount,
          'totalAmount': e.totalAmount,
          'creditNoteUuid': e.creditNote.value?.uuid,
          'itemUuid': e.item.value?.uuid,
        });
      case 'DebitNote':
        final e = entity as DebitNote;
        return baseMap..addAll({
          'debitNoteNumber': e.debitNoteNumber,
          'debitNoteDate': e.debitNoteDate?.toIso8601String(),
          'originalPurchaseNumber': e.originalPurchaseNumber,
          'originalPurchaseUuid': e.originalPurchaseUuid,
          'partyId': e.partyId,
          'partyName': e.partyName,
          'gstNumber': e.gstNumber,
          'address': e.address,
          'subtotal': e.subtotal,
          'discountAmount': e.discountAmount,
          'taxableAmount': e.taxableAmount,
          'cgstAmount': e.cgstAmount,
          'sgstAmount': e.sgstAmount,
          'igstAmount': e.igstAmount,
          'totalGST': e.totalGST,
          'roundOff': e.roundOff,
          'grandTotal': e.grandTotal,
          'remarks': e.remarks,
          'createdBy': e.createdBy,
          'partyUuid': e.party.value?.uuid,
        });
      case 'DebitNoteItem':
        final e = entity as DebitNoteItem;
        return baseMap..addAll({
          'itemId': e.itemId,
          'itemName': e.itemName,
          'hsnCode': e.hsnCode,
          'quantity': e.quantity,
          'freeQuantity': e.freeQuantity,
          'rate': e.rate,
          'discount': e.discount,
          'taxableAmount': e.taxableAmount,
          'gstRate': e.gstRate,
          'gstAmount': e.gstAmount,
          'totalAmount': e.totalAmount,
          'debitNoteUuid': e.debitNote.value?.uuid,
          'itemUuid': e.item.value?.uuid,
        });
      case 'StockAdjustment':
        final e = entity as StockAdjustment;
        return baseMap..addAll({
          'itemUuid': e.itemUuid,
          'itemId': e.itemId,
          'itemName': e.itemName,
          'adjustmentType': e.adjustmentType,
          'quantity': e.quantity,
          'unit': e.unit,
          'ratePerUnit': e.ratePerUnit,
          'totalValue': e.totalValue,
          'adjustmentDate': e.adjustmentDate?.toIso8601String(),
          'reason': e.reason,
          'notes': e.notes,
        });
      case 'WhatsAppMapping':
        final e = entity as WhatsAppMapping;
        return baseMap..addAll({
          'mappingType': e.mappingType,
          'rawKey': e.rawKey,
          'targetUuid': e.targetUuid,
          'pcsPerBundle': e.pcsPerBundle,
          'pcsPerCarton': e.pcsPerCarton,
          'customRate': e.customRate,
          'rateUnit': e.rateUnit,
          'isTaxInclusive': e.isTaxInclusive,
        });
      default:
        return baseMap;
    }
  }

  /// Maps remote Firestore JSON to Isar entity mapping
  dynamic _mapMapToEntity(String entityType, Map<String, dynamic> data) {
    dynamic entity;
    
    switch (entityType) {
      case 'Party':
        entity = Party()
          ..partyCode = data['partyCode']
          ..partyName = data['partyName']
          ..partyType = data['partyType']
          ..mobileNumber = data['mobileNumber']
          ..whatsappNumber = data['whatsappNumber']
          ..email = data['email']
          ..gstType = data['gstType']
          ..gstNumber = data['gstNumber']
          ..panNumber = data['panNumber']
          ..addressLine1 = data['addressLine1']
          ..addressLine2 = data['addressLine2']
          ..city = data['city']
          ..state = data['state']
          ..pincode = data['pincode']
          ..latitude = (data['latitude'] as num?)?.toDouble()
          ..longitude = (data['longitude'] as num?)?.toDouble()
          ..locationAddress = data['locationAddress']
          ..googleMapUrl = data['googleMapUrl']
          ..openingBalance = (data['openingBalance'] as num?)?.toDouble()
          ..balanceType = data['balanceType']
          ..creditLimit = (data['creditLimit'] as num?)?.toDouble()
          ..outstandingBalance = (data['outstandingBalance'] as num?)?.toDouble()
          ..paymentTerms = data['paymentTerms']
          ..dueDays = (data['dueDays'] as num?)?.toInt()
          ..contactPerson = data['contactPerson']
          ..businessCategory = data['businessCategory']
          ..notes = data['notes']
          ..shopPhotos = data['shopPhotos'] != null ? List<String>.from(data['shopPhotos']) : null
          ..shopPhotoUrls = data['shopPhotoUrls'] != null ? List<String>.from(data['shopPhotoUrls']) : null;
        break;
      case 'Item':
        entity = Item()
          ..itemCode = data['itemCode']
          ..itemName = data['itemName']
          ..shortName = data['shortName']
          ..description = data['description']
          ..hsnCode = data['hsnCode']
          ..gstApplicable = data['gstApplicable'] as bool? ?? true
          ..gstRate = (data['gstRate'] as num?)?.toDouble()
          ..cessRate = (data['cessRate'] as num?)?.toDouble()
          ..buyRate = (data['buyRate'] as num?)?.toDouble()
          ..mrp = (data['mrp'] as num?)?.toDouble()
          ..sellRate = (data['sellRate'] as num?)?.toDouble()
          ..wholesaleRate = (data['wholesaleRate'] as num?)?.toDouble()
          ..minimumSellingPrice = (data['minimumSellingPrice'] as num?)?.toDouble()
          ..openingStock = (data['openingStock'] as num?)?.toDouble() ?? (data['opening_stock'] as num?)?.toDouble()
          ..currentStock = (() {
            final c = (data['currentStock'] as num?)?.toDouble() ?? (data['current_stock'] as num?)?.toDouble() ?? 0.0;
            final s = (data['stock'] as num?)?.toDouble() ?? 0.0;
            final o = (data['openingStock'] as num?)?.toDouble() ?? (data['opening_stock'] as num?)?.toDouble() ?? 0.0;
            if (c > 0.0) return c;
            if (s > 0.0) return s;
            if (o > 0.0) return o;
            return c;
          })()
          ..hasSubItems = data['hasSubItems'] as bool? ?? false
          ..subItems = (data['subItems'] as List<dynamic>?)?.map((s) {
            final m = s as Map<String, dynamic>;
            return SubItem()
              ..uuid = m['uuid'] as String?
              ..name = m['name'] as String?
              ..localPhotoPath = m['localPhotoPath'] as String?
              ..googlePhotoLink = m['googlePhotoLink'] as String?
              ..buyPrice = (m['buyPrice'] as num?)?.toDouble()
              ..sellPrice = (m['sellPrice'] as num?)?.toDouble();
          }).toList()
          ..reorderLevel = (data['reorderLevel'] as num?)?.toDouble()
          ..minimumStock = (data['minimumStock'] as num?)?.toDouble()
          ..primaryUnitName = (data['primaryUnitName'] as String?)?.isNotEmpty == true ? (data['primaryUnitName'] as String) : ((data['unit'] as String?)?.isNotEmpty == true ? (data['unit'] as String) : null)
          ..secondaryUnit = data['secondaryUnit']
          ..tertiaryUnit = data['tertiaryUnit']
          ..conversionFactor = (data['conversionFactor'] as num?)?.toDouble()
          ..secondaryToTertiaryConversion = (data['secondaryToTertiaryConversion'] as num?)?.toDouble()
          ..barcode = data['barcode']
          ..sku = data['sku']
          ..skuCode = data['skuCode']
          ..imagePaths = data['imagePaths'] != null ? List<String>.from(data['imagePaths']) : null
          ..firebaseImageUrls = data['firebaseImageUrls'] != null ? List<String>.from(data['firebaseImageUrls']) : null
          ..thumbnailImage = data['thumbnailImage']
          ..weight = (data['weight'] as num?)?.toDouble()
          ..dimensions = data['dimensions']
          ..notes = data['notes']
          ..enableBatchTracking = data['enableBatchTracking'] ?? false
          ..defaultBatchNumber = data['defaultBatchNumber']
          ..isBundle = data['isBundle'] ?? false
          ..itemType = data['itemType']
          ..bundleComponentUuids = data['bundleComponentUuids'] != null ? List<String>.from(data['bundleComponentUuids']) : null
          ..bundleComponentQuantities = data['bundleComponentQuantities'] != null ? List<double>.from(data['bundleComponentQuantities'].map((e) => (e as num).toDouble())) : null
          ..bundleComponentUnits = data['bundleComponentUnits'] != null ? List<String>.from(data['bundleComponentUnits']) : null;
        break;
      case 'Category':
        entity = Category()
          ..categoryName = data['categoryName']
          ..description = data['description'];
        break;
      case 'Unit':
        entity = Unit()
          ..unitName = data['unitName']
          ..shortName = data['shortName'];
        break;
      case 'Brand':
        entity = Brand()..brandName = data['brandName'];
        break;
      case 'Order':
        entity = Order()
          ..orderNumber = data['orderNumber']
          ..orderDate = data['orderDate'] != null ? DateTime.parse(data['orderDate']) : null
          ..status = data['status']
          ..partyId = data['partyId']
          ..partyName = data['partyName']
          ..mobileNumber = data['mobileNumber']
          ..gstNumber = data['gstNumber']
          ..latitude = data['latitude']
          ..longitude = data['longitude']
          ..locationAddress = data['locationAddress']
          ..locationUrl = data['locationUrl']
          ..subtotal = (data['subtotal'] as num?)?.toDouble()
          ..discountAmount = (data['discountAmount'] as num?)?.toDouble()
          ..discountPercent = (data['discountPercent'] as num?)?.toDouble()
          ..totalGST = (data['totalGST'] as num?)?.toDouble()
          ..roundOff = (data['roundOff'] as num?)?.toDouble()
          ..grandTotal = (data['grandTotal'] as num?)?.toDouble()
          ..remarks = data['remarks']
          ..internalNotes = data['internalNotes']
          ..cancelledBy = data['cancelledBy']
          ..cancelledDate = data['cancelledDate'] != null ? DateTime.parse(data['cancelledDate']) : null
          ..cancellationReason = data['cancellationReason']
          ..createdBy = data['createdBy']
          ..editedBy = data['editedBy']
          ..editTime = data['editTime'] != null ? DateTime.parse(data['editTime']) : null;
        break;
      case 'OrderItem':
        entity = OrderItem()
          ..orderId = data['orderId'] as int?
          ..orderUuid = data['orderUuid'] as String?
          ..itemId = data['itemId']
          ..itemName = data['itemName']
          ..hsnCode = data['hsnCode']
          ..quantity = (data['quantity'] as num?)?.toDouble()
          ..freeQuantity = (data['freeQuantity'] as num?)?.toDouble()
          ..unit = data['unit']
          ..rate = (data['rate'] as num?)?.toDouble()
          ..discountPercent = (data['discountPercent'] as num?)?.toDouble()
          ..discountAmount = (data['discountAmount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..gstPercent = (data['gstPercent'] as num?)?.toDouble()
          ..gstAmount = (data['gstAmount'] as num?)?.toDouble()
          ..totalAmount = (data['totalAmount'] as num?)?.toDouble()
          ..batchNumber = data['batchNumber'] as String?
          ..expiryDate = data['expiryDate'] as String?
          ..mfgDate = data['mfgDate'] as String?;
        break;
      case 'Invoice':
        entity = Invoice()
          ..invoiceNumber = data['invoiceNumber']
          ..invoiceDate = data['invoiceDate'] != null ? DateTime.parse(data['invoiceDate']) : null
          ..invoiceType = data['invoiceType']
          ..invoiceStatus = data['invoiceStatus']
          ..sourceOrderId = data['sourceOrderId']
          ..sourceOrderNumber = data['sourceOrderNumber']
          ..partyId = data['partyId']
          ..partyName = data['partyName']
          ..gstNumber = data['gstNumber']
          ..address = data['address']
          ..subtotal = (data['subtotal'] as num?)?.toDouble()
          ..discountAmount = (data['discountAmount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..cgstAmount = (data['cgstAmount'] as num?)?.toDouble()
          ..sgstAmount = (data['sgstAmount'] as num?)?.toDouble()
          ..igstAmount = (data['igstAmount'] as num?)?.toDouble()
          ..totalGST = (data['totalGST'] as num?)?.toDouble()
          ..roundOff = (data['roundOff'] as num?)?.toDouble()
          ..grandTotal = (data['grandTotal'] as num?)?.toDouble()
          ..paymentStatus = data['paymentStatus']
          ..paidAmount = (data['paidAmount'] as num?)?.toDouble()
          ..pendingAmount = (data['pendingAmount'] as num?)?.toDouble()
          ..dueDate = data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null
          ..remarks = data['remarks']
          ..termsAndConditions = data['termsAndConditions']
          ..cancelledBy = data['cancelledBy']
          ..cancelledDate = data['cancelledDate'] != null ? DateTime.parse(data['cancelledDate']) : null
          ..cancellationReason = data['cancellationReason']
          ..createdBy = data['createdBy']
          ..editedBy = data['editedBy']
          ..editTime = data['editTime'] != null ? DateTime.parse(data['editTime']) : null;
        break;
      case 'InvoiceItem':
        entity = InvoiceItem()
          ..itemId = data['itemId']
          ..itemName = data['itemName']
          ..hsnCode = data['hsnCode']
          ..parentInvoiceId = data['parentInvoiceId']
          ..parentInvoiceUuid = (data['parentInvoiceUuid'] ?? data['invoiceUuid']) as String?
          ..selectedSubItemUuid = data['selectedSubItemUuid'] as String?
          ..selectedSubItemName = data['selectedSubItemName'] as String?
          ..quantity = (data['quantity'] as num?)?.toDouble()
          ..freeQuantity = (data['freeQuantity'] as num?)?.toDouble()
          ..unit = data['unit']
          ..rate = (data['rate'] as num?)?.toDouble()
          ..discount = (data['discount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..gstRate = (data['gstRate'] as num?)?.toDouble()
          ..gstAmount = (data['gstAmount'] as num?)?.toDouble()
          ..totalAmount = (data['totalAmount'] as num?)?.toDouble()
          ..batchNumber = data['batchNumber']
          ..expiryDate = data['expiryDate']
          ..mfgDate = data['mfgDate'];
        break;
      case 'Settings':
        entity = Settings()
          ..companyName = data['companyName']
          ..companyGST = data['companyGST']
          ..companyAddress = data['companyAddress']
          ..companyPhone = data['companyPhone']
          ..companyEmail = data['companyEmail']
          ..logoPath = data['logoPath']
          ..themeMode = data['themeMode'];
        break;
      case 'User':
        entity = User()
          ..name = data['name']
          ..email = data['email']
          ..role = data['role'];
        break;
      case 'Expense':
        String? resolvedItemsJson;
        final rawItemsJson = data['itemsJson'];
        final rawItems = data['items'];

        if (rawItemsJson is String && rawItemsJson.isNotEmpty) {
          resolvedItemsJson = rawItemsJson;
        } else if (rawItemsJson is List) {
          resolvedItemsJson = jsonEncode(rawItemsJson);
        } else if (rawItems is List) {
          resolvedItemsJson = jsonEncode(rawItems);
        } else if (rawItems is Map) {
          resolvedItemsJson = jsonEncode([rawItems]);
        }

        entity = Expense()
          ..voucherNo = data['voucherNo']
          ..partyName = data['partyName']
          ..category = data['category']
          ..subtotal = (data['subtotal'] as num?)?.toDouble()
          ..roundOff = (data['roundOff'] as num?)?.toDouble()
          ..amount = (data['amount'] as num?)?.toDouble()
          ..expenseDate = data['expenseDate'] != null ? DateTime.parse(data['expenseDate']) : null
          ..paymentMode = data['paymentMode']
          ..remarks = data['remarks']
          ..itemsJson = resolvedItemsJson;
        break;
      case 'ExpenseItem':
        entity = ExpenseItem()
          ..itemName = data['itemName']
          ..defaultRate = (data['defaultRate'] as num?)?.toDouble();
        break;
      case 'Transaction':
        entity = Transaction()
          ..transactionNumber = data['transactionNumber']
          ..transactionDate = data['transactionDate'] != null ? DateTime.parse(data['transactionDate']) : null
          ..partyUuid = data['partyUuid']
          ..partyName = data['partyName']
          ..transactionType = data['transactionType']
          ..amount = (data['amount'] as num?)?.toDouble()
          ..paymentMode = data['paymentMode']
          ..referenceNumber = data['referenceNumber']
          ..remarks = data['remarks']
          ..linkedBillUuid = data['linkedBillUuid']
          ..linkedBillNumber = data['linkedBillNumber']
          ..targetPartyUuid = data['targetPartyUuid']
          ..targetPartyName = data['targetPartyName'];
        break;
      case 'BankAccount':
        entity = BankAccount()
          ..accountName = data['accountName']
          ..bankName = data['bankName']
          ..accountNumber = data['accountNumber']
          ..ifscCode = data['ifscCode']
          ..branchName = data['branchName']
          ..openingBalance = (data['openingBalance'] as num?)?.toDouble()
          ..currentBalance = (data['currentBalance'] as num?)?.toDouble();
        break;
      case 'Purchase':
        entity = Purchase()
          ..purchaseNumber = data['purchaseNumber']
          ..supplierInvoiceNumber = data['supplierInvoiceNumber']
          ..purchaseDate = data['purchaseDate'] != null ? DateTime.parse(data['purchaseDate']) : null
          ..partyId = data['partyId']
          ..partyName = data['partyName']
          ..gstNumber = data['gstNumber']
          ..address = data['address']
          ..subtotal = (data['subtotal'] as num?)?.toDouble()
          ..discountAmount = (data['discountAmount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..cgstAmount = (data['cgstAmount'] as num?)?.toDouble()
          ..sgstAmount = (data['sgstAmount'] as num?)?.toDouble()
          ..igstAmount = (data['igstAmount'] as num?)?.toDouble()
          ..totalGST = (data['totalGST'] as num?)?.toDouble()
          ..roundOff = (data['roundOff'] as num?)?.toDouble()
          ..grandTotal = (data['grandTotal'] as num?)?.toDouble()
          ..paymentStatus = data['paymentStatus']
          ..paidAmount = (data['paidAmount'] as num?)?.toDouble()
          ..pendingAmount = (data['pendingAmount'] as num?)?.toDouble()
          ..remarks = data['remarks'];
        break;
      case 'PurchaseItem':
        entity = PurchaseItem()
          ..itemId = data['itemId']
          ..itemName = data['itemName']
          ..hsnCode = data['hsnCode']
          ..purchaseId = data['purchaseId']
          ..purchaseUuid = data['purchaseUuid']
          ..quantity = (data['quantity'] as num?)?.toDouble()
          ..unit = data['unit']
          ..rate = (data['rate'] as num?)?.toDouble()
          ..discount = (data['discount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..gstRate = (data['gstRate'] as num?)?.toDouble()
          ..gstAmount = (data['gstAmount'] as num?)?.toDouble()
          ..totalAmount = (data['totalAmount'] as num?)?.toDouble()
          ..batchNumber = data['batchNumber']
          ..expiryDate = data['expiryDate']
          ..mfgDate = data['mfgDate'];
        break;
      case 'CreditNote':
        entity = CreditNote()
          ..creditNoteNumber = data['creditNoteNumber']
          ..creditNoteDate = data['creditNoteDate'] != null ? DateTime.parse(data['creditNoteDate']) : null
          ..originalInvoiceNumber = data['originalInvoiceNumber']
          ..originalInvoiceUuid = data['originalInvoiceUuid']
          ..partyId = data['partyId']
          ..partyName = data['partyName']
          ..gstNumber = data['gstNumber']
          ..address = data['address']
          ..subtotal = (data['subtotal'] as num?)?.toDouble()
          ..discountAmount = (data['discountAmount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..cgstAmount = (data['cgstAmount'] as num?)?.toDouble()
          ..sgstAmount = (data['sgstAmount'] as num?)?.toDouble()
          ..igstAmount = (data['igstAmount'] as num?)?.toDouble()
          ..totalGST = (data['totalGST'] as num?)?.toDouble()
          ..roundOff = (data['roundOff'] as num?)?.toDouble()
          ..grandTotal = (data['grandTotal'] as num?)?.toDouble()
          ..remarks = data['remarks']
          ..createdBy = data['createdBy'];
        break;
      case 'CreditNoteItem':
        entity = CreditNoteItem()
          ..itemId = data['itemId']
          ..itemName = data['itemName']
          ..hsnCode = data['hsnCode']
          ..quantity = (data['quantity'] as num?)?.toDouble()
          ..freeQuantity = (data['freeQuantity'] as num?)?.toDouble()
          ..rate = (data['rate'] as num?)?.toDouble()
          ..discount = (data['discount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..gstRate = (data['gstRate'] as num?)?.toDouble()
          ..gstAmount = (data['gstAmount'] as num?)?.toDouble()
          ..totalAmount = (data['totalAmount'] as num?)?.toDouble();
        break;
      case 'DebitNote':
        entity = DebitNote()
          ..debitNoteNumber = data['debitNoteNumber']
          ..debitNoteDate = data['debitNoteDate'] != null ? DateTime.parse(data['debitNoteDate']) : null
          ..originalPurchaseNumber = data['originalPurchaseNumber']
          ..originalPurchaseUuid = data['originalPurchaseUuid']
          ..partyId = data['partyId']
          ..partyName = data['partyName']
          ..gstNumber = data['gstNumber']
          ..address = data['address']
          ..subtotal = (data['subtotal'] as num?)?.toDouble()
          ..discountAmount = (data['discountAmount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..cgstAmount = (data['cgstAmount'] as num?)?.toDouble()
          ..sgstAmount = (data['sgstAmount'] as num?)?.toDouble()
          ..igstAmount = (data['igstAmount'] as num?)?.toDouble()
          ..totalGST = (data['totalGST'] as num?)?.toDouble()
          ..roundOff = (data['roundOff'] as num?)?.toDouble()
          ..grandTotal = (data['grandTotal'] as num?)?.toDouble()
          ..remarks = data['remarks']
          ..createdBy = data['createdBy'];
        break;
      case 'DebitNoteItem':
        entity = DebitNoteItem()
          ..itemId = data['itemId']
          ..itemName = data['itemName']
          ..hsnCode = data['hsnCode']
          ..quantity = (data['quantity'] as num?)?.toDouble()
          ..freeQuantity = (data['freeQuantity'] as num?)?.toDouble()
          ..rate = (data['rate'] as num?)?.toDouble()
          ..discount = (data['discount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..gstRate = (data['gstRate'] as num?)?.toDouble()
          ..gstAmount = (data['gstAmount'] as num?)?.toDouble()
          ..totalAmount = (data['totalAmount'] as num?)?.toDouble();
        break;
      case 'StockAdjustment':
        entity = StockAdjustment()
          ..itemUuid = data['itemUuid'] as String?
          ..itemId = (data['itemId'] as num?)?.toInt()
          ..itemName = data['itemName'] as String?
          ..adjustmentType = data['adjustmentType'] as String?
          ..quantity = double.tryParse(data['quantity']?.toString() ?? '0') ?? (data['quantity'] as num?)?.toDouble() ?? 0.0
          ..unit = data['unit'] as String?
          ..ratePerUnit = double.tryParse(data['ratePerUnit']?.toString() ?? '0') ?? (data['ratePerUnit'] as num?)?.toDouble() ?? 0.0
          ..totalValue = double.tryParse(data['totalValue']?.toString() ?? '0') ?? (data['totalValue'] as num?)?.toDouble() ?? 0.0
          ..adjustmentDate = data['adjustmentDate'] != null ? DateTime.tryParse(data['adjustmentDate'].toString()) : null
          ..reason = data['reason'] as String?
          ..notes = data['notes'] as String?;
        break;
      case 'WhatsAppMapping':
        entity = WhatsAppMapping()
          ..mappingType = data['mappingType'] as String?
          ..rawKey = data['rawKey'] as String?
          ..targetUuid = data['targetUuid'] as String?
          ..pcsPerBundle = (data['pcsPerBundle'] as num?)?.toDouble()
          ..pcsPerCarton = (data['pcsPerCarton'] as num?)?.toDouble()
          ..customRate = (data['customRate'] as num?)?.toDouble();
        break;
    }

    if (entity != null) {
      entity.uuid = data['uuid']?.toString();
      entity.createdAt = data['createdAt'] != null 
          ? (DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()) 
          : DateTime.now();
      entity.updatedAt = data['updatedAt'] != null 
          ? (DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now()) 
          : DateTime.now();
      entity.isDeleted = data['isDeleted'] == true;
      entity.isSynced = true;
      entity.version = (data['version'] as num?)?.toInt() ?? 1;
    }

    return entity;
  }

  /// Overwrites an existing local record with downloaded updates
  Future<void> _overwriteLocalRecord(String entityType, Id localId, Map<String, dynamic> data) async {
    final entity = _mapMapToEntity(entityType, data);
    if (entity == null) return;
    entity.id = localId;
    
    await _dbService.isar.writeTxn(() async {
      switch (entityType) {
        case 'Party': await _dbService.isar.partys.put(entity as Party); break;
        case 'Item': await _dbService.isar.items.put(entity as Item); break;
        case 'Category': await _dbService.isar.categorys.put(entity as Category); break;
        case 'Unit': await _dbService.isar.units.put(entity as Unit); break;
        case 'Brand': await _dbService.isar.brands.put(entity as Brand); break;
        case 'Order': await _dbService.isar.orders.put(entity as Order); break;
        case 'OrderItem': await _dbService.isar.orderItems.put(entity as OrderItem); break;
        case 'Invoice': await _dbService.isar.invoices.put(entity as Invoice); break;
        case 'InvoiceItem': await _dbService.isar.invoiceItems.put(entity as InvoiceItem); break;
        case 'Settings': await _dbService.isar.settings.put(entity as Settings); break;
        case 'User': await _dbService.isar.users.put(entity as User); break;
        case 'Purchase': await _dbService.isar.purchases.put(entity as Purchase); break;
        case 'PurchaseItem': await _dbService.isar.purchaseItems.put(entity as PurchaseItem); break;
        case 'Expense': await _dbService.isar.expenses.put(entity as Expense); break;
        case 'ExpenseItem': await _dbService.isar.collection<ExpenseItem>().put(entity as ExpenseItem); break;
        case 'Transaction': await _dbService.isar.transactions.put(entity as Transaction); break;
        case 'BankAccount': await _dbService.isar.bankAccounts.put(entity as BankAccount); break;
        case 'CreditNote': await _dbService.isar.creditNotes.put(entity as CreditNote); break;
        case 'CreditNoteItem': await _dbService.isar.creditNoteItems.put(entity as CreditNoteItem); break;
        case 'DebitNote': await _dbService.isar.debitNotes.put(entity as DebitNote); break;
        case 'DebitNoteItem': await _dbService.isar.debitNoteItems.put(entity as DebitNoteItem); break;
        case 'StockAdjustment': await _dbService.isar.collection<StockAdjustment>().put(entity as StockAdjustment); break;
        case 'WhatsAppMapping': await _dbService.isar.whatsAppMappings.put(entity as WhatsAppMapping); break;
      }
    });

    _linkRemoteRelations(entityType, entity, data);
  }

  /// Inserts a new remote record downloaded into local database
  /// Includes duplicate voucher number detection across devices
  Future<void> _insertLocalRecord(String entityType, Map<String, dynamic> data) async {
    if (kIsWeb) await Future.delayed(Duration.zero);
    final isar = _dbService.isar;
    final uuid = data['uuid'] as String?;

    // === Duplicate Voucher Number Conflict Detection ===
    try {
      if (entityType == 'Invoice' && data['invoiceNumber'] != null) {
        final existing = await isar.invoices.filter().invoiceNumberEqualTo(data['invoiceNumber'] as String).findFirst();
        if (existing != null && existing.uuid != uuid) {
          final originalNum = data['invoiceNumber'] as String;
          data['invoiceNumber'] = '$originalNum-CLOUD';
          logger.warning('CONFLICT: Duplicate invoice number "$originalNum" from different device. Renamed to "${data['invoiceNumber']}".');
          await _logConflictEvent(entityType, uuid ?? '', 0, 0, 'Duplicate voucher# "$originalNum" renamed to "${data['invoiceNumber']}"');
        }
      } else if (entityType == 'Purchase' && data['purchaseNumber'] != null) {
        final existing = await isar.purchases.filter().purchaseNumberEqualTo(data['purchaseNumber'] as String).findFirst();
        if (existing != null && existing.uuid != uuid) {
          final originalNum = data['purchaseNumber'] as String;
          data['purchaseNumber'] = '$originalNum-CLOUD';
          logger.warning('CONFLICT: Duplicate purchase number "$originalNum" from different device. Renamed.');
          await _logConflictEvent(entityType, uuid ?? '', 0, 0, 'Duplicate voucher# "$originalNum" renamed');
        }
      } else if (entityType == 'Order' && data['orderNumber'] != null) {
        final existing = await isar.orders.filter().orderNumberEqualTo(data['orderNumber'] as String).findFirst();
        if (existing != null && existing.uuid != uuid) {
          final originalNum = data['orderNumber'] as String;
          data['orderNumber'] = '$originalNum-CLOUD';
          logger.warning('CONFLICT: Duplicate order number "$originalNum" from different device. Renamed.');
          await _logConflictEvent(entityType, uuid ?? '', 0, 0, 'Duplicate voucher# "$originalNum" renamed');
        }
      } else if (entityType == 'Expense' && data['voucherNo'] != null) {
        final voucherNoStr = data['voucherNo'] as String;
        final allExpenses = await isar.expenses.filter().isDeletedEqualTo(false).findAll();
        final existing = allExpenses.where((e) => e.voucherNo == voucherNoStr).firstOrNull;
        if (existing != null && existing.uuid != uuid) {
          final originalNum = voucherNoStr;
          data['voucherNo'] = '$originalNum-CLOUD';
          logger.warning('CONFLICT: Duplicate expense voucher "$originalNum" from different device. Renamed.');
          await _logConflictEvent(entityType, uuid ?? '', 0, 0, 'Duplicate voucher# "$originalNum" renamed');
        }
      } else if (entityType == 'Transaction' && data['transactionNumber'] != null) {
        final existing = await isar.transactions.filter().transactionNumberEqualTo(data['transactionNumber'] as String).findFirst();
        if (existing != null && existing.uuid != uuid) {
          final originalNum = data['transactionNumber'] as String;
          data['transactionNumber'] = '$originalNum-CLOUD';
          logger.warning('CONFLICT: Duplicate transaction number "$originalNum" from different device. Renamed.');
          await _logConflictEvent(entityType, uuid ?? '', 0, 0, 'Duplicate voucher# "$originalNum" renamed');
        }
      }
    } catch (conflictCheckErr) {
      logger.warning('Non-fatal conflict check error for $entityType: $conflictCheckErr');
    }

    final entity = _mapMapToEntity(entityType, data);
    if (entity == null) return;

    await _dbService.isar.writeTxn(() async {
      switch (entityType) {
        case 'Party': await _dbService.isar.partys.put(entity as Party); break;
        case 'Item': await _dbService.isar.items.put(entity as Item); break;
        case 'Category': await _dbService.isar.categorys.put(entity as Category); break;
        case 'Unit': await _dbService.isar.units.put(entity as Unit); break;
        case 'Brand': await _dbService.isar.brands.put(entity as Brand); break;
        case 'Order': await _dbService.isar.orders.put(entity as Order); break;
        case 'OrderItem': await _dbService.isar.orderItems.put(entity as OrderItem); break;
        case 'Invoice': await _dbService.isar.invoices.put(entity as Invoice); break;
        case 'InvoiceItem': await _dbService.isar.invoiceItems.put(entity as InvoiceItem); break;
        case 'Settings': await _dbService.isar.settings.put(entity as Settings); break;
        case 'User': await _dbService.isar.users.put(entity as User); break;
        case 'Purchase': await _dbService.isar.purchases.put(entity as Purchase); break;
        case 'PurchaseItem': await _dbService.isar.purchaseItems.put(entity as PurchaseItem); break;
        case 'Expense': await _dbService.isar.expenses.put(entity as Expense); break;
        case 'ExpenseItem': await _dbService.isar.collection<ExpenseItem>().put(entity as ExpenseItem); break;
        case 'Transaction': await _dbService.isar.transactions.put(entity as Transaction); break;
        case 'BankAccount': await _dbService.isar.bankAccounts.put(entity as BankAccount); break;
        case 'CreditNote': await _dbService.isar.creditNotes.put(entity as CreditNote); break;
        case 'CreditNoteItem': await _dbService.isar.creditNoteItems.put(entity as CreditNoteItem); break;
        case 'DebitNote': await _dbService.isar.debitNotes.put(entity as DebitNote); break;
        case 'DebitNoteItem': await _dbService.isar.debitNoteItems.put(entity as DebitNoteItem); break;
        case 'StockAdjustment': await _dbService.isar.collection<StockAdjustment>().put(entity as StockAdjustment); break;
        case 'WhatsAppMapping': await _dbService.isar.whatsAppMappings.put(entity as WhatsAppMapping); break;
      }
    });

    _linkRemoteRelations(entityType, entity, data);
  }

  /// Resolves entity linking using global UUID references downloaded
  Future<void> _linkRemoteRelations(String entityType, dynamic entity, Map<String, dynamic> data) async {
    final isar = _dbService.isar;
    
    try {
      if (entityType == 'Item') {
        final e = entity as Item;
        final categoryUuid = data['categoryUuid'] as String?;
        final unitUuid = data['unitUuid'] as String?;
        final brandUuid = data['brandUuid'] as String?;

        if (categoryUuid != null) {
          e.category.value = await isar.categorys.filter().uuidEqualTo(categoryUuid).findFirst();
        }
        if (unitUuid != null) {
          e.unit.value = await isar.units.filter().uuidEqualTo(unitUuid).findFirst();
        }
        if (brandUuid != null) {
          e.brand.value = await isar.brands.filter().uuidEqualTo(brandUuid).findFirst();
        }

        await isar.writeTxn(() async {
          await e.category.save();
          await e.unit.save();
          await e.brand.save();
        });
      } else if (entityType == 'Order') {
        final e = entity as Order;
        final partyUuid = data['partyUuid'] as String?;

        if (partyUuid != null) {
          e.party.value = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
          await isar.writeTxn(() async {
            await e.party.save();
          });
        }

        // Restore embedded items if present in document
        if (data.containsKey('items') && data['items'] is List) {
          final itemsList = data['items'] as List;
          for (var itemMap in itemsList) {
            if (itemMap is Map<String, dynamic>) {
              final itemUuid = itemMap['uuid'] as String? ?? '${e.uuid}-${itemMap['itemId']}';
              final OrderItem ordItem = (await isar.orderItems.filter().uuidEqualTo(itemUuid).findFirst()) ?? OrderItem();
              ordItem
                ..uuid = itemUuid
                ..itemId = itemMap['itemId'] as int?
                ..itemName = itemMap['itemName'] as String?
                ..hsnCode = itemMap['hsnCode'] as String?
                ..quantity = (itemMap['quantity'] as num?)?.toDouble()
                ..freeQuantity = (itemMap['freeQuantity'] as num?)?.toDouble()
                ..unit = itemMap['unit'] as String?
                ..rate = (itemMap['rate'] as num?)?.toDouble()
                ..discountPercent = (itemMap['discountPercent'] as num?)?.toDouble()
                ..discountAmount = (itemMap['discountAmount'] as num?)?.toDouble()
                ..taxableAmount = (itemMap['taxableAmount'] as num?)?.toDouble()
                ..gstPercent = (itemMap['gstPercent'] as num?)?.toDouble()
                ..gstAmount = (itemMap['gstAmount'] as num?)?.toDouble()
                ..totalAmount = (itemMap['totalAmount'] as num?)?.toDouble()
                ..isDeleted = false
                ..isSynced = true
                ..updatedAt = DateTime.now();

              ordItem.order.value = e;
              await isar.writeTxn(() async {
                await isar.orderItems.put(ordItem);
                try { await ordItem.order.save(); } catch (_) {}
              });
            }
          }
        } else if (e.uuid != null && e.uuid!.isNotEmpty) {
          // Legacy Cloud Fallback: Fetch from legacy 'order_items' collection in Firestore
          try {
            final legacySnapshot = await _firebaseService.firestore
                .collection('order_items')
                .where('companyId', isEqualTo: _firebaseService.companyId)
                .where('orderUuid', isEqualTo: e.uuid)
                .get()
                .timeout(const Duration(seconds: 5));

            for (var legacyDoc in legacySnapshot.docs) {
              final itemMap = legacyDoc.data();
              final itemUuid = itemMap['uuid'] as String? ?? legacyDoc.id;
              final OrderItem ordItem = (await isar.orderItems.filter().uuidEqualTo(itemUuid).findFirst()) ?? OrderItem();
              ordItem
                ..uuid = itemUuid
                ..itemId = itemMap['itemId'] as int?
                ..itemName = itemMap['itemName'] as String?
                ..hsnCode = itemMap['hsnCode'] as String?
                ..quantity = (itemMap['quantity'] as num?)?.toDouble()
                ..freeQuantity = (itemMap['freeQuantity'] as num?)?.toDouble()
                ..unit = itemMap['unit'] as String?
                ..rate = (itemMap['rate'] as num?)?.toDouble()
                ..discountPercent = (itemMap['discountPercent'] as num?)?.toDouble()
                ..discountAmount = (itemMap['discountAmount'] as num?)?.toDouble()
                ..taxableAmount = (itemMap['taxableAmount'] as num?)?.toDouble()
                ..gstPercent = (itemMap['gstPercent'] as num?)?.toDouble()
                ..gstAmount = (itemMap['gstAmount'] as num?)?.toDouble()
                ..totalAmount = (itemMap['totalAmount'] as num?)?.toDouble()
                ..isDeleted = false
                ..isSynced = true
                ..updatedAt = DateTime.now();

              ordItem.order.value = e;
              await isar.writeTxn(() async {
                await isar.orderItems.put(ordItem);
                try { await ordItem.order.save(); } catch (_) {}
              });
            }
          } catch (e) {
            logger.warning('Failed to fetch legacy order_items: $e');
          }
        }
      } else if (entityType == 'OrderItem') {
        final e = entity as OrderItem;
        final orderUuid = data['orderUuid'] as String?;
        final itemUuid = data['itemUuid'] as String?;

        if (orderUuid != null) {
          e.order.value = await isar.orders.filter().uuidEqualTo(orderUuid).findFirst();
        }
        if (itemUuid != null) {
          e.item.value = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
        }

        await isar.writeTxn(() async {
          await e.order.save();
          await e.item.save();
        });
      } else if (entityType == 'Invoice') {
        final e = entity as Invoice;
        final partyUuid = data['partyUuid'] as String?;
        final orderUuid = data['orderUuid'] as String?;

        if (partyUuid != null) {
          e.party.value = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
        }
        if (orderUuid != null) {
          e.order.value = await isar.orders.filter().uuidEqualTo(orderUuid).findFirst();
        }

        await isar.writeTxn(() async {
          await e.party.save();
          await e.order.save();
        });

        // Restore embedded items if present in document
        final bool hasEmbeddedInvItems = data.containsKey('items') && data['items'] is List && (data['items'] as List).isNotEmpty;
        if (hasEmbeddedInvItems) {
          final itemsList = data['items'] as List;
          for (var itemMap in itemsList) {
            if (itemMap is Map<String, dynamic>) {
              final itemUuid = itemMap['uuid'] as String? ?? '${e.uuid}-${itemMap['itemId']}';
              final InvoiceItem invItem = (await isar.invoiceItems.filter().uuidEqualTo(itemUuid).findFirst()) ?? InvoiceItem();
              invItem
                ..uuid = itemUuid
                ..parentInvoiceId = e.id
                ..parentInvoiceUuid = e.uuid
                ..itemId = itemMap['itemId'] as int?
                ..itemName = itemMap['itemName'] as String?
                ..hsnCode = itemMap['hsnCode'] as String?
                ..quantity = (itemMap['quantity'] as num?)?.toDouble()
                ..freeQuantity = (itemMap['freeQuantity'] as num?)?.toDouble()
                ..unit = itemMap['unit'] as String?
                ..rate = (itemMap['rate'] as num?)?.toDouble()
                ..discount = (itemMap['discount'] as num?)?.toDouble()
                ..taxableAmount = (itemMap['taxableAmount'] as num?)?.toDouble()
                ..gstRate = (itemMap['gstRate'] as num?)?.toDouble()
                ..gstAmount = (itemMap['gstAmount'] as num?)?.toDouble()
                ..totalAmount = (itemMap['totalAmount'] as num?)?.toDouble()
                ..batchNumber = itemMap['batchNumber'] as String?
                ..expiryDate = itemMap['expiryDate'] as String?
                ..mfgDate = itemMap['mfgDate'] as String?
                ..isDeleted = false
                ..isSynced = true
                ..updatedAt = DateTime.now();

              await isar.writeTxn(() async {
                await isar.invoiceItems.put(invItem);
              });
            }
          }
        } else if (e.uuid != null && e.uuid!.isNotEmpty) {
          // Legacy Cloud Fallback: Fetch from legacy 'invoice_items' collection in Firestore
          try {
            final legacySnapshot = await _firebaseService.firestore
                .collection('invoice_items')
                .where('companyId', isEqualTo: _firebaseService.companyId)
                .where('parentInvoiceUuid', isEqualTo: e.uuid)
                .get()
                .timeout(const Duration(seconds: 5));

            for (var legacyDoc in legacySnapshot.docs) {
              final itemMap = legacyDoc.data();
              final itemUuid = itemMap['uuid'] as String? ?? legacyDoc.id;
              final InvoiceItem invItem = (await isar.invoiceItems.filter().uuidEqualTo(itemUuid).findFirst()) ?? InvoiceItem();
              invItem
                ..uuid = itemUuid
                ..parentInvoiceId = e.id
                ..parentInvoiceUuid = e.uuid
                ..itemId = itemMap['itemId'] as int?
                ..itemName = itemMap['itemName'] as String?
                ..hsnCode = itemMap['hsnCode'] as String?
                ..quantity = (itemMap['quantity'] as num?)?.toDouble()
                ..freeQuantity = (itemMap['freeQuantity'] as num?)?.toDouble()
                ..unit = itemMap['unit'] as String?
                ..rate = (itemMap['rate'] as num?)?.toDouble()
                ..discount = (itemMap['discount'] as num?)?.toDouble()
                ..taxableAmount = (itemMap['taxableAmount'] as num?)?.toDouble()
                ..gstRate = (itemMap['gstRate'] as num?)?.toDouble()
                ..gstAmount = (itemMap['gstAmount'] as num?)?.toDouble()
                ..totalAmount = (itemMap['totalAmount'] as num?)?.toDouble()
                ..batchNumber = itemMap['batchNumber'] as String?
                ..expiryDate = itemMap['expiryDate'] as String?
                ..mfgDate = itemMap['mfgDate'] as String?
                ..isDeleted = itemMap['isDeleted'] as bool? ?? false
                ..isSynced = true
                ..updatedAt = DateTime.now();

              await isar.writeTxn(() async {
                await isar.invoiceItems.put(invItem);
              });
            }
          } catch (legacyErr) {
            logger.warning('Legacy invoice_items query fallback non-fatal warning: $legacyErr');
          }
        }
      } else if (entityType == 'InvoiceItem') {
        final e = entity as InvoiceItem;
        final invUuid = (data['invoiceUuid'] ?? data['parentInvoiceUuid']) as String?;
        final itemUuid = data['itemUuid'] as String?;

        if (invUuid != null && invUuid.isNotEmpty) {
          e.parentInvoiceUuid = invUuid;
          final parentInv = await isar.invoices.filter().uuidEqualTo(invUuid).findFirst();
          if (parentInv != null) {
            e.invoice.value = parentInv;
            e.parentInvoiceId = parentInv.id;
          }
        }
        if (itemUuid != null && itemUuid.isNotEmpty) {
          e.item.value = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
        }

        await isar.writeTxn(() async {
          await isar.invoiceItems.put(e);
          try { await e.invoice.save(); } catch (_) {}
          try { await e.item.save(); } catch (_) {}
        });
      } else if (entityType == 'Purchase') {
        final e = entity as Purchase;
        final partyUuid = data['partyUuid'] as String?;
        if (partyUuid != null) {
          e.party.value = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
          await isar.writeTxn(() async {
            await e.party.save();
          });
        }

        // Restore embedded items if present in document
        final bool hasEmbeddedPItems = data.containsKey('items') && data['items'] is List && (data['items'] as List).isNotEmpty;
        if (hasEmbeddedPItems) {
          final itemsList = data['items'] as List;
          for (var itemMap in itemsList) {
            if (itemMap is Map<String, dynamic>) {
              final itemUuid = itemMap['uuid'] as String? ?? '${e.uuid}-${itemMap['itemId']}';
              final PurchaseItem purItem = (await isar.purchaseItems.filter().uuidEqualTo(itemUuid).findFirst()) ?? PurchaseItem();
              purItem
                ..uuid = itemUuid
                ..purchaseId = e.id
                ..purchaseUuid = e.uuid
                ..itemId = itemMap['itemId'] as int?
                ..itemName = itemMap['itemName'] as String?
                ..hsnCode = itemMap['hsnCode'] as String?
                ..quantity = (itemMap['quantity'] as num?)?.toDouble()
                ..rate = (itemMap['rate'] as num?)?.toDouble()
                ..discount = (itemMap['discount'] as num?)?.toDouble()
                ..taxableAmount = (itemMap['taxableAmount'] as num?)?.toDouble()
                ..gstRate = (itemMap['gstRate'] as num?)?.toDouble()
                ..gstAmount = (itemMap['gstAmount'] as num?)?.toDouble()
                ..totalAmount = (itemMap['totalAmount'] as num?)?.toDouble()
                ..unit = itemMap['unit'] as String?
                ..batchNumber = itemMap['batchNumber'] as String?
                ..expiryDate = itemMap['expiryDate'] as String?
                ..mfgDate = itemMap['mfgDate'] as String?
                ..isDeleted = false
                ..isSynced = true
                ..updatedAt = DateTime.now();

              await isar.writeTxn(() async {
                await isar.purchaseItems.put(purItem);
              });
            }
          }
        } else if (e.uuid != null && e.uuid!.isNotEmpty) {
          // Legacy Cloud Fallback: Fetch from legacy 'purchase_items' collection in Firestore
          try {
            final legacySnapshot = await _firebaseService.firestore
                .collection('purchase_items')
                .where('companyId', isEqualTo: _firebaseService.companyId)
                .where('purchaseUuid', isEqualTo: e.uuid)
                .get()
                .timeout(const Duration(seconds: 5));

            for (var legacyDoc in legacySnapshot.docs) {
              final itemMap = legacyDoc.data();
              final itemUuid = itemMap['uuid'] as String? ?? legacyDoc.id;
              final PurchaseItem purItem = (await isar.purchaseItems.filter().uuidEqualTo(itemUuid).findFirst()) ?? PurchaseItem();
              purItem
                ..uuid = itemUuid
                ..purchaseId = e.id
                ..purchaseUuid = e.uuid
                ..itemId = itemMap['itemId'] as int?
                ..itemName = itemMap['itemName'] as String?
                ..hsnCode = itemMap['hsnCode'] as String?
                ..quantity = (itemMap['quantity'] as num?)?.toDouble()
                ..rate = (itemMap['rate'] as num?)?.toDouble()
                ..discount = (itemMap['discount'] as num?)?.toDouble()
                ..taxableAmount = (itemMap['taxableAmount'] as num?)?.toDouble()
                ..gstRate = (itemMap['gstRate'] as num?)?.toDouble()
                ..gstAmount = (itemMap['gstAmount'] as num?)?.toDouble()
                ..totalAmount = (itemMap['totalAmount'] as num?)?.toDouble()
                ..unit = itemMap['unit'] as String?
                ..batchNumber = itemMap['batchNumber'] as String?
                ..expiryDate = itemMap['expiryDate'] as String?
                ..mfgDate = itemMap['mfgDate'] as String?
                ..isDeleted = itemMap['isDeleted'] as bool? ?? false
                ..isSynced = true
                ..updatedAt = DateTime.now();

              await isar.writeTxn(() async {
                await isar.purchaseItems.put(purItem);
              });
            }
          } catch (legacyErr) {
            logger.warning('Legacy purchase_items query fallback non-fatal warning: $legacyErr');
          }
        }
      } else if (entityType == 'PurchaseItem') {
        final e = entity as PurchaseItem;
        final purchaseUuid = data['purchaseUuid'] as String?;
        final itemUuid = data['itemUuid'] as String?;

        if (purchaseUuid != null && purchaseUuid.isNotEmpty) {
          final parentPurchase = await isar.purchases.filter().uuidEqualTo(purchaseUuid).findFirst();
          if (parentPurchase != null) {
            e.purchase.value = parentPurchase;
            e.purchaseId = parentPurchase.id;
          }
        }
        if (itemUuid != null && itemUuid.isNotEmpty) {
          e.item.value = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
        }

        await isar.writeTxn(() async {
          await isar.purchaseItems.put(e);
          try { await e.purchase.save(); } catch (_) {}
          try { await e.item.save(); } catch (_) {}
        });
      } else if (entityType == 'CreditNote') {
        final e = entity as CreditNote;
        final partyUuid = data['partyUuid'] as String?;
        if (partyUuid != null) {
          e.party.value = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
          await isar.writeTxn(() async {
            await e.party.save();
          });
        }

        // Restore embedded items if present in document
        if (data.containsKey('items') && data['items'] is List) {
          final itemsList = data['items'] as List;
          for (var itemMap in itemsList) {
            if (itemMap is Map<String, dynamic>) {
              final itemUuid = itemMap['uuid'] as String? ?? '${e.uuid}-${itemMap['itemId']}';
              final CreditNoteItem cnItem = (await isar.creditNoteItems.filter().uuidEqualTo(itemUuid).findFirst()) ?? CreditNoteItem();
              cnItem
                ..uuid = itemUuid
                ..itemId = itemMap['itemId'] as int?
                ..itemName = itemMap['itemName'] as String?
                ..hsnCode = itemMap['hsnCode'] as String?
                ..quantity = (itemMap['quantity'] as num?)?.toDouble()
                ..freeQuantity = (itemMap['freeQuantity'] as num?)?.toDouble()
                ..rate = (itemMap['rate'] as num?)?.toDouble()
                ..discount = (itemMap['discount'] as num?)?.toDouble()
                ..taxableAmount = (itemMap['taxableAmount'] as num?)?.toDouble()
                ..gstRate = (itemMap['gstRate'] as num?)?.toDouble()
                ..gstAmount = (itemMap['gstAmount'] as num?)?.toDouble()
                ..totalAmount = (itemMap['totalAmount'] as num?)?.toDouble()
                ..isDeleted = false
                ..isSynced = true
                ..updatedAt = DateTime.now();

              cnItem.creditNote.value = e;
              await isar.writeTxn(() async {
                await isar.creditNoteItems.put(cnItem);
                try { await cnItem.creditNote.save(); } catch (_) {}
              });
            }
          }
        }
      } else if (entityType == 'CreditNoteItem') {
        final e = entity as CreditNoteItem;
        final creditNoteUuid = data['creditNoteUuid'] as String?;
        final itemUuid = data['itemUuid'] as String?;
        if (creditNoteUuid != null) {
          e.creditNote.value = await isar.creditNotes.filter().uuidEqualTo(creditNoteUuid).findFirst();
        }
        if (itemUuid != null) {
          e.item.value = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
        }
        await isar.writeTxn(() async {
          await e.creditNote.save();
          await e.item.save();
        });
      } else if (entityType == 'DebitNote') {
        final e = entity as DebitNote;
        final partyUuid = data['partyUuid'] as String?;
        if (partyUuid != null) {
          e.party.value = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
          await isar.writeTxn(() async {
            await e.party.save();
          });
        }

        // Restore embedded items if present in document
        if (data.containsKey('items') && data['items'] is List) {
          final itemsList = data['items'] as List;
          for (var itemMap in itemsList) {
            if (itemMap is Map<String, dynamic>) {
              final itemUuid = itemMap['uuid'] as String? ?? '${e.uuid}-${itemMap['itemId']}';
              final DebitNoteItem dnItem = (await isar.debitNoteItems.filter().uuidEqualTo(itemUuid).findFirst()) ?? DebitNoteItem();
              dnItem
                ..uuid = itemUuid
                ..itemId = itemMap['itemId'] as int?
                ..itemName = itemMap['itemName'] as String?
                ..hsnCode = itemMap['hsnCode'] as String?
                ..quantity = (itemMap['quantity'] as num?)?.toDouble()
                ..freeQuantity = (itemMap['freeQuantity'] as num?)?.toDouble()
                ..rate = (itemMap['rate'] as num?)?.toDouble()
                ..discount = (itemMap['discount'] as num?)?.toDouble()
                ..taxableAmount = (itemMap['taxableAmount'] as num?)?.toDouble()
                ..gstRate = (itemMap['gstRate'] as num?)?.toDouble()
                ..gstAmount = (itemMap['gstAmount'] as num?)?.toDouble()
                ..totalAmount = (itemMap['totalAmount'] as num?)?.toDouble()
                ..isDeleted = false
                ..isSynced = true
                ..updatedAt = DateTime.now();

              dnItem.debitNote.value = e;
              await isar.writeTxn(() async {
                await isar.debitNoteItems.put(dnItem);
                try { await dnItem.debitNote.save(); } catch (_) {}
              });
            }
          }
        }
      } else if (entityType == 'DebitNoteItem') {
        final e = entity as DebitNoteItem;
        final debitNoteUuid = data['debitNoteUuid'] as String?;
        final itemUuid = data['itemUuid'] as String?;
        if (debitNoteUuid != null) {
          e.debitNote.value = await isar.debitNotes.filter().uuidEqualTo(debitNoteUuid).findFirst();
        }
        if (itemUuid != null) {
          e.item.value = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
        }
        await isar.writeTxn(() async {
          await e.debitNote.save();
          await e.item.save();
        });
      }
    } catch (err) {
      logger.error('Failed to link downloaded relations for $entityType UUID: ${entity.uuid}', err);
    }
  }

  /// Appends log items — Success logs to local SharedPreferences only, Failures to Firestore
  Future<void> _logSyncEvent(String result, String message) async {
    // Success logs: local-only to minimize Firebase writes
    if (result == 'Success') {
      try {
        await _prefs.setString('last_sync_log', '[$result] ${DateTime.now().toIso8601String()}: $message');
      } catch (_) {}
      return;
    }

    // Failure/Error logs: write to Firestore for remote debugging
    try {
      await _firebaseService.firestore.collection('sync_logs').add({
        'time': DateTime.now().toIso8601String(),
        'result': result,
        'message': message,
        'deviceId': _firebaseService.deviceId,
        'user': _firebaseService.currentUserEmail ?? 'admin@sahaj.com',
        'companyId': _firebaseService.companyId,
        'firmId': _dbService.activeFirmId,
      });
    } catch (e) {
      logger.error('Failed to write sync log entry to Firestore', e);
    }
  }

  /// Appends details to conflict logs in Firestore
  Future<void> _logConflictEvent(
    String entityType,
    String uuid,
    int remoteVersion,
    int localVersion,
    String resolution,
  ) async {
    try {
      await _firebaseService.firestore.collection('sync_logs').add({
        'time': DateTime.now().toIso8601String(),
        'result': 'Conflict',
        'message': 'Conflict resolved for $entityType ($uuid): Remote version $remoteVersion vs Local version $localVersion. Winner: $resolution',
        'deviceId': _firebaseService.deviceId,
        'user': _firebaseService.currentUserEmail ?? 'admin@sahaj.com',
        'companyId': _firebaseService.companyId,
        'firmId': _dbService.activeFirmId,
      });
    } catch (e) {
      logger.error('Failed to write conflict log entry to Firestore', e);
    }
  }

  void dispose() {
    _stateController.close();
  }
}
