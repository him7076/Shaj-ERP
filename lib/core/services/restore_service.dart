import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/compression_service.dart';
import 'package:business_sahaj_erp/core/services/encryption_service.dart';
import 'package:business_sahaj_erp/domain/models/backup_metadata.dart';

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

class RestoreService {
  final DatabaseService _dbService;
  final CompressionService _compressionService;
  final EncryptionService _encryptionService;

  RestoreService(
    this._dbService,
    this._compressionService,
    this._encryptionService,
  );

  /// Validates a backup file. Returns BackupMetadata if valid.
  /// If backup is encrypted and password is correct, returns metadata.
  /// Throws [EncryptionException] if password is wrong or required but missing.
  Future<BackupMetadata> validateBackup(String filePath, {String? password}) async {
    final tempDir = await getTemporaryDirectory();
    final tempExtractPath = '${tempDir.path}/meta_extract_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(tempExtractPath).create(recursive: true);

    String zipToExtract = filePath;
    bool isTemporaryDecryptedFile = false;

    try {
      // 1. Try to check if zip can be parsed. If not, and password is provided, try to decrypt.
      final fileBytes = await File(filePath).readAsBytes();
      bool isEncrypted = false;
      
      // A valid ZIP starts with the bytes 'PK' (0x50, 0x4B)
      if (fileBytes.length < 2 || fileBytes[0] != 0x50 || fileBytes[1] != 0x4B) {
        isEncrypted = true;
      }

      if (isEncrypted) {
        if (password == null || password.isEmpty) {
          throw const EncryptionException('This backup file is encrypted. Please enter a password.');
        }

        final decryptedZipPath = '${tempDir.path}/decrypted_${DateTime.now().millisecondsSinceEpoch}.zip';
        await _encryptionService.decryptFile(
          srcPath: filePath,
          destPath: decryptedZipPath,
          password: password,
        );
        zipToExtract = decryptedZipPath;
        isTemporaryDecryptedFile = true;
      }

      // 2. Extract only metadata.json to validate
      await _compressionService.extractBackupArchive(
        zipPath: zipToExtract,
        destExtractDir: tempExtractPath,
      );

      final metaFile = File('$tempExtractPath/metadata.json');
      if (!await metaFile.exists()) {
        throw const CorruptedBackupException('Invalid backup archive: missing metadata header.');
      }

      final metaContent = await metaFile.readAsString();
      final metadata = BackupMetadata.fromJson(jsonDecode(metaContent));

      // 3. Clean up temp files
      await Directory(tempExtractPath).delete(recursive: true);
      if (isTemporaryDecryptedFile) {
        await File(zipToExtract).delete();
      }

      // 4. Validate DB schema compatibility
      if (metadata.databaseVersion > DatabaseService.currentDatabaseVersion) {
        throw RestoreException(
          'Incompatible database version. Backup version is v${metadata.databaseVersion}, '
          'but application only supports up to v${DatabaseService.currentDatabaseVersion}.',
        );
      }

      return metadata;
    } catch (e) {
      // Cleanup temp directories on error
      if (await Directory(tempExtractPath).exists()) {
        await Directory(tempExtractPath).delete(recursive: true);
      }
      if (isTemporaryDecryptedFile && await File(zipToExtract).exists()) {
        await File(zipToExtract).delete();
      }
      rethrow;
    }
  }

