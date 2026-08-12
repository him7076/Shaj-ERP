import 'dart:async';
import 'dart:convert';
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

  final _stateController = StreamController<SyncState>.broadcast();
  SyncState _currentState = const SyncState(
    status: SyncStatus.idle,
    message: 'System ready for sync',
  );

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
    _quietSyncDebounceTimer?.cancel();
    _quietSyncDebounceTimer = Timer(delay, () async {
      if (_isUploadingQuietly) return;
      final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
      if (!cloudSyncEnabled) return;
      if (_currentState.status == SyncStatus.syncing) return;

      _isUploadingQuietly = true;
      try {
        await _firebaseService.ensureAuthenticated();
        if (_firebaseService.isAuthenticated) {
          await _uploadLocalChanges();
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
    final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
    if (!cloudSyncEnabled) {
      logger.info('Firebase Cloud Sync is turned OFF by user. Bypassing cloud sync.');
      _updateState(const SyncState(
        status: SyncStatus.idle,
        message: 'Local Storage Mode Active (Cloud Sync OFF)',
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
      // 1. Purge local DB for active firm completely so old corrupted data is wiped
      await _dbService.clearDatabase();

      // 2. Clear firm-specific last sync timestamp so incremental filter is disabled
      final activeFirmId = _dbService.activeFirmId;
      await _prefs.remove('${AppConstants.keyLastSyncTime}_$activeFirmId');
      await _prefs.remove(AppConstants.keyLastSyncTime);

      // 3. Re-seed standard commercial units in local DB
      await DemoDataSeeder.seedStandardUnits(_dbService);

      // 4. Download remote firm definitions & all Firestore collections for active firm
      await syncFirms();
      final epochStart = DateTime.fromMillisecondsSinceEpoch(0);
      final newSyncTime = DateTime.now();
      await _downloadRemoteUpdates(epochStart);
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
    await isar.writeTxn(() async {
      final parties = forceAll ? await isar.partys.filter().idGreaterThan(-1).findAll() : await isar.partys.filter().isSyncedEqualTo(false).findAll();
      for (var p in parties) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'Party'
          ..entityId = p.id
          ..entityUuid = p.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final items = forceAll ? await isar.items.filter().idGreaterThan(-1).findAll() : await isar.items.filter().isSyncedEqualTo(false).findAll();
      for (var i in items) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'Item'
          ..entityId = i.id
          ..entityUuid = i.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final invoices = forceAll ? await isar.invoices.filter().idGreaterThan(-1).findAll() : await isar.invoices.filter().isSyncedEqualTo(false).findAll();
      for (var inv in invoices) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'Invoice'
          ..entityId = inv.id
          ..entityUuid = inv.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final orders = forceAll ? await isar.orders.filter().idGreaterThan(-1).findAll() : await isar.orders.filter().isSyncedEqualTo(false).findAll();
      for (var ord in orders) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'Order'
          ..entityId = ord.id
          ..entityUuid = ord.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final purchases = forceAll ? await isar.purchases.filter().idGreaterThan(-1).findAll() : await isar.purchases.filter().isSyncedEqualTo(false).findAll();
      for (var pur in purchases) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'Purchase'
          ..entityId = pur.id
          ..entityUuid = pur.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final invItems = forceAll ? await isar.invoiceItems.filter().idGreaterThan(-1).findAll() : await isar.invoiceItems.filter().isSyncedEqualTo(false).findAll();
      for (var ii in invItems) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'InvoiceItem'
          ..entityId = ii.id
          ..entityUuid = ii.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final purItems = forceAll ? await isar.purchaseItems.filter().idGreaterThan(-1).findAll() : await isar.purchaseItems.filter().isSyncedEqualTo(false).findAll();
      for (var pi in purItems) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'PurchaseItem'
          ..entityId = pi.id
          ..entityUuid = pi.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final expenses = forceAll ? await isar.expenses.filter().idGreaterThan(-1).findAll() : await isar.expenses.filter().isSyncedEqualTo(false).findAll();
      for (var exp in expenses) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'Expense'
          ..entityId = exp.id
          ..entityUuid = exp.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final allExpItems = await isar.expenseItems.where().findAll();
      final expItems = allExpItems.where((ei) => forceAll || !ei.isSynced).toList();
      for (var ei in expItems) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'ExpenseItem'
          ..entityId = ei.id
          ..entityUuid = ei.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final allStockAdjs = await isar.collection<StockAdjustment>().where().findAll();
      final stockAdjs = allStockAdjs.where((sa) => forceAll || !sa.isSynced).toList();
      for (var sa in stockAdjs) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'StockAdjustment'
          ..entityId = sa.id
          ..entityUuid = sa.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final allCreditNotes = await isar.creditNotes.where().findAll();
      final creditNotes = allCreditNotes.where((cn) => forceAll || !cn.isSynced).toList();
      for (var cn in creditNotes) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'CreditNote'
          ..entityId = cn.id
          ..entityUuid = cn.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final allCreditNoteItems = await isar.creditNoteItems.where().findAll();
      final creditNoteItems = allCreditNoteItems.where((cni) => forceAll || !cni.isSynced).toList();
      for (var cni in creditNoteItems) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'CreditNoteItem'
          ..entityId = cni.id
          ..entityUuid = cni.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final allDebitNotes = await isar.debitNotes.where().findAll();
      final debitNotes = allDebitNotes.where((dn) => forceAll || !dn.isSynced).toList();
      for (var dn in debitNotes) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'DebitNote'
          ..entityId = dn.id
          ..entityUuid = dn.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final allDebitNoteItems = await isar.debitNoteItems.where().findAll();
      final debitNoteItems = allDebitNoteItems.where((dni) => forceAll || !dni.isSynced).toList();
      for (var dni in debitNoteItems) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'DebitNoteItem'
          ..entityId = dni.id
          ..entityUuid = dni.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
      final txns = forceAll ? await isar.transactions.filter().idGreaterThan(-1).findAll() : await isar.transactions.filter().isSyncedEqualTo(false).findAll();
      for (var t in txns) {
        final q = SyncQueue()
          ..uuid = uuidGen.v4()
          ..entityType = 'Transaction'
          ..entityId = t.id
          ..entityUuid = t.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(q);
      }
    });
  }

  /// Deletes all documents belonging to the active company context from Firestore.
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
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem'
    ];

    for (var entityType in entityTypes) {
      final collectionName = _getFirestoreCollection(entityType);
      final querySnapshot = await _firebaseService.firestore
          .collection(collectionName)
          .where('companyId', isEqualTo: companyId)
          .get();

      if (querySnapshot.docs.isEmpty) continue;

      final batch = _firebaseService.firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Also hard-delete any firm documents in 'firms' collection
    try {
      final firmsSnapshot = await _firebaseService.firestore
          .collection('firms')
          .where('companyId', isEqualTo: companyId)
          .get();

      if (firmsSnapshot.docs.isNotEmpty) {
        final batch = _firebaseService.firestore.batch();
        for (var doc in firmsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (_) {}

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
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem'
    ];

    for (var entityType in entityTypes) {
      final collectionName = _getFirestoreCollection(entityType);
      final querySnapshot = await _firebaseService.firestore
          .collection(collectionName)
          .where('companyId', isEqualTo: companyId)
          .where('firmId', isEqualTo: activeFirmId)
          .get();

      if (querySnapshot.docs.isEmpty) continue;

      final batch = _firebaseService.firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Uploads all dirty local records marked isSynced == false via batched WriteBatch (max 500 docs per batch)
  Future<void> _uploadLocalChanges() async {
    logger.info('Uploading local dirty changes to Firestore...');
    final uploadStartTime = DateTime.now();
    final queueItems = await _queueService.getPendingQueue();

    if (queueItems.isEmpty) {
      logger.info('No pending changes to upload.');
      return;
    }

    final isar = _dbService.isar;
    final List<Map<String, dynamic>> syncedItems = [];
    final List<int> completedQueueIds = [];

    WriteBatch currentBatch = _firebaseService.firestore.batch();
    int batchOpsCount = 0;

    for (int i = 0; i < queueItems.length; i++) {
      final queueItem = queueItems[i];
      if (queueItem.retryCount >= 5) continue;

      // Yield event loop every 10 items for 60 FPS UI responsiveness & to prevent Vercel 95% hang
      if (i % 10 == 0) {
        await Future.delayed(Duration.zero);
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
          case 'Invoice': entity = await isar.invoices.get(entityId); break;
          case 'Settings': entity = await isar.settings.get(entityId); break;
          case 'User': entity = await isar.users.get(entityId); break;
          case 'Purchase': entity = await isar.purchases.get(entityId); break;
          case 'Expense': entity = await isar.expenses.get(entityId); break;
          case 'Transaction': entity = await isar.transactions.get(entityId); break;
          case 'BankAccount': entity = await isar.bankAccounts.get(entityId); break;
          case 'CreditNote': entity = await isar.creditNotes.get(entityId); break;
          case 'DebitNote': entity = await isar.debitNotes.get(entityId); break;
          case 'StockAdjustment': entity = await isar.collection<StockAdjustment>().get(entityId); break;
        }

        if (entity == null && queueItem.operation != 'Delete') {
          logger.warning('Sync queue item ID ${queueItem.id} not found in database. Skipping.');
          completedQueueIds.add(queueItem.id);
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
          syncedItems.add({'entityType': entityType, 'entity': entity});
        }
        completedQueueIds.add(queueItem.id);

        // Commit WriteBatch if 450 items reached (safely under 500 limit)
        if (batchOpsCount >= 450) {
          await currentBatch.commit().timeout(const Duration(seconds: 8));
          currentBatch = _firebaseService.firestore.batch();
          batchOpsCount = 0;
          await Future.delayed(Duration.zero);
        }
      } catch (e) {
        logger.error('Failed to sync queue item ID ${queueItem.id}', e);
        await _queueService.updateAttempt(queueItem, e.toString());
      }
    }

    // Commit any remaining queued ops in batch with 8s timeout
    if (batchOpsCount > 0) {
      try {
        await currentBatch.commit().timeout(const Duration(seconds: 8));
      } catch (e) {
        logger.error('Failed committing write batch to Firestore', e);
      }
    }

    // Single batched Isar write transaction to mark synced items & atomic queue clearing
    if (syncedItems.isNotEmpty || completedQueueIds.isNotEmpty) {
      await isar.writeTxn(() async {
        for (var itemMap in syncedItems) {
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
          }
        }
        await isar.syncQueues.deleteAll(completedQueueIds);
      });

      // Atomic Queue Clearing before upload start time to prevent clearing edits made during upload
      await _queueService.removeQueueItemsBefore(uploadStartTime);

      logger.info('Batched sync complete: Updated ${syncedItems.length} entities and cleared queue items.');
    }
  }

  /// INSTANT LOW-QUOTA DELTA SYNC ENGINE
  /// Downloads and reconciles remote updates modified after lastSync (where updatedAt > lastSyncTimestamp)
  Future<void> _downloadDeltaRemoteUpdates(DateTime lastSync) async {
    await _downloadRemoteUpdates(lastSync);
  }

  /// Downloads and reconciles remote updates since lastSync (Pull Cloud -> Local)
  Future<void> _downloadRemoteUpdates(DateTime lastSync) async {
    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'Invoice', 'Settings', 'User',
      'Purchase', 'Expense', 'ExpenseItem', 'Transaction', 'BankAccount',
      'CreditNote', 'DebitNote', 'StockAdjustment'
    ];
    final activeFirmId = _dbService.activeFirmId;
    final totalSteps = entityTypes.length + 2;

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
      logger.info('Downloading updates for $collectionName (firm: $activeFirmId)...');

      try {
        final localCount = await _getLocalRecordCount(entityType);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? lastCloudSyncStr = prefs.getString('last_cloud_sync_timestamp_$entityType');
        DateTime? filterCutoff;

        if (lastCloudSyncStr != null && lastCloudSyncStr.isNotEmpty) {
          final parsed = DateTime.tryParse(lastCloudSyncStr);
          if (parsed != null && parsed.millisecondsSinceEpoch > 0) {
            filterCutoff = parsed.subtract(const Duration(minutes: 2));
          }
        }

        var query = _firebaseService.firestore
            .collection(collectionName)
            .where('companyId', isEqualTo: _firebaseService.companyId);

        // Incremental Delta Sync filter by updatedAt only if cloud sync history exists
        if (filterCutoff != null) {
          query = query.where('updatedAt', isGreaterThan: filterCutoff.toUtc().toIso8601String());
        }

        // Enforce strict 8-second timeout per query
        var querySnapshot = await query.get().timeout(const Duration(seconds: 8));
        await Future.delayed(Duration.zero);

        // Update dedicated cloud sync timestamp in SharedPreferences
        await prefs.setString('last_cloud_sync_timestamp_$entityType', DateTime.now().toUtc().toIso8601String());

        // Fallback: If query returned 0 documents and localCount is 0, fetch all for company
        if (querySnapshot.docs.isEmpty && localCount == 0) {
          final fallbackQuery = _firebaseService.firestore
              .collection(collectionName)
              .where('companyId', isEqualTo: _firebaseService.companyId);
          querySnapshot = await fallbackQuery.get().timeout(const Duration(seconds: 8));
        }

        if (querySnapshot.docs.isEmpty) continue;

        for (int d = 0; d < querySnapshot.docs.length; d++) {
          if (d % 10 == 0) await Future.delayed(Duration.zero);

          try {
            final doc = querySnapshot.docs[d];
            final data = doc.data();
            final uuid = data['uuid'] as String?;
            if (uuid == null) continue;

            // Firm-wise filtering
            final docFirmId = data['firmId'] as String?;
            if (docFirmId != null && docFirmId.isNotEmpty && docFirmId != activeFirmId) {
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
            }

            if (localRecord != null) {
              // Local Dirty Lock: If local edit is unsynced (isSynced == false), preserve local draft edits!
              if (localRecord.isSynced == false) {
                logger.info('Conflict: Local Wins (Unsynced Local Draft Lock) for $entityType UUID: $uuid. Keeping local draft.');
                await _logConflictEvent(entityType, uuid, data['version'] as int? ?? 1, localRecord.version, 'Local Wins (Unsynced Draft Lock)');
                continue;
              }

              final localVersion = localRecord.version;
              final remoteVersion = data['version'] as int? ?? 1;
              final localUpdated = localRecord.updatedAt as DateTime;
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

    // Post-download pass: Re-link relations and recalculate item stocks with yielding
    try {
      _updateState(SyncState(
        status: SyncStatus.syncing,
        message: 'Relinking database relationships (96%)...',
        lastSyncTime: _currentState.lastSyncTime,
        progress: 0.96,
        currentStep: totalSteps - 1,
        totalSteps: totalSteps,
      ));
      await _relinkAllRelations();

      _updateState(SyncState(
        status: SyncStatus.syncing,
        message: 'Recalculating inventory stock balances (98%)...',
        lastSyncTime: _currentState.lastSyncTime,
        progress: 0.98,
        currentStep: totalSteps,
        totalSteps: totalSteps,
      ));
      await recalculateAllItemStocksFromTransactions();
      await recalculateAllPartyBalancesFromTransactions();
    } catch (e, stackTrace) {
      logger.warning('Post-download relation re-linking or stock recalculation warning: $e', e, stackTrace);
    }
  }

  /// Post-sync pass: Relinks all unlinked line items (InvoiceItem, PurchaseItem, OrderItem)
  /// Post-sync pass: Relinks all unlinked line items (InvoiceItem, PurchaseItem, OrderItem)
  /// with their respective parent documents by UUID/ID in local DB.
  Future<void> _relinkAllRelations() async {
    final isar = _dbService.isar;
    logger.info('Executing post-sync pass to re-link all line items to parents...');

    try {
      final allInvoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final Map<String, Invoice> invoiceByUuid = {};
      final Map<int, Invoice> invoiceById = {};

      for (int i = 0; i < allInvoices.length; i++) {
        final inv = allInvoices[i];
        if (inv.uuid != null && inv.uuid!.isNotEmpty) {
          invoiceByUuid[inv.uuid!] = inv;
        }
        invoiceById[inv.id] = inv;
      }

      final allInvoiceItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
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
      final allPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final Map<String, Purchase> purchaseByUuid = {};
      final Map<int, Purchase> purchaseById = {};

      for (int i = 0; i < allPurchases.length; i++) {
        final pur = allPurchases[i];
        if (pur.uuid != null && pur.uuid!.isNotEmpty) {
          purchaseByUuid[pur.uuid!] = pur;
        }
        purchaseById[pur.id] = pur;
      }

      final allPurchaseItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();
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
      final parties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
      if (parties.isEmpty) return;

      final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final purchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();

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

      final transactions = await isar.transactions.filter().isDeletedEqualTo(false).findAll();
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
        final uPending = p.uuid != null ? (uuidPending[p.uuid] ?? 0.0) : 0.0;
        final iPending = p.id > 0 ? (idPending[p.id] ?? 0.0) : 0.0;
        final invPending = uPending > 0 ? uPending : iPending;

        final uUnlinked = p.uuid != null ? (uuidUnlinkedCredits[p.uuid] ?? 0.0) : 0.0;
        final netPending = (invPending > 0 ? invPending : (p.openingBalance ?? 0.0)) - uUnlinked;
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
    final isar = _dbService.isar;
    logger.info('Recalculating item stocks dynamically from local transactions...');

    try {
      final allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();
      if (allItems.isEmpty) return;

      final allInvItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
      final allPurItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();
      final allCreditNoteItems = await isar.creditNoteItems.filter().isDeletedEqualTo(false).findAll();
      final allDebitNoteItems = await isar.debitNoteItems.filter().isDeletedEqualTo(false).findAll();

      // Load item links for accuracy with non-blocking async yielding
      for (int i = 0; i < allInvItems.length; i++) { if (i % 20 == 0) await Future.delayed(Duration.zero); try { await allInvItems[i].item.load(); } catch (_) {} }
      for (int i = 0; i < allPurItems.length; i++) { if (i % 20 == 0) await Future.delayed(Duration.zero); try { await allPurItems[i].item.load(); } catch (_) {} }
      for (int i = 0; i < allCreditNoteItems.length; i++) { if (i % 20 == 0) await Future.delayed(Duration.zero); try { await allCreditNoteItems[i].item.load(); } catch (_) {} }
      for (int i = 0; i < allDebitNoteItems.length; i++) { if (i % 20 == 0) await Future.delayed(Duration.zero); try { await allDebitNoteItems[i].item.load(); } catch (_) {} }

      // Filter out deleted parent invoices/purchases
      final allInvoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final validInvIds = allInvoices.map((i) => i.id).toSet();
      final validInvUuids = allInvoices.map((i) => i.uuid).whereType<String>().toSet();

      final allPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final validPurIds = allPurchases.map((p) => p.id).toSet();
      final validPurUuids = allPurchases.map((p) => p.uuid).whereType<String>().toSet();

      final allStockAdjustments = await isar.collection<StockAdjustment>().filter().isDeletedEqualTo(false).findAll();

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

          final linkedUuid = ii.item.value?.uuid;
          final isMatch = (linkedUuid != null && linkedUuid.isNotEmpty && linkedUuid == itemUuid) ||
              (ii.itemName != null && ii.itemName!.trim().toLowerCase() == itemNameLower);

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

          final linkedUuid = pi.item.value?.uuid;
          final isMatch = (linkedUuid != null && linkedUuid.isNotEmpty && linkedUuid == itemUuid) ||
              (pi.itemName != null && pi.itemName!.trim().toLowerCase() == itemNameLower);

          if (isMatch) {
            totalPurchases += _toPrimaryQty(pi.unit, pi.quantity ?? 0.0);
          }
        }

        // 3. Sales Returns / Credit Notes (Stock In)
        double totalSalesReturns = 0.0;
        for (var cni in allCreditNoteItems) {
          final linkedUuid = cni.item.value?.uuid;
          final isMatch = (linkedUuid != null && linkedUuid.isNotEmpty && linkedUuid == itemUuid) ||
              (cni.itemName != null && cni.itemName!.trim().toLowerCase() == itemNameLower);
          if (isMatch) {
            totalSalesReturns += _toPrimaryQty(cni.unit, cni.quantity ?? 0.0);
          }
        }

        // 4. Purchase Returns / Debit Notes (Stock Out)
        double totalPurchaseReturns = 0.0;
        for (var dni in allDebitNoteItems) {
          final linkedUuid = dni.item.value?.uuid;
          final isMatch = (linkedUuid != null && linkedUuid.isNotEmpty && linkedUuid == itemUuid) ||
              (dni.itemName != null && dni.itemName!.trim().toLowerCase() == itemNameLower);
          if (isMatch) {
            totalPurchaseReturns += _toPrimaryQty(dni.unit, dni.quantity ?? 0.0);
          }
        }

        // 5. Manual Stock Adjustments (Stock In / Stock Out)
        double totalAdjustments = 0.0;
        for (var adj in allStockAdjustments) {
          final isMatch = (adj.itemUuid != null && adj.itemUuid!.isNotEmpty && adj.itemUuid == itemUuid) ||
              (adj.itemName != null && adj.itemName!.trim().toLowerCase() == itemNameLower) ||
              (adj.itemId != null && adj.itemId == item.id);
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
          final list = await isar.collection<ExpenseItem>().where().findAll();
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
      default: return entityType.toLowerCase();
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
          'primaryUnitName': e.primaryUnitName ?? e.unit.value?.shortName ?? e.unit.value?.unitName,
          'secondaryUnit': e.secondaryUnit,
          'conversionFactor': e.conversionFactor,
          'barcode': e.barcode,
          'sku': e.sku,
          'skuCode': e.skuCode,
          'imagePaths': e.imagePaths,
          'firebaseImageUrls': e.firebaseImageUrls,
          'thumbnailImage': e.thumbnailImage,
          'categoryUuid': e.category.value?.uuid,
          'unitUuid': e.unit.value?.uuid,
          'brandUuid': e.brand.value?.uuid,
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
          'partyUuid': e.party.value?.uuid,
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
          'orderUuid': e.order.value?.uuid,
          'itemUuid': e.item.value?.uuid,
        });
      case 'Invoice':
        final e = entity as Invoice;
        final isarRef = _dbService.isar;
        final allInvItems = await isarRef.invoiceItems.filter().isDeletedEqualTo(false).findAll();
        final rawItems = allInvItems.where((i) => i.parentInvoiceId == e.id || (e.uuid != null && e.uuid!.isNotEmpty && i.parentInvoiceUuid == e.uuid)).toList();

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
          'partyUuid': e.party.value?.uuid,
          'orderUuid': e.order.value?.uuid,
          'items': itemsMapList,
        });
      case 'InvoiceItem':
        final e = entity as InvoiceItem;
        String? invUuid = e.invoice.value?.uuid;
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
          'itemUuid': e.item.value?.uuid,
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
        final allPurItems = await isarRefP.purchaseItems.filter().isDeletedEqualTo(false).findAll();
        final rawPItems = allPurItems.where((i) => i.purchaseId == e.id || (e.uuid != null && e.uuid!.isNotEmpty && i.purchaseUuid == e.uuid)).toList();

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
          'partyUuid': e.party.value?.uuid,
          'items': pItemsMapList,
        });
      case 'PurchaseItem':
        final e = entity as PurchaseItem;
        String? pUuid = e.purchaseUuid ?? e.purchase.value?.uuid;
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
          'itemUuid': e.item.value?.uuid,
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
          ..reorderLevel = (data['reorderLevel'] as num?)?.toDouble()
          ..minimumStock = (data['minimumStock'] as num?)?.toDouble()
          ..primaryUnitName = (data['primaryUnitName'] as String?)?.isNotEmpty == true ? (data['primaryUnitName'] as String) : ((data['unit'] as String?)?.isNotEmpty == true ? (data['unit'] as String) : null)
          ..secondaryUnit = data['secondaryUnit']
          ..conversionFactor = (data['conversionFactor'] as num?)?.toDouble()
          ..barcode = data['barcode']
          ..sku = data['sku']
          ..skuCode = data['skuCode']
          ..imagePaths = data['imagePaths'] != null ? List<String>.from(data['imagePaths']) : null
          ..firebaseImageUrls = data['firebaseImageUrls'] != null ? List<String>.from(data['firebaseImageUrls']) : null
          ..thumbnailImage = data['thumbnailImage'];
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
          ..totalAmount = (data['totalAmount'] as num?)?.toDouble();
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
    }

    if (entity != null) {
      entity.uuid = data['uuid'];
      entity.createdAt = data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now();
      entity.updatedAt = data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : DateTime.now();
      entity.isDeleted = data['isDeleted'] ?? false;
      entity.isSynced = true;
      entity.version = data['version'] ?? 1;
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
      }
    });

    _linkRemoteRelations(entityType, entity, data);
  }

  /// Inserts a new remote record downloaded into local database
  Future<void> _insertLocalRecord(String entityType, Map<String, dynamic> data) async {
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

  /// Appends log items to Firestore sync_logs collection
  Future<void> _logSyncEvent(String result, String message) async {
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
