import 'dart:async';
import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order, Settings;
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
    // Default to epoch if first time
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    await _prefs.setInt(AppConstants.keyLastSyncTime, time.millisecondsSinceEpoch);
    _currentState = _currentState.copyWith(lastSyncTime: time);
  }

  /// Triggers full synchronization of all collections: upload edits, download changes, resolve conflicts
  Future<void> syncAll() async {
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

  /// Deletes all documents belonging to the active company context from Firestore.
  Future<void> clearCloudData() async {
    await _firebaseService.ensureAuthenticated();
    if (!_firebaseService.isAuthenticated) {
      throw StateError('Firebase authentication failed. Enable Anonymous login in console.');
    }

    final companyId = _firebaseService.companyId;
    final entityTypes = [
      'Category', 'Unit', 'Brand', 'Party', 'Item',
      'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User'
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
      // If retry threshold is reached, skip for SyncManager retry loop
      if (queueItem.retryCount >= 5) continue;

      try {
        final entityType = queueItem.entityType!;
        final entityId = queueItem.entityId!;
        final isar = _dbService.isar;

        // Fetch local entity details dynamically
        dynamic entity;
        switch (entityType) {
          case 'Party':
            entity = await isar.partys.get(entityId);
            break;
          case 'Item':
            entity = await isar.items.get(entityId);
            break;
          case 'Category':
            entity = await isar.categorys.get(entityId);
            break;
          case 'Unit':
            entity = await isar.units.get(entityId);
            break;
          case 'Brand':
            entity = await isar.brands.get(entityId);
            break;
          case 'Order':
            entity = await isar.orders.get(entityId);
            break;
          case 'OrderItem':
            entity = await isar.orderItems.get(entityId);
            break;
          case 'Invoice':
            entity = await isar.invoices.get(entityId);
            break;
          case 'InvoiceItem':
            entity = await isar.invoiceItems.get(entityId);
            break;
          case 'Settings':
            entity = await isar.settings.get(entityId);
            break;
          case 'User':
            entity = await isar.users.get(entityId);
            break;
        }

        if (entity == null && queueItem.operation != 'Delete') {
          logger.warning('Sync queue item ID ${queueItem.id} not found in database. Skipping.');
          await _queueService.removeQueueItem(queueItem.id);
          continue;
        }

        // Prepare document payload
        final firestoreCollection = _getFirestoreCollection(entityType);
        final docRef = _firebaseService.firestore.collection(firestoreCollection).doc(queueItem.entityUuid);

        if (queueItem.operation == 'Delete') {
          // Sync deletion as a soft-delete
          await docRef.set({
            'uuid': queueItem.entityUuid,
            'isDeleted': true,
            'isSynced': true,
            'updatedAt': DateTime.now().toIso8601String(),
            'version': queueItem.version,
            'deviceId': _firebaseService.deviceId,
            'lastModifiedBy': _firebaseService.currentUserEmail ?? 'admin@sahaj.com',
            'companyId': _firebaseService.companyId,
          }, SetOptions(merge: true));
        } else {
          // Sync inserts/updates
          final map = _mapEntityToMap(entityType, entity);
          await docRef.set(map);
        }

        // On success: update local DB record to state isSynced = true (skip adding to SyncQueue)
        if (entity != null) {
          entity.isSynced = true;
          await _dbService.isar.writeTxn(() async {
            switch (entityType) {
              case 'Party':
                await isar.partys.put(entity as Party);
                break;
              case 'Item':
                await isar.items.put(entity as Item);
                break;
              case 'Category':
                await isar.categorys.put(entity as Category);
                break;
              case 'Unit':
                await isar.units.put(entity as Unit);
                break;
              case 'Brand':
                await isar.brands.put(entity as Brand);
                break;
              case 'Order':
                await isar.orders.put(entity as Order);
                break;
              case 'OrderItem':
                await isar.orderItems.put(entity as OrderItem);
                break;
              case 'Invoice':
                await isar.invoices.put(entity as Invoice);
                break;
              case 'InvoiceItem':
                await isar.invoiceItems.put(entity as InvoiceItem);
                break;
              case 'Settings':
                await isar.settings.put(entity as Settings);
                break;
              case 'User':
                await isar.users.put(entity as User);
                break;
            }
          });
        }

        // Delete from local queue
        await _queueService.removeQueueItem(queueItem.id);
      } catch (e) {
        logger.error('Failed to sync queue item ID ${queueItem.id}', e);
        await _queueService.updateAttempt(queueItem, e.toString());
      }
    }
  }

  /// Downloads and reconciles remote updates since lastSync
  Future<void> _downloadRemoteUpdates(DateTime lastSync) async {
    final entityTypes = ['Category', 'Unit', 'Brand', 'Party', 'Item', 'Order', 'OrderItem', 'Invoice', 'InvoiceItem', 'Settings', 'User'];

    for (var entityType in entityTypes) {
      final collectionName = _getFirestoreCollection(entityType);
      logger.info('Downloading updates for $collectionName...');

      final querySnapshot = await _firebaseService.firestore
          .collection(collectionName)
          .where('companyId', isEqualTo: _firebaseService.companyId)
          .where('updatedAt', isGreaterThan: lastSync.toIso8601String())
          .get();

      if (querySnapshot.docs.isEmpty) continue;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final uuid = data['uuid'] as String;

        // Resolve local record in database
        final isar = _dbService.isar;
        dynamic localRecord;
        
        switch (entityType) {
          case 'Party':
            localRecord = await isar.partys.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'Item':
            localRecord = await isar.items.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'Category':
            localRecord = await isar.categorys.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'Unit':
            localRecord = await isar.units.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'Brand':
            localRecord = await isar.brands.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'Order':
            localRecord = await isar.orders.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'OrderItem':
            localRecord = await isar.orderItems.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'Invoice':
            localRecord = await isar.invoices.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'InvoiceItem':
            localRecord = await isar.invoiceItems.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'Settings':
            localRecord = await isar.settings.filter().uuidEqualTo(uuid).findFirst();
            break;
          case 'User':
            localRecord = await isar.users.filter().uuidEqualTo(uuid).findFirst();
            break;
        }

        if (localRecord != null) {
          // Reconcile conflicts
          final localVersion = localRecord.version;
          final remoteVersion = data['version'] as int;
          final localUpdated = localRecord.updatedAt as DateTime;
          final remoteUpdated = DateTime.parse(data['updatedAt'] as String);

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
          // Record doesn't exist, create it locally
          logger.info('Inserting new remote record for $entityType UUID: $uuid');
          await _insertLocalRecord(entityType, data);
        }
      }
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
      default: return entityType.toLowerCase();
    }
  }

  /// Maps Isar entity to JSON map for Firestore
  Map<String, dynamic> _mapEntityToMap(String entityType, dynamic entity) {
    final baseMap = {
      'uuid': entity.uuid,
      'createdAt': entity.createdAt.toIso8601String(),
      'updatedAt': entity.updatedAt.toIso8601String(),
      'version': entity.version,
      'isDeleted': entity.isDeleted,
      'deviceId': _firebaseService.deviceId,
      'lastModifiedBy': _firebaseService.currentUserEmail ?? 'admin@sahaj.com',
      'companyId': _firebaseService.companyId,
    };

    switch (entityType) {
      case 'Party':
        final e = entity as Party;
        return baseMap..addAll({
          'partyName': e.partyName,
          'gstNumber': e.gstNumber,
          'mobileNumber': e.mobileNumber,
          'whatsappNumber': e.whatsappNumber,
          'email': e.email,
          'addressLine1': e.addressLine1,
          'addressLine2': e.addressLine2,
          'city': e.city,
          'state': e.state,
          'pincode': e.pincode,
          'latitude': e.latitude,
          'longitude': e.longitude,
          'creditLimit': e.creditLimit,
          'paymentTerms': e.paymentTerms,
          'notes': e.notes,
        });
      case 'Item':
        final e = entity as Item;
        return baseMap..addAll({
          'itemName': e.itemName,
          'hsnCode': e.hsnCode,
          'barcode': e.barcode,
          'gstRate': e.gstRate,
          'buyRate': e.buyRate,
          'sellRate': e.sellRate,
          'sku': e.sku,
          'description': e.description,
          'imagePaths': e.imagePaths,
          'currentStock': e.currentStock,
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
        });
      case 'InvoiceItem':
        final e = entity as InvoiceItem;
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
          'invoiceUuid': e.invoice.value?.uuid,
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
          ..partyName = data['partyName']
          ..gstNumber = data['gstNumber']
          ..mobileNumber = data['mobileNumber']
          ..whatsappNumber = data['whatsappNumber']
          ..email = data['email']
          ..addressLine1 = data['addressLine1']
          ..addressLine2 = data['addressLine2']
          ..city = data['city']
          ..state = data['state']
          ..pincode = data['pincode']
          ..latitude = data['latitude']
          ..longitude = data['longitude']
          ..creditLimit = data['creditLimit']
          ..paymentTerms = data['paymentTerms']
          ..notes = data['notes'];
        break;
      case 'Item':
        entity = Item()
          ..itemName = data['itemName']
          ..hsnCode = data['hsnCode']
          ..barcode = data['barcode']
          ..gstRate = data['gstRate']
          ..buyRate = data['buyRate']
          ..sellRate = data['sellRate']
          ..sku = data['sku']
          ..description = data['description']
          ..imagePaths = data['imagePaths'] != null ? List<String>.from(data['imagePaths']) : null
          ..currentStock = data['currentStock'] ?? data['stock'];
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
          ..quantity = (data['quantity'] as num?)?.toDouble()
          ..freeQuantity = (data['freeQuantity'] as num?)?.toDouble()
          ..rate = (data['rate'] as num?)?.toDouble()
          ..discount = (data['discount'] as num?)?.toDouble()
          ..taxableAmount = (data['taxableAmount'] as num?)?.toDouble()
          ..gstRate = (data['gstRate'] as num?)?.toDouble()
          ..gstAmount = (data['gstAmount'] as num?)?.toDouble()
          ..totalAmount = (data['totalAmount'] as num?)?.toDouble();
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
    }

    if (entity != null) {
      entity.uuid = data['uuid'];
      entity.createdAt = DateTime.parse(data['createdAt']);
      entity.updatedAt = DateTime.parse(data['updatedAt']);
      entity.isDeleted = data['isDeleted'];
      entity.isSynced = true;
      entity.version = data['version'];
    }

    return entity;
  }

  /// Overwrites an existing local record with downloaded updates
  Future<void> _overwriteLocalRecord(String entityType, Id localId, Map<String, dynamic> data) async {
    final entity = _mapMapToEntity(entityType, data);
    entity.id = localId;
    
    await _dbService.isar.writeTxn(() async {
      switch (entityType) {
        case 'Party':
          await _dbService.isar.partys.put(entity as Party);
          break;
        case 'Item':
          await _dbService.isar.items.put(entity as Item);
          break;
        case 'Category':
          await _dbService.isar.categorys.put(entity as Category);
          break;
        case 'Unit':
          await _dbService.isar.units.put(entity as Unit);
          break;
        case 'Brand':
          await _dbService.isar.brands.put(entity as Brand);
          break;
        case 'Order':
          await _dbService.isar.orders.put(entity as Order);
          break;
        case 'OrderItem':
          await _dbService.isar.orderItems.put(entity as OrderItem);
          break;
        case 'Invoice':
          await _dbService.isar.invoices.put(entity as Invoice);
          break;
        case 'InvoiceItem':
          await _dbService.isar.invoiceItems.put(entity as InvoiceItem);
          break;
        case 'Settings':
          await _dbService.isar.settings.put(entity as Settings);
          break;
        case 'User':
          await _dbService.isar.users.put(entity as User);
          break;
      }
    });

    // Re-resolve remote relationship references asynchronously
    _linkRemoteRelations(entityType, entity, data);
  }

  /// Inserts a new remote record downloaded into local database
  Future<void> _insertLocalRecord(String entityType, Map<String, dynamic> data) async {
    final entity = _mapMapToEntity(entityType, data);
    
    await _dbService.isar.writeTxn(() async {
      switch (entityType) {
        case 'Party':
          await _dbService.isar.partys.put(entity as Party);
          break;
        case 'Item':
          await _dbService.isar.items.put(entity as Item);
          break;
        case 'Category':
          await _dbService.isar.categorys.put(entity as Category);
          break;
        case 'Unit':
          await _dbService.isar.units.put(entity as Unit);
          break;
        case 'Brand':
          await _dbService.isar.brands.put(entity as Brand);
          break;
        case 'Order':
          await _dbService.isar.orders.put(entity as Order);
          break;
        case 'OrderItem':
          await _dbService.isar.orderItems.put(entity as OrderItem);
          break;
        case 'Invoice':
          await _dbService.isar.invoices.put(entity as Invoice);
          break;
        case 'InvoiceItem':
          await _dbService.isar.invoiceItems.put(entity as InvoiceItem);
          break;
        case 'Settings':
          await _dbService.isar.settings.put(entity as Settings);
          break;
        case 'User':
          await _dbService.isar.users.put(entity as User);
          break;
      }
    });

    // Link remote relationships
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
      } else if (entityType == 'InvoiceItem') {
        final e = entity as InvoiceItem;
        final invoiceUuid = data['invoiceUuid'] as String?;
        final itemUuid = data['itemUuid'] as String?;

        if (invoiceUuid != null) {
          e.invoice.value = await isar.invoices.filter().uuidEqualTo(invoiceUuid).findFirst();
        }
        if (itemUuid != null) {
          e.item.value = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
        }

        await isar.writeTxn(() async {
          await e.invoice.save();
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
      });
    } catch (e) {
      logger.error('Failed to write conflict log entry to Firestore', e);
    }
  }

  void dispose() {
    _stateController.close();
  }
}
