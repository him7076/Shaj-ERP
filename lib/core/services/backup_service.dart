import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/compression_service.dart';
import 'package:business_sahaj_erp/core/services/encryption_service.dart';
import 'package:business_sahaj_erp/core/services/google_drive_service.dart';
import 'package:business_sahaj_erp/domain/models/backup_metadata.dart';
import 'package:business_sahaj_erp/domain/models/backup_history_entry.dart';

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

class BackupService {
  final DatabaseService _dbService;
  final CompressionService _compressionService;
  final EncryptionService _encryptionService;
  final GoogleDriveService _driveService;
  final SharedPreferences _prefs;

  static const String _keyBackupHistory = 'backup_history_list';

  BackupService(
    this._dbService,
    this._compressionService,
    this._encryptionService,
    this._driveService,
    this._prefs,
  );

  /// Formats date to simple string: yyyy_MM_dd_HH_mm
  String _formatDateString(DateTime dt) {
    return '${dt.year}_'
        '${dt.month.toString().padLeft(2, '0')}_'
        '${dt.day.toString().padLeft(2, '0')}_'
        '${dt.hour.toString().padLeft(2, '0')}_'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Triggers full system backup
  Future<BackupHistoryEntry> createBackup({
    String? password,
    bool includeImages = true,
    bool uploadToCloud = false,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final backupTimestamp = DateTime.now();
    final backupId = backupTimestamp.millisecondsSinceEpoch;
    final tempBackupFolder = Directory('${tempDir.path}/backup_$backupId');
    await tempBackupFolder.create(recursive: true);

    try {
      logger.info('Starting backup generation...');
      final isar = _dbService.isar;

      // 1. Export Isar Collections to temporary JSON files
      final collections = {
        'categories': await isar.categorys.where().findAll(),
        'units': await isar.units.where().findAll(),
        'brands': await isar.brands.where().findAll(),
        'parties': await isar.partys.where().findAll(),
        'items': await isar.items.where().findAll(),
        'orders': await isar.orders.where().findAll(),
        'order_items': await isar.orderItems.where().findAll(),
        'invoices': await isar.invoices.where().findAll(),
        'invoice_items': await isar.invoiceItems.where().findAll(),
        'settings': await isar.settings.where().findAll(),
        'users': await isar.users.where().findAll(),
        'sync_queues': await isar.syncQueues.where().findAll(),
      };

      final List<File> tempJsonFiles = [];
      for (var entry in collections.entries) {
        final jsonList = entry.value.map((e) => _mapEntityToMap(entry.key, e)).toList();
        final file = File('${tempBackupFolder.path}/${entry.key}.json');
        await file.writeAsString(jsonEncode(jsonList));
        tempJsonFiles.add(file);
      }

      // 2. Export Metadata Header
      final metadata = BackupMetadata(
        appVersion: '1.0.0',
        databaseVersion: DatabaseService.currentDatabaseVersion,
        backupDate: backupTimestamp,
        hasPassword: password != null && password.isNotEmpty,
        includeImages: includeImages,
        collectionsList: collections.keys.toList(),
      );
      final metaFile = File('${tempBackupFolder.path}/metadata.json');
      await metaFile.writeAsString(jsonEncode(metadata.toJson()));
      tempJsonFiles.add(metaFile);

      // 3. Collect Images if selected
      Directory? imagesDir;
      if (includeImages) {
        final appDocsDir = await getApplicationDocumentsDirectory();
        imagesDir = Directory('${appDocsDir.path}/product_images');
      }

      // 4. Create ZIP archive
      final zipFilename = 'BusinessSahaj_${_formatDateString(backupTimestamp)}.zip';
      final zipTempPath = '${tempDir.path}/$zipFilename';
      await _compressionService.createBackupArchive(
        jsonFiles: tempJsonFiles,
        imagesDir: imagesDir,
        destZipPath: zipTempPath,
      );

      // 5. Final target file with custom extension
      final bserpFilename = 'BusinessSahaj_${_formatDateString(backupTimestamp)}.bserp';
      final appDocsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocsDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final localDestPath = '${backupDir.path}/$bserpFilename';

      // 6. Encrypt if password is set
      if (password != null && password.isNotEmpty) {
        await _encryptionService.encryptFile(
          srcPath: zipTempPath,
          destPath: localDestPath,
          password: password,
        );
        // Clean temporary zip
        await File(zipTempPath).delete();
      } else {
        // Just rename/move zip file to target
        await File(zipTempPath).rename(localDestPath);
      }

      final backupFile = File(localDestPath);
      final sizeInBytes = await backupFile.length();

      // 7. If Cloud sync is requested, upload to Google Drive
      String finalLocation = localDestPath;
      bool isCloudSaved = false;

      if (uploadToCloud) {
        try {
          if (!_driveService.isSignedIn) {
            await _driveService.signIn();
          }
          final driveFileId = await _driveService.uploadBackup(backupFile, bserpFilename);
          finalLocation = driveFileId;
          isCloudSaved = true;
          logger.info('Backup successfully uploaded to Google Drive. File ID: $driveFileId');
        } catch (cloudError) {
          logger.error('Failed to sync backup to Google Drive. Retaining local backup.', cloudError);
          // Don't fail the entire backup, register it as local backup.
        }
      }

      // 8. Register in SharedPreferences History
      final historyEntry = BackupHistoryEntry(
        backupName: bserpFilename,
        date: backupTimestamp,
        size: sizeInBytes,
        location: finalLocation,
        isCloud: isCloudSaved,
        isEncrypted: password != null && password.isNotEmpty,
      );

      await _registerBackupInHistory(historyEntry);

      // 9. Clean temporary export files
      await tempBackupFolder.delete(recursive: true);

      // 10. Run Auto Cleanup
      await autoCleanupBackups();

      logger.info('System backup generated successfully: $bserpFilename (${sizeInBytes} bytes)');
      return historyEntry;
    } catch (e, stackTrace) {
      logger.error('System backup execution failed', e, stackTrace);
      // Ensure temp folder is cleaned up on failure
      if (await tempBackupFolder.exists()) {
        await tempBackupFolder.delete(recursive: true);
      }
      throw BackupException('System backup execution failed: $e');
    }
  }

  /// Appends backup entry into registry history list
  Future<void> _registerBackupInHistory(BackupHistoryEntry entry) async {
    final currentHistory = await getBackupHistory();
    currentHistory.insert(0, entry); // latest first
    final serialized = currentHistory.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyBackupHistory, jsonEncode(serialized));
  }

  /// Retrieves the history list from registry
  Future<List<BackupHistoryEntry>> getBackupHistory() async {
    final historyString = _prefs.getString(_keyBackupHistory);
    if (historyString == null) return [];
    try {
      final List decoded = jsonDecode(historyString);
      return decoded.map((e) => BackupHistoryEntry.fromJson(e)).toList();
    } catch (e) {
      logger.error('Failed to decode backup history list', e);
      return [];
    }
  }

  /// Removes an entry from backup history and deletes files
  Future<void> deleteBackup(BackupHistoryEntry entry) async {
    try {
      logger.info('Deleting backup: ${entry.backupName}');

      // Delete file locally or on cloud
      if (entry.isCloud) {
        await _driveService.deleteBackup(entry.location);
      } else {
        final file = File(entry.location);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from preferences
      final history = await getBackupHistory();
      history.removeWhere((e) => e.location == entry.location);
      final serialized = history.map((e) => e.toJson()).toList();
      await _prefs.setString(_keyBackupHistory, jsonEncode(serialized));

      logger.info('Backup deleted successfully.');
    } catch (e) {
      logger.error('Failed to delete backup', e);
      throw BackupException('Failed to delete backup: $e');
    }
  }

  /// Deletes older backups automatically keeping last N settings
  Future<void> autoCleanupBackups() async {
    final limitString = _prefs.getString('backup_cleanup_limit') ?? 'keep_10';
    if (limitString == 'unlimited') return;

    int keepLimit = 10;
    if (limitString == 'keep_5') {
      keepLimit = 5;
    } else if (limitString == 'keep_10') {
      keepLimit = 10;
    }

    try {
      final history = await getBackupHistory();
      if (history.length <= keepLimit) return;

      logger.info('Auto backup cleanup triggered. Current size: ${history.length}, Limit: $keepLimit');
      
      // Identify entries to remove (index keepLimit and onwards are the oldest ones)
      final entriesToRemove = history.sublist(keepLimit);
      for (var entry in entriesToRemove) {
        await deleteBackup(entry);
      }
    } catch (e) {
      logger.error('Failed running automatic backup cleanup', e);
    }
  }

  /// Serialize Isar models to Map
  Map<String, dynamic> _mapEntityToMap(String type, dynamic entity) {
    final baseMap = {
      'id': entity.id,
      'uuid': entity.uuid,
      'createdAt': entity.createdAt.toIso8601String(),
      'updatedAt': entity.updatedAt.toIso8601String(),
      'isDeleted': entity.isDeleted,
      'isSynced': entity.isSynced,
      'version': entity.version,
    };

    switch (type) {
      case 'categories':
        final e = entity as Category;
        return baseMap..addAll({
          'categoryName': e.categoryName,
          'description': e.description,
          'parentCategoryUuid': e.parentCategory.value?.uuid,
        });
      case 'units':
        final e = entity as Unit;
        return baseMap..addAll({
          'unitName': e.unitName,
          'shortName': e.shortName,
        });
      case 'brands':
        final e = entity as Brand;
        return baseMap..addAll({
          'brandName': e.brandName,
        });
      case 'parties':
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
          'outstandingBalance': e.outstandingBalance,
        });
      case 'items':
        final e = entity as Item;
        return baseMap..addAll({
          'itemName': e.itemName,
          'shortName': e.shortName,
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
          'secondaryUnit': e.secondaryUnit,
          'conversionFactor': e.conversionFactor,
          'barcode': e.barcode,
          'sku': e.sku,
          'skuCode': e.skuCode,
          'imagePaths': e.imagePaths,
          'firebaseImageUrls': e.firebaseImageUrls,
          'thumbnailImage': e.thumbnailImage,
          'weight': e.weight,
          'dimensions': e.dimensions,
          'notes': e.notes,
          'categoryUuid': e.category.value?.uuid,
          'unitUuid': e.unit.value?.uuid,
          'brandUuid': e.brand.value?.uuid,
        });
      case 'orders':
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
      case 'order_items':
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
      case 'invoices':
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
      case 'invoice_items':
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
      case 'settings':
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
      case 'users':
        final e = entity as User;
        return baseMap..addAll({
          'name': e.name,
          'email': e.email,
          'role': e.role,
        });
      case 'sync_queues':
        final e = entity as SyncQueue;
        return {
          'id': e.id,
          'uuid': e.uuid,
          'entityType': e.entityType,
          'entityId': e.entityId,
          'entityUuid': e.entityUuid,
          'operation': e.operation,
          'retryCount': e.retryCount,
          'lastError': e.lastError,
          'createdAt': e.createdAt?.toIso8601String(),
          'updatedAt': e.updatedAt?.toIso8601String(),
        };
      default:
        return baseMap;
    }
  }
}
