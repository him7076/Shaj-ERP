import 'dart:async';
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
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';

enum SyncStatus { idle, syncing, success, failure }

class SyncState {
  final SyncStatus status;
  final String message;
  final DateTime? lastSyncTime;

  const SyncState({
    required this.status,
    required this.message,
    this.lastSyncTime,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
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
    final timestamp = _prefs.getInt(AppConstants.keyLastSyncTime);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    await _prefs.setInt(AppConstants.keyLastSyncTime, time.millisecondsSinceEpoch);
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

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final firmId = data['firmId'] as String? ?? doc.id;
        final firmName = data['firmName'] as String?;
        final isDeleted = data['isDeleted'] as bool? ?? false;

        if (isDeleted) {
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

      // 2. Upload local firms to Firestore if missing
      final batch = _firebaseService.firestore.batch();
      bool hasUploads = false;

      for (var firmId in updatedFirmsList) {
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

  /// Hard-delete a firm document in Firestore
  Future<void> deleteRemoteFirm(String firmId) async {
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) return;
    try {
      final docRef = _firebaseService.firestore.collection('firms').doc(firmId);
      await docRef.delete();
      logger.info('Permanently deleted firm $firmId from Firestore.');
    } catch (e) {
      logger.error('Failed to delete firm $firmId in Firestore', e);
    }
  }

  /// Non-blocking, lightweight background queue upload.
  /// Pushes unsynced changes to Firestore asynchronously WITHOUT running full database downloads or freezing the browser.
  void syncPendingChangesQuietly() {
    Future.microtask(() async {
      try {
        final cloudSyncEnabled = _prefs.getBool('enable_firebase_cloud_sync') ?? true;
        if (!cloudSyncEnabled) return;
        if (_currentState.status == SyncStatus.syncing) return;
        await _firebaseService.ensureAuthenticated();
        if (!_firebaseService.isAuthenticated) return;
        await _uploadLocalChanges();
      } catch (e) {
        logger.warning('Quiet background upload encountered non-fatal error: $e');
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

      // 2. Download remote updates from Firestore
      final lastSync = _currentState.lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final newSyncTime = DateTime.now();

      await _downloadRemoteUpdates(lastSync);

      // 3. Persist successful sync time
      await _saveLastSyncTime(newSyncTime);
      
      // 4. Log successful synchronization
      await _logSyncEvent('Success', 'Full sync completed successfully.');

      logger.info('Firebase sync cycle completed successfully.');
      _updateState(SyncState(
        status: SyncStatus.success,
        message: 'Sync completed successfully',
        lastSyncTime: newSyncTime,
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

    logger.info('Downloading data from Firebase Cloud...');
    _updateState(SyncState(
      status: SyncStatus.syncing,
      message: 'Downloading data from Cloud...',
      lastSyncTime: _currentState.lastSyncTime,
    ));

    try {
      await syncFirms();
      final epochStart = DateTime.fromMillisecondsSinceEpoch(0);
      final newSyncTime = DateTime.now();
      await _downloadRemoteUpdates(epochStart);
      await _saveLastSyncTime(newSyncTime);

      _updateState(SyncState(
        status: SyncStatus.success,
        message: 'Downloaded cloud data successfully',
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

    logger.info('Enqueuing all local records & uploading to Firebase Cloud...');
    _updateState(SyncState(
      status: SyncStatus.syncing,
      message: 'Pushing local data to Cloud...',
      lastSyncTime: _currentState.lastSyncTime,
    ));

    try {
      await _queueService.resetAllRetries();
      await _enqueueAllLocalRecordsForUpload(forceAll: true);
      await _uploadLocalChanges();

      final newSyncTime = DateTime.now();
      await _saveLastSyncTime(newSyncTime);

      _updateState(SyncState(
        status: SyncStatus.success,
        message: 'Pushed local data to cloud successfully',
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

  /// Uploads all dirty local records marked isSynced == false
  Future<void> _uploadLocalChanges() async {
    logger.info('Uploading local dirty changes to Firestore...');
    final queueItems = await _queueService.getPendingQueue();

    if (queueItems.isEmpty) {
      logger.info('No pending changes to upload.');
      return;
    }

    for (var queueItem in queueItems) {
      if (queueItem.retryCount >= 5) continue;

      // Yield to Chrome main event loop to keep UI 100% responsive
      await Future.delayed(Duration.zero);

      try {
        final entityType = queueItem.entityType!;
        final entityId = queueItem.entityId!;
        final isar = _dbService.isar;

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
          case 'Transaction': entity = await isar.transactions.get(entityId); break;
          case 'BankAccount': entity = await isar.bankAccounts.get(entityId); break;
          case 'CreditNote': entity = await isar.creditNotes.get(entityId); break;
          case 'CreditNoteItem': entity = await isar.creditNoteItems.get(entityId); break;
          case 'DebitNote': entity = await isar.debitNotes.get(entityId); break;
          case 'DebitNoteItem': entity = await isar.debitNoteItems.get(entityId); break;
        }

        if (entity == null && queueItem.operation != 'Delete') {
          logger.warning('Sync queue item ID ${queueItem.id} not found in database. Skipping.');
          await _queueService.removeQueueItem(queueItem.id);
          continue;
        }

        final firestoreCollection = _getFirestoreCollection(entityType);
        final docRef = _firebaseService.firestore.collection(firestoreCollection).doc(queueItem.entityUuid);

        if (queueItem.operation == 'Delete') {
          await docRef.delete();
          logger.info('Permanently deleted document ${queueItem.entityUuid} from Firestore collection $firestoreCollection');
        } else {
          final map = await _mapEntityToMap(entityType, entity);
          await docRef.set(map, SetOptions(merge: true));
        }

        if (entity != null) {
          entity.isSynced = true;
          await _dbService.isar.writeTxn(() async {
            switch (entityType) {
              case 'Party': await isar.partys.put(entity as Party); break;
              case 'Item': await isar.items.put(entity as Item); break;
              case 'Category': await isar.categorys.put(entity as Category); break;
              case 'Unit': await isar.units.put(entity as Unit); break;
              case 'Brand': await isar.brands.put(entity as Brand); break;
              case 'Order': await isar.orders.put(entity as Order); break;
              case 'OrderItem': await isar.orderItems.put(entity as OrderItem); break;
              case 'Invoice': await isar.invoices.put(entity as Invoice); break;
              case 'InvoiceItem': await isar.invoiceItems.put(entity as InvoiceItem); break;
              case 'Settings': await isar.settings.put(entity as Settings); break;
              case 'User': await isar.users.put(entity as User); break;
              case 'Purchase': await isar.purchases.put(entity as Purchase); break;
              case 'PurchaseItem': await isar.purchaseItems.put(entity as PurchaseItem); break;
              case 'Expense': await isar.expenses.put(entity as Expense); break;
              case 'Transaction': await isar.transactions.put(entity as Transaction); break;
              case 'BankAccount': await isar.bankAccounts.put(entity as BankAccount); break;
              case 'CreditNote': await isar.creditNotes.put(entity as CreditNote); break;
              case 'CreditNoteItem': await isar.creditNoteItems.put(entity as CreditNoteItem); break;
              case 'DebitNote': await isar.debitNotes.put(entity as DebitNote); break;
              case 'DebitNoteItem': await isar.debitNoteItems.put(entity as DebitNoteItem); break;
            }
          });
        }

        await _queueService.removeQueueItem(queueItem.id);
      } catch (e) {
        logger.error('Failed to sync queue item ID ${queueItem.id}', e);
        await _queueService.updateAttempt(queueItem, e.toString());
      }
    }
  }

  /// Downloads and reconciles remote updates since lastSync
  Future<void> _downloadRemoteUpdates(DateTime lastSync) async {
    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User',
      'Purchase', 'PurchaseItem', 'Expense', 'Transaction', 'BankAccount',
      'CreditNote', 'CreditNoteItem', 'DebitNote', 'DebitNoteItem'
    ];
    final activeFirmId = _dbService.activeFirmId;

    for (var entityType in entityTypes) {
      final collectionName = _getFirestoreCollection(entityType);
      logger.info('Downloading updates for $collectionName (firm: $activeFirmId)...');

      try {
        final localCount = await _getLocalRecordCount(entityType);

        var query = _firebaseService.firestore
            .collection(collectionName)
            .where('companyId', isEqualTo: _firebaseService.companyId);

        // If local database has records and lastSync is valid, filter by updatedAt diff
        if (localCount > 0 && lastSync.millisecondsSinceEpoch > 0) {
          query = query.where('updatedAt', isGreaterThan: lastSync.toIso8601String());
        }

        final querySnapshot = await query.get().timeout(const Duration(seconds: 5));

        if (querySnapshot.docs.isEmpty) continue;

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final uuid = data['uuid'] as String?;
          if (uuid == null) continue;

          // Firm-wise filtering
          final docFirmId = data['firmId'] as String?;
          if (docFirmId != null && docFirmId.isNotEmpty) {
            if (docFirmId != activeFirmId) {
              continue; // Skip documents belonging to another firm
            }
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
            case 'OrderItem': localRecord = await isar.orderItems.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'Invoice': localRecord = await isar.invoices.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'InvoiceItem': localRecord = await isar.invoiceItems.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'Settings': localRecord = await isar.settings.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'User': localRecord = await isar.users.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'Purchase': localRecord = await isar.purchases.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'PurchaseItem': localRecord = await isar.purchaseItems.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'Expense': localRecord = await isar.expenses.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'Transaction': localRecord = await isar.transactions.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'BankAccount': localRecord = await isar.bankAccounts.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'CreditNote': localRecord = await isar.creditNotes.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'CreditNoteItem': localRecord = await isar.creditNoteItems.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'DebitNote': localRecord = await isar.debitNotes.filter().uuidEqualTo(uuid).findFirst(); break;
            case 'DebitNoteItem': localRecord = await isar.debitNoteItems.filter().uuidEqualTo(uuid).findFirst(); break;
          }

          if (localRecord != null) {
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
              logger.info('Conflict: Local wins for $entityType UUID: $uuid. Keeping local modifications.');
              await _logConflictEvent(entityType, uuid, remoteVersion, localVersion, 'Local Wins');
            }
          } else {
            logger.info('Inserting new remote record for $entityType UUID: $uuid');
            await _insertLocalRecord(entityType, data);
          }
        }
      } catch (e) {
        logger.warning('Skipped $entityType sync query due to timeout or network: $e');
      }
    }

    // Post-download pass: Ensure all line items are connected to parents in local Isar DB
    await _relinkAllRelations();
  }

  /// Post-sync pass: Relinks all unlinked line items (InvoiceItem, PurchaseItem, OrderItem)
  /// with their respective parent documents by UUID/ID in local DB.
  Future<void> _relinkAllRelations() async {
    final isar = _dbService.isar;
    logger.info('Executing post-sync pass to re-link all line items to parents...');

    try {
      final allInvoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final Map<String, Invoice> invoiceByUuid = {};
      final Map<int, Invoice> invoiceById = {};

      for (var inv in allInvoices) {
        if (inv.uuid != null && inv.uuid!.isNotEmpty) {
          invoiceByUuid[inv.uuid!] = inv;
        }
        invoiceById[inv.id] = inv;
      }

      final allInvoiceItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();

      await isar.writeTxn(() async {
        for (var item in allInvoiceItems) {
          Invoice? parent;
          try { await item.invoice.load(); parent = item.invoice.value; } catch (_) {}

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
            await isar.invoiceItems.put(item);
            try { await item.invoice.save(); } catch (_) {}
          }
        }
      });

      // Relink PurchaseItems
      final allPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final Map<String, Purchase> purchaseByUuid = {};
      final Map<int, Purchase> purchaseById = {};

      for (var pur in allPurchases) {
        if (pur.uuid != null && pur.uuid!.isNotEmpty) {
          purchaseByUuid[pur.uuid!] = pur;
        }
        purchaseById[pur.id] = pur;
      }

      final allPurchaseItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();

      await isar.writeTxn(() async {
        for (var item in allPurchaseItems) {
          Purchase? parent;
          try { await item.purchase.load(); parent = item.purchase.value; } catch (_) {}

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
            await isar.purchaseItems.put(item);
            try { await item.purchase.save(); } catch (_) {}
          }
        }
      });
    } catch (e) {
      logger.error('Error during post-sync relation re-linking pass', e);
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
        case 'Transaction': return await isar.transactions.filter().idGreaterThan(-1).count();
        default: return 0;
      }
    } catch (_) {
      return 0;
    }
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
      case 'Transaction': return 'transactions';
      case 'BankAccount': return 'bank_accounts';
      case 'CreditNote': return 'credit_notes';
      case 'CreditNoteItem': return 'credit_note_items';
      case 'DebitNote': return 'debit_notes';
      case 'DebitNoteItem': return 'debit_note_items';
      default: return entityType.toLowerCase();
    }
  }

  /// Maps Isar entity to JSON map for Firestore
  Future<Map<String, dynamic>> _mapEntityToMap(String entityType, dynamic entity) async {
    final baseMap = {
      'uuid': entity.uuid,
      'createdAt': entity.createdAt.toIso8601String(),
      'updatedAt': entity.updatedAt.toIso8601String(),
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
        return baseMap..addAll({
          'category': e.category,
          'amount': e.amount,
          'expenseDate': e.expenseDate?.toIso8601String(),
          'paymentMode': e.paymentMode,
          'remarks': e.remarks,
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
          ..openingStock = (data['openingStock'] as num?)?.toDouble()
          ..currentStock = (data['currentStock'] as num?)?.toDouble() ?? (data['stock'] as num?)?.toDouble()
          ..reorderLevel = (data['reorderLevel'] as num?)?.toDouble()
          ..minimumStock = (data['minimumStock'] as num?)?.toDouble()
          ..primaryUnitName = (data['primaryUnitName'] as String?)?.isNotEmpty == true ? (data['primaryUnitName'] as String) : (data['unit'] as String? ?? 'PCS')
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
        entity = Expense()
          ..category = data['category']
          ..amount = (data['amount'] as num?)?.toDouble()
          ..expenseDate = data['expenseDate'] != null ? DateTime.parse(data['expenseDate']) : null
          ..paymentMode = data['paymentMode']
          ..remarks = data['remarks'];
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
        case 'Transaction': await _dbService.isar.transactions.put(entity as Transaction); break;
        case 'BankAccount': await _dbService.isar.bankAccounts.put(entity as BankAccount); break;
        case 'CreditNote': await _dbService.isar.creditNotes.put(entity as CreditNote); break;
        case 'CreditNoteItem': await _dbService.isar.creditNoteItems.put(entity as CreditNoteItem); break;
        case 'DebitNote': await _dbService.isar.debitNotes.put(entity as DebitNote); break;
        case 'DebitNoteItem': await _dbService.isar.debitNoteItems.put(entity as DebitNoteItem); break;
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
        case 'Transaction': await _dbService.isar.transactions.put(entity as Transaction); break;
        case 'BankAccount': await _dbService.isar.bankAccounts.put(entity as BankAccount); break;
        case 'CreditNote': await _dbService.isar.creditNotes.put(entity as CreditNote); break;
        case 'CreditNoteItem': await _dbService.isar.creditNoteItems.put(entity as CreditNoteItem); break;
        case 'DebitNote': await _dbService.isar.debitNotes.put(entity as DebitNote); break;
        case 'DebitNoteItem': await _dbService.isar.debitNoteItems.put(entity as DebitNoteItem); break;
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
        if (data.containsKey('items') && data['items'] is List) {
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
        if (data.containsKey('items') && data['items'] is List) {
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