  /// Restores database collections and images.
  /// [duplicateStrategy] options: 'replace', 'merge', 'skip'
  Future<void> restoreBackup(
    String filePath, {
    String? password,
    bool restoreParties = true,
    bool restoreItems = true,
    bool restoreOrders = true,
    bool restoreInvoices = true,
    bool restoreSettings = true,
    String duplicateStrategy = 'replace',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory('${tempDir.path}/restore_${DateTime.now().millisecondsSinceEpoch}');
    await extractDir.create(recursive: true);

    String zipToExtract = filePath;
    bool isTemporaryDecrypted = false;

    try {
      logger.info('Initiating backup restoration: $filePath');
      
      // 1. Decrypt if needed
      final fileBytes = await File(filePath).readAsBytes();
      bool isEncrypted = fileBytes.length < 2 || fileBytes[0] != 0x50 || fileBytes[1] != 0x4B;

      if (isEncrypted) {
        if (password == null || password.isEmpty) {
          throw const EncryptionException('This backup file is encrypted. Password is required.');
        }
        final decryptedZipPath = '${tempDir.path}/decrypted_restore_${DateTime.now().millisecondsSinceEpoch}.zip';
        await _encryptionService.decryptFile(
          srcPath: filePath,
          destPath: decryptedZipPath,
          password: password,
        );
        zipToExtract = decryptedZipPath;
        isTemporaryDecrypted = true;
      }

      // 2. Extract the archive
      await _compressionService.extractBackupArchive(
        zipPath: zipToExtract,
        destExtractDir: extractDir.path,
      );

      // 3. Read metadata
      final metaFile = File('${extractDir.path}/metadata.json');
      if (!await metaFile.exists()) {
        throw const CorruptedBackupException('Backup metadata header not found.');
      }
      final metadata = BackupMetadata.fromJson(jsonDecode(await metaFile.readAsString()));

      // 4. Copy images back to document folder and rewrite prefixes if directory changed
      final appDocsDir = await getApplicationDocumentsDirectory();
      final targetImagesDir = Directory('${appDocsDir.path}/product_images');
      if (!await targetImagesDir.exists()) {
        await targetImagesDir.create(recursive: true);
      }

      final extractedImagesDir = Directory('${extractDir.path}/images');
      if (await extractedImagesDir.exists()) {
        logger.info('Restoring product images...');
        final files = extractedImagesDir.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            final relativePath = file.path.replaceFirst(extractedImagesDir.path, '');
            final destPath = '${targetImagesDir.path}$relativePath';
            final destFile = File(destPath);
            await destFile.parent.create(recursive: true);
            await file.copy(destPath);
          }
        }
      }

      // 5. Ingest JSON collections back into Isar in strict relationship dependency order
      final isar = _dbService.isar;

      // Restoring Settings
      if (restoreSettings) {
        await _restoreCollection<Settings>(
          jsonFile: File('${extractDir.path}/settings.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToSettings(map),
          putAll: (items) async => await isar.settings.putAll(items),
          deleteByUuids: (uuids) async => await isar.settings.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.settings.filter().uuidEqualTo(uuid).findFirst(),
        );
      }

      // Users
      await _restoreCollection<User>(
        jsonFile: File('${extractDir.path}/users.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToUser(map),
        putAll: (items) async => await isar.users.putAll(items),
        deleteByUuids: (uuids) async => await isar.users.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.users.filter().uuidEqualTo(uuid).findFirst(),
      );

      // Categories
      if (restoreItems) {
        await _restoreCollection<Category>(
          jsonFile: File('${extractDir.path}/categories.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToCategory(map),
          putAll: (items) async => await isar.categorys.putAll(items),
          deleteByUuids: (uuids) async => await isar.categorys.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.categorys.filter().uuidEqualTo(uuid).findFirst(),
        );

        // Re-link Category Parent-Child relations
        final categoriesJsonFile = File('${extractDir.path}/categories.json');
        if (await categoriesJsonFile.exists()) {
          final List list = jsonDecode(await categoriesJsonFile.readAsString());
          await isar.writeTxn(() async {
            for (var itemMap in list) {
              final parentUuid = itemMap['parentCategoryUuid'] as String?;
              if (parentUuid != null) {
                final currentUuid = itemMap['uuid'] as String;
                final current = await isar.categorys.filter().uuidEqualTo(currentUuid).findFirst();
                final parent = await isar.categorys.filter().uuidEqualTo(parentUuid).findFirst();
                if (current != null && parent != null) {
                  current.parentCategory.value = parent;
                  await current.parentCategory.save();
                }
              }
            }
          });
        }
      }

      // Units
      if (restoreItems) {
        await _restoreCollection<Unit>(
          jsonFile: File('${extractDir.path}/units.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToUnit(map),
          putAll: (items) async => await isar.units.putAll(items),
          deleteByUuids: (uuids) async => await isar.units.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.units.filter().uuidEqualTo(uuid).findFirst(),
        );
      }

      // Brands
      if (restoreItems) {
        await _restoreCollection<Brand>(
          jsonFile: File('${extractDir.path}/brands.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToBrand(map),
          putAll: (items) async => await isar.brands.putAll(items),
          deleteByUuids: (uuids) async => await isar.brands.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.brands.filter().uuidEqualTo(uuid).findFirst(),
        );
      }

      // Parties
      if (restoreParties) {
        await _restoreCollection<Party>(
          jsonFile: File('${extractDir.path}/parties.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToParty(map),
          putAll: (items) async => await isar.partys.putAll(items),
          deleteByUuids: (uuids) async => await isar.partys.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.partys.filter().uuidEqualTo(uuid).findFirst(),
        );
      }

      // Items
      if (restoreItems) {
        await _restoreCollection<Item>(
          jsonFile: File('${extractDir.path}/items.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToItem(map, appDocsDir.path), // Rewrites image path prefixes dynamically
          putAll: (items) async => await isar.items.putAll(items),
          deleteByUuids: (uuids) async => await isar.items.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.items.filter().uuidEqualTo(uuid).findFirst(),
        );

        // Re-link category, unit, brand
        final itemsJsonFile = File('${extractDir.path}/items.json');
        if (await itemsJsonFile.exists()) {
          final List list = jsonDecode(await itemsJsonFile.readAsString());
          await isar.writeTxn(() async {
            for (var itemMap in list) {
              final currentUuid = itemMap['uuid'] as String;
              final categoryUuid = itemMap['categoryUuid'] as String?;
              final unitUuid = itemMap['unitUuid'] as String?;
              final brandUuid = itemMap['brandUuid'] as String?;

              final current = await isar.items.filter().uuidEqualTo(currentUuid).findFirst();
              if (current != null) {
                if (categoryUuid != null) {
                  current.category.value = await isar.categorys.filter().uuidEqualTo(categoryUuid).findFirst();
                }
                if (unitUuid != null) {
                  current.unit.value = await isar.units.filter().uuidEqualTo(unitUuid).findFirst();
                }
                if (brandUuid != null) {
                  current.brand.value = await isar.brands.filter().uuidEqualTo(brandUuid).findFirst();
                }
                await current.category.save();
                await current.unit.save();
                await current.brand.save();
              }
            }
          });
        }
      }

      // Orders
      if (restoreOrders) {
        await _restoreCollection<Order>(
          jsonFile: File('${extractDir.path}/orders.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToOrder(map),
          putAll: (items) async => await isar.orders.putAll(items),
          deleteByUuids: (uuids) async => await isar.orders.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.orders.filter().uuidEqualTo(uuid).findFirst(),
        );

        // Re-link Party
        final ordersJsonFile = File('${extractDir.path}/orders.json');
        if (await ordersJsonFile.exists()) {
          final List list = jsonDecode(await ordersJsonFile.readAsString());
          await isar.writeTxn(() async {
            for (var itemMap in list) {
              final currentUuid = itemMap['uuid'] as String;
              final partyUuid = itemMap['partyUuid'] as String?;
              final current = await isar.orders.filter().uuidEqualTo(currentUuid).findFirst();
              if (current != null && partyUuid != null) {
                current.party.value = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
                await current.party.save();
              }
            }
          });
        }

        // Order Items
        await _restoreCollection<OrderItem>(
          jsonFile: File('${extractDir.path}/order_items.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToOrderItem(map),
          putAll: (items) async => await isar.orderItems.putAll(items),
          deleteByUuids: (uuids) async => await isar.orderItems.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.orderItems.filter().uuidEqualTo(uuid).findFirst(),
        );

        // Re-link order, item
        final orderItemsJsonFile = File('${extractDir.path}/order_items.json');
        if (await orderItemsJsonFile.exists()) {
          final List list = jsonDecode(await orderItemsJsonFile.readAsString());
          await isar.writeTxn(() async {
            for (var itemMap in list) {
              final currentUuid = itemMap['uuid'] as String;
              final orderUuid = itemMap['orderUuid'] as String?;
              final itemUuid = itemMap['itemUuid'] as String?;

              final current = await isar.orderItems.filter().uuidEqualTo(currentUuid).findFirst();
              if (current != null) {
                if (orderUuid != null) {
                  current.order.value = await isar.orders.filter().uuidEqualTo(orderUuid).findFirst();
                }
                if (itemUuid != null) {
                  current.item.value = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
                }
                await current.order.save();
                await current.item.save();
              }
            }
          });
        }
      }

      // Invoices
      if (restoreInvoices) {
        await _restoreCollection<Invoice>(
          jsonFile: File('${extractDir.path}/invoices.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToInvoice(map),
          putAll: (items) async => await isar.invoices.putAll(items),
          deleteByUuids: (uuids) async => await isar.invoices.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.invoices.filter().uuidEqualTo(uuid).findFirst(),
        );

        // Re-link party, order
        final invoicesJsonFile = File('${extractDir.path}/invoices.json');
        if (await invoicesJsonFile.exists()) {
          final List list = jsonDecode(await invoicesJsonFile.readAsString());
          await isar.writeTxn(() async {
            for (var itemMap in list) {
              final currentUuid = itemMap['uuid'] as String;
              final partyUuid = itemMap['partyUuid'] as String?;
              final orderUuid = itemMap['orderUuid'] as String?;

              final current = await isar.invoices.filter().uuidEqualTo(currentUuid).findFirst();
              if (current != null) {
                if (partyUuid != null) {
                  current.party.value = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
                }
                if (orderUuid != null) {
                  current.order.value = await isar.orders.filter().uuidEqualTo(orderUuid).findFirst();
                }
                await current.party.save();
                await current.order.save();
              }
            }
          });
        }

        // Invoice Items
        await _restoreCollection<InvoiceItem>(
          jsonFile: File('${extractDir.path}/invoice_items.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToInvoiceItem(map),
          putAll: (items) async => await isar.invoiceItems.putAll(items),
          deleteByUuids: (uuids) async => await isar.invoiceItems.filter().group((q) {
            var filter = q.uuidEqualTo(uuids.first);
            for (var i = 1; i < uuids.length; i++) {
              filter = filter.or().uuidEqualTo(uuids[i]);
            }
            return filter;
          }).deleteAll(),
          findByUuid: (uuid) async => await isar.invoiceItems.filter().uuidEqualTo(uuid).findFirst(),
        );

        // Re-link invoice, item
        final invoiceItemsJsonFile = File('${extractDir.path}/invoice_items.json');
        if (await invoiceItemsJsonFile.exists()) {
          final List list = jsonDecode(await invoiceItemsJsonFile.readAsString());
          await isar.writeTxn(() async {
            for (var itemMap in list) {
              final currentUuid = itemMap['uuid'] as String;
              final invoiceUuid = itemMap['invoiceUuid'] as String?;
              final itemUuid = itemMap['itemUuid'] as String?;

              final current = await isar.invoiceItems.filter().uuidEqualTo(currentUuid).findFirst();
              if (current != null) {
                if (invoiceUuid != null) {
                  current.invoice.value = await isar.invoices.filter().uuidEqualTo(invoiceUuid).findFirst();
                }
                if (itemUuid != null) {
                  current.item.value = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
                }
                await current.invoice.save();
                await current.item.save();
              }
            }
          });
        }
      }

      // Sync Queues
      await _restoreCollection<SyncQueue>(
        jsonFile: File('${extractDir.path}/sync_queues.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToSyncQueue(map),
        putAll: (items) async => await isar.syncQueues.putAll(items),
        deleteByUuids: (uuids) async => await isar.syncQueues.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.syncQueues.filter().uuidEqualTo(uuid).findFirst(),
      );

      // Clean up extracted files
      await extractDir.delete(recursive: true);
      if (isTemporaryDecrypted) {
        await File(zipToExtract).delete();
      }

      logger.info('Restore operation completed successfully.');
    } catch (e, stackTrace) {
      logger.error('Restore operation failed', e, stackTrace);
      // Cleanup temp directories on error
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      if (isTemporaryDecrypted && await File(zipToExtract).exists()) {
        await File(zipToExtract).delete();
      }
      throw RestoreException('Database restore failed: $e');
    }
  }

  /// Internal generic helper to restore an individual collection from a JSON dump
  Future<void> _restoreCollection<T>({
    required File jsonFile,
    required String strategy,
    required T Function(Map<String, dynamic> map) fromMap,
    required Future<void> Function(List<T> items) putAll,
    required Future<void> Function(List<String> uuids) deleteByUuids,
    required Future<dynamic> Function(String uuid) findByUuid,
  }) async {
    if (!await jsonFile.exists()) {
      logger.warning('Backup file ${jsonFile.path} does not exist. Skipping collection restoration.');
      return;
    }

    final fileContent = await jsonFile.readAsString();
    final List decodedList = jsonDecode(fileContent);
    if (decodedList.isEmpty) return;

    final List<T> toPut = [];
    final List<String> uuidsToDelete = [];

    for (var itemMap in decodedList) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(itemMap);
      final uuid = map['uuid'] as String;

      final existingRecord = await findByUuid(uuid);

      if (existingRecord == null) {
        // Record does not exist locally - always insert it
        toPut.add(fromMap(map));
      } else {
        // Record exists locally - resolve conflicts using selected duplicate handling strategy
        if (strategy == 'replace') {
          // Delete existing local record first, and put the new one from backup
          uuidsToDelete.add(uuid);
          toPut.add(fromMap(map));
        } else if (strategy == 'merge') {
          // Merge: Only put if version of backup is higher/newer
          final localVersion = existingRecord.version as int;
          final backupVersion = map['version'] as int? ?? 1;

          if (backupVersion >= localVersion) {
            uuidsToDelete.add(uuid);
            toPut.add(fromMap(map));
          }
        }
        // strategy 'skip': just ignore, do nothing
      }
    }

    if (uuidsToDelete.isNotEmpty || toPut.isNotEmpty) {
      await _dbService.isar.writeTxn(() async {
        if (uuidsToDelete.isNotEmpty) {
          await deleteByUuids(uuidsToDelete);
        }
        if (toPut.isNotEmpty) {
          await putAll(toPut);
        }
      });
    }

    logger.debug('Collection restored from ${jsonFile.path}: ${toPut.length} inserted/updated.');
  }

  // --- Dynamic Model Parsers ---

  /// Helper to dynamically fix local document path prefix if changing mobile device directory structures
  String _rewriteImagePath(String? path, String currentDocsPrefix) {
    if (path == null) return '';
    // Look for product_images or thumbnails separator
    if (path.contains('product_images')) {
      final subPath = path.substring(path.indexOf('product_images'));
      return '$currentDocsPrefix/$subPath';
    }
    if (path.contains('thumbnails')) {
      final subPath = path.substring(path.indexOf('thumbnails'));
      return '$currentDocsPrefix/$subPath';
    }
    return path;
  }

  Settings _mapMapToSettings(Map<String, dynamic> map) {
    return Settings()
      ..uuid = map['uuid']
      ..companyName = map['companyName']
      ..companyGST = map['companyGST']
      ..companyAddress = map['companyAddress']
      ..companyPhone = map['companyPhone']
      ..companyEmail = map['companyEmail']
      ..logoPath = map['logoPath']
      ..themeMode = map['themeMode']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  User _mapMapToUser(Map<String, dynamic> map) {
    return User()
      ..uuid = map['uuid']
      ..name = map['name']
      ..email = map['email']
      ..role = map['role']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Category _mapMapToCategory(Map<String, dynamic> map) {
    return Category()
      ..uuid = map['uuid']
      ..categoryName = map['categoryName']
      ..description = map['description']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Unit _mapMapToUnit(Map<String, dynamic> map) {
    return Unit()
      ..uuid = map['uuid']
      ..unitName = map['unitName']
      ..shortName = map['shortName']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Brand _mapMapToBrand(Map<String, dynamic> map) {
    return Brand()
      ..uuid = map['uuid']
      ..brandName = map['brandName']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Party _mapMapToParty(Map<String, dynamic> map) {
    return Party()
      ..uuid = map['uuid']
      ..partyName = map['partyName']
      ..gstNumber = map['gstNumber']
      ..mobileNumber = map['mobileNumber']
      ..whatsappNumber = map['whatsappNumber']
      ..email = map['email']
      ..addressLine1 = map['addressLine1']
      ..addressLine2 = map['addressLine2']
      ..city = map['city']
      ..state = map['state']
      ..pincode = map['pincode']
      ..latitude = (map['latitude'] as num?)?.toDouble()
      ..longitude = (map['longitude'] as num?)?.toDouble()
      ..creditLimit = (map['creditLimit'] as num?)?.toDouble()
      ..paymentTerms = map['paymentTerms']
      ..notes = map['notes']
      ..outstandingBalance = (map['outstandingBalance'] as num?)?.toDouble()
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Item _mapMapToItem(Map<String, dynamic> map, String currentDocsPrefix) {
    final imagePathsList = map['imagePaths'] != null ? List<String>.from(map['imagePaths']) : <String>[];
    final rewrittenPaths = imagePathsList.map((p) => _rewriteImagePath(p, currentDocsPrefix)).toList();
    final rewrittenThumb = map['thumbnailImage'] != null ? _rewriteImagePath(map['thumbnailImage'] as String, currentDocsPrefix) : null;

    return Item()
      ..uuid = map['uuid']
      ..itemName = map['itemName']
      ..shortName = map['shortName']
      ..hsnCode = map['hsnCode']
      ..gstApplicable = map['gstApplicable'] as bool? ?? true
      ..gstRate = (map['gstRate'] as num?)?.toDouble()
      ..cessRate = (map['cessRate'] as num?)?.toDouble()
      ..buyRate = (map['buyRate'] as num?)?.toDouble()
      ..mrp = (map['mrp'] as num?)?.toDouble()
      ..sellRate = (map['sellRate'] as num?)?.toDouble()
      ..wholesaleRate = (map['wholesaleRate'] as num?)?.toDouble()
      ..minimumSellingPrice = (map['minimumSellingPrice'] as num?)?.toDouble()
      ..openingStock = (map['openingStock'] as num?)?.toDouble()
      ..currentStock = (map['currentStock'] as num?)?.toDouble()
      ..reorderLevel = (map['reorderLevel'] as num?)?.toDouble()
      ..minimumStock = (map['minimumStock'] as num?)?.toDouble()
      ..secondaryUnit = map['secondaryUnit']
      ..conversionFactor = (map['conversionFactor'] as num?)?.toDouble()
      ..barcode = map['barcode']
      ..sku = map['sku']
      ..skuCode = map['skuCode']
      ..imagePaths = rewrittenPaths
      ..firebaseImageUrls = map['firebaseImageUrls'] != null ? List<String>.from(map['firebaseImageUrls']) : null
      ..thumbnailImage = rewrittenThumb
      ..weight = (map['weight'] as num?)?.toDouble()
      ..dimensions = map['dimensions']
      ..notes = map['notes']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Order _mapMapToOrder(Map<String, dynamic> map) {
    return Order()
      ..uuid = map['uuid']
      ..orderNumber = map['orderNumber']
      ..orderDate = map['orderDate'] != null ? DateTime.parse(map['orderDate']) : null
      ..status = map['status']
      ..partyId = map['partyId'] as int?
      ..partyName = map['partyName']
      ..mobileNumber = map['mobileNumber']
      ..gstNumber = map['gstNumber']
      ..latitude = (map['latitude'] as num?)?.toDouble()
      ..longitude = (map['longitude'] as num?)?.toDouble()
      ..locationAddress = map['locationAddress']
      ..subtotal = (map['subtotal'] as num?)?.toDouble()
      ..discountAmount = (map['discountAmount'] as num?)?.toDouble()
      ..discountPercent = (map['discountPercent'] as num?)?.toDouble()
      ..totalGST = (map['totalGST'] as num?)?.toDouble()
      ..roundOff = (map['roundOff'] as num?)?.toDouble()
      ..grandTotal = (map['grandTotal'] as num?)?.toDouble()
      ..remarks = map['remarks']
      ..internalNotes = map['internalNotes']
      ..cancelledBy = map['cancelledBy']
      ..cancelledDate = map['cancelledDate'] != null ? DateTime.parse(map['cancelledDate']) : null
      ..cancellationReason = map['cancellationReason']
      ..createdBy = map['createdBy']
      ..editedBy = map['editedBy']
      ..editTime = map['editTime'] != null ? DateTime.parse(map['editTime']) : null
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  OrderItem _mapMapToOrderItem(Map<String, dynamic> map) {
    return OrderItem()
      ..uuid = map['uuid']
      ..itemId = map['itemId'] as int?
      ..itemName = map['itemName']
      ..hsnCode = map['hsnCode']
      ..quantity = (map['quantity'] as num?)?.toDouble()
      ..freeQuantity = (map['freeQuantity'] as num?)?.toDouble()
      ..unit = map['unit']
      ..rate = (map['rate'] as num?)?.toDouble()
      ..discountPercent = (map['discountPercent'] as num?)?.toDouble()
      ..discountAmount = (map['discountAmount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..gstPercent = (map['gstPercent'] as num?)?.toDouble()
      ..gstAmount = (map['gstAmount'] as num?)?.toDouble()
      ..totalAmount = (map['totalAmount'] as num?)?.toDouble()
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Invoice _mapMapToInvoice(Map<String, dynamic> map) {
    return Invoice()
      ..uuid = map['uuid']
      ..invoiceNumber = map['invoiceNumber']
      ..invoiceDate = map['invoiceDate'] != null ? DateTime.parse(map['invoiceDate']) : null
      ..invoiceType = map['invoiceType']
      ..invoiceStatus = map['invoiceStatus']
      ..sourceOrderId = map['sourceOrderId'] as int?
      ..sourceOrderNumber = map['sourceOrderNumber']
      ..partyId = map['partyId'] as int?
      ..partyName = map['partyName']
      ..gstNumber = map['gstNumber']
      ..address = map['address']
      ..subtotal = (map['subtotal'] as num?)?.toDouble()
      ..discountAmount = (map['discountAmount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..cgstAmount = (map['cgstAmount'] as num?)?.toDouble()
      ..sgstAmount = (map['sgstAmount'] as num?)?.toDouble()
      ..igstAmount = (map['igstAmount'] as num?)?.toDouble()
      ..totalGST = (map['totalGST'] as num?)?.toDouble()
      ..roundOff = (map['roundOff'] as num?)?.toDouble()
      ..grandTotal = (map['grandTotal'] as num?)?.toDouble()
      ..paymentStatus = map['paymentStatus']
      ..paidAmount = (map['paidAmount'] as num?)?.toDouble()
      ..pendingAmount = (map['pendingAmount'] as num?)?.toDouble()
      ..dueDate = map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null
      ..remarks = map['remarks']
      ..termsAndConditions = map['termsAndConditions']
      ..cancelledBy = map['cancelledBy']
      ..cancelledDate = map['cancelledDate'] != null ? DateTime.parse(map['cancelledDate']) : null
      ..cancellationReason = map['cancellationReason']
      ..createdBy = map['createdBy']
      ..editedBy = map['editedBy']
      ..editTime = map['editTime'] != null ? DateTime.parse(map['editTime']) : null
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  InvoiceItem _mapMapToInvoiceItem(Map<String, dynamic> map) {
    return InvoiceItem()
      ..uuid = map['uuid']
      ..itemId = map['itemId'] as int?
      ..itemName = map['itemName']
      ..hsnCode = map['hsnCode']
      ..quantity = (map['quantity'] as num?)?.toDouble()
      ..freeQuantity = (map['freeQuantity'] as num?)?.toDouble()
      ..rate = (map['rate'] as num?)?.toDouble()
      ..discount = (map['discount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..gstRate = (map['gstRate'] as num?)?.toDouble()
      ..gstAmount = (map['gstAmount'] as num?)?.toDouble()
      ..totalAmount = (map['totalAmount'] as num?)?.toDouble()
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  SyncQueue _mapMapToSyncQueue(Map<String, dynamic> map) {
    return SyncQueue()
      ..uuid = map['uuid']
      ..entityType = map['entityType']
      ..entityId = map['entityId'] as int?
      ..entityUuid = map['entityUuid']
      ..operation = map['operation']
      ..retryCount = map['retryCount'] as int? ?? 0
      ..lastError = map['lastError']
      ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()
      ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now();
  }
}
