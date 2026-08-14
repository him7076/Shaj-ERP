import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:archive/archive.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/user_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';

class RestoreService {
  final DatabaseService _dbService;
  final CompressionService _compressionService;
  final EncryptionService _encryptionService;
  final SharedPreferences? _prefs;

  RestoreService(
    this._dbService,
    this._compressionService,
    this._encryptionService, [
    this._prefs,
  ]);

  /// Validates a backup archive directly from Uint8List bytes (Web & Native compatible)
  Future<BackupMetadata> validateBackupBytes(Uint8List bytes, {String? password}) async {
    try {
      if (bytes.isEmpty) {
        throw const CorruptedBackupException('Backup file is empty.');
      }

      // 1. Raw JSON Payload (Web Download Format)
      if (bytes[0] == 0x7B /* '{' */) {
        final jsonString = utf8.decode(bytes);
        final Map<String, dynamic> fullMap = jsonDecode(jsonString);
        if (!fullMap.containsKey('metadata')) {
          throw const CorruptedBackupException('Invalid backup archive: missing metadata header.');
        }
        final metadata = BackupMetadata.fromJson(fullMap['metadata']);
        if (metadata.databaseVersion > DatabaseService.currentDatabaseVersion) {
          throw RestoreException(
            'Incompatible database version. Backup version is v${metadata.databaseVersion}, '
            'but application only supports up to v${DatabaseService.currentDatabaseVersion}.',
          );
        }
        return metadata;
      }

      // 2. ZIP Archive (PK Header Format)
      if (bytes.length > 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
        final archive = ZipDecoder().decodeBytes(bytes);
        final metaArchiveFile = archive.findFile('metadata.json');
        if (metaArchiveFile == null) {
          throw const CorruptedBackupException('Invalid backup archive: missing metadata header.');
        }
        final metaContent = utf8.decode(metaArchiveFile.content as List<int>);
        final metadata = BackupMetadata.fromJson(jsonDecode(metaContent));
        if (metadata.databaseVersion > DatabaseService.currentDatabaseVersion) {
          throw RestoreException(
            'Incompatible database version. Backup version is v${metadata.databaseVersion}, '
            'but application only supports up to v${DatabaseService.currentDatabaseVersion}.',
          );
        }
        return metadata;
      }

      throw const CorruptedBackupException('Unsupported backup file format.');
    } catch (e) {
      if (e is RestoreException || e is CorruptedBackupException || e is EncryptionException) {
        rethrow;
      }
      throw RestoreException('Failed to validate backup data: $e');
    }
  }

  /// Restores database directly from Uint8List bytes
  Future<void> restoreBackupBytes(
    Uint8List bytes, {
    String? password,
    bool restoreParties = true,
    bool restoreItems = true,
    bool restoreOrders = true,
    bool restoreInvoices = true,
    bool restoreSettings = true,
    String duplicateStrategy = 'replace',
  }) async {
    try {
      Map<String, dynamic> collectionsMap = {};

      if (bytes[0] == 0x7B /* '{' */) {
        final jsonString = utf8.decode(bytes);
        collectionsMap = jsonDecode(jsonString);
      } else if (bytes.length > 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
        final archive = ZipDecoder().decodeBytes(bytes);
        for (var file in archive) {
          if (file.isFile && file.name.endsWith('.json') && file.name != 'metadata.json') {
            final colName = file.name.replaceAll('.json', '');
            final contentStr = utf8.decode(file.content as List<int>);
            collectionsMap[colName] = jsonDecode(contentStr);
          }
        }
      }

      final isar = _dbService.isar;

      await isar.writeTxn(() async {
        if (restoreParties && collectionsMap.containsKey('parties')) {
          final list = collectionsMap['parties'] as List;
          for (var itemMap in list) {
            final party = _mapMapToParty(itemMap as Map<String, dynamic>);
            await isar.partys.put(party);
          }
        }

        if (restoreItems && collectionsMap.containsKey('items')) {
          final list = collectionsMap['items'] as List;
          for (var itemMap in list) {
            final item = _mapMapToItem(itemMap as Map<String, dynamic>);
            await isar.items.put(item);
          }
        }

        if (restoreItems && collectionsMap.containsKey('categories')) {
          final list = collectionsMap['categories'] as List;
          for (var itemMap in list) {
            final cat = _mapMapToCategory(itemMap as Map<String, dynamic>);
            await isar.categorys.put(cat);
          }
        }

        if (restoreItems && collectionsMap.containsKey('units')) {
          final list = collectionsMap['units'] as List;
          for (var itemMap in list) {
            final unit = _mapMapToUnit(itemMap as Map<String, dynamic>);
            await isar.units.put(unit);
          }
        }

        if (restoreItems && collectionsMap.containsKey('brands')) {
          final list = collectionsMap['brands'] as List;
          for (var itemMap in list) {
            final brand = _mapMapToBrand(itemMap as Map<String, dynamic>);
            await isar.brands.put(brand);
          }
        }

        if (restoreOrders && collectionsMap.containsKey('orders')) {
          final list = collectionsMap['orders'] as List;
          for (var itemMap in list) {
            final order = _mapMapToOrder(itemMap as Map<String, dynamic>);
            await isar.orders.put(order);
          }
        }

        if (restoreOrders && collectionsMap.containsKey('order_items')) {
          final list = collectionsMap['order_items'] as List;
          for (var itemMap in list) {
            final oi = _mapMapToOrderItem(itemMap as Map<String, dynamic>);
            await isar.orderItems.put(oi);
          }
        }

        if (restoreInvoices && collectionsMap.containsKey('invoices')) {
          final list = collectionsMap['invoices'] as List;
          for (var itemMap in list) {
            final inv = _mapMapToInvoice(itemMap as Map<String, dynamic>);
            await isar.invoices.put(inv);
          }
        }

        if (restoreInvoices && collectionsMap.containsKey('invoice_items')) {
          final list = collectionsMap['invoice_items'] as List;
          for (var itemMap in list) {
            final ii = _mapMapToInvoiceItem(itemMap as Map<String, dynamic>);
            await isar.invoiceItems.put(ii);
          }
        }

        if (collectionsMap.containsKey('purchases')) {
          final list = collectionsMap['purchases'] as List;
          for (var itemMap in list) {
            final pur = _mapMapToPurchase(itemMap as Map<String, dynamic>);
            await isar.purchases.put(pur);
          }
        }

        if (collectionsMap.containsKey('purchase_items')) {
          final list = collectionsMap['purchase_items'] as List;
          for (var itemMap in list) {
            final pi = _mapMapToPurchaseItem(itemMap as Map<String, dynamic>);
            await isar.purchaseItems.put(pi);
          }
        }

        if (collectionsMap.containsKey('expenses')) {
          final list = collectionsMap['expenses'] as List;
          for (var itemMap in list) {
            final exp = _mapMapToExpense(itemMap as Map<String, dynamic>);
            await isar.expenses.put(exp);
          }
        }

        if (collectionsMap.containsKey('expense_items')) {
          final list = collectionsMap['expense_items'] as List;
          for (var itemMap in list) {
            final expItem = _mapMapToExpenseItem(itemMap as Map<String, dynamic>);
            await isar.collection<ExpenseItem>().put(expItem);
          }
        }

        if (restoreSettings && collectionsMap.containsKey('settings')) {
          final list = collectionsMap['settings'] as List;
          for (var itemMap in list) {
            final st = _mapMapToSettings(itemMap as Map<String, dynamic>);
            await isar.settings.put(st);
          }
        }
      });

      logger.info('Database restore from bytes completed successfully.');
    } catch (e, stack) {
      logger.error('Failed to restore database from bytes', e, stack);
      throw RestoreException('Failed to restore database: $e');
    }
  }

  /// Validates a backup file. Returns BackupMetadata if valid.
  Future<BackupMetadata> validateBackup(String filePath, {String? password}) async {
    final tempDir = await getTemporaryDirectory();
    final tempExtractPath = '${tempDir.path}/meta_extract_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(tempExtractPath).create(recursive: true);

    String zipToExtract = filePath;
    bool isTemporaryDecryptedFile = false;

    try {
      final fileBytes = await File(filePath).readAsBytes();
      bool isEncrypted = fileBytes.length < 2 || fileBytes[0] != 0x50 || fileBytes[1] != 0x4B;

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

      await Directory(tempExtractPath).delete(recursive: true);
      if (isTemporaryDecryptedFile) {
        await File(zipToExtract).delete();
      }

      if (metadata.databaseVersion > DatabaseService.currentDatabaseVersion) {
        throw RestoreException(
          'Incompatible database version. Backup version is v${metadata.databaseVersion}, '
          'but application only supports up to v${DatabaseService.currentDatabaseVersion}.',
        );
      }

      return metadata;
    } catch (e) {
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

      await _compressionService.extractBackupArchive(
        zipPath: zipToExtract,
        destExtractDir: extractDir.path,
      );

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

      // Restore Multi-Firm SharedPreferences if present
      if (_prefs != null) {
        final prefFile = File('${extractDir.path}/preferences.json');
        if (await prefFile.exists()) {
          try {
            final Map<String, dynamic> map = jsonDecode(await prefFile.readAsString());
            for (var entry in map.entries) {
              if (entry.value is String) {
                await _prefs!.setString(entry.key, entry.value as String);
              } else if (entry.value is bool) {
                await _prefs!.setBool(entry.key, entry.value as bool);
              } else if (entry.value is List) {
                await _prefs!.setStringList(entry.key, (entry.value as List).cast<String>());
              }
            }
            logger.info('Restored multi-firm preferences from backup payload.');
          } catch (e) {
            logger.warning('Non-fatal: failed to restore preferences.json: $e');
          }
        }
      }

      final isar = _dbService.isar;

      // 1. Restoring Settings
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

      // 2. Users
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

      // 3. Categories
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
      }

      // 4. Units
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

      // 5. Brands
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

      // 6. Parties
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

      // 7. Items
      if (restoreItems) {
        await _restoreCollection<Item>(
          jsonFile: File('${extractDir.path}/items.json'),
          strategy: duplicateStrategy,
          fromMap: (map) => _mapMapToItem(map, appDocsDir.path),
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

        // Re-link item relations
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

      // 8. Orders & OrderItems
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
      }

      // 9. Invoices & InvoiceItems
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

        // Re-link invoice parent relation
        final invoiceItemsJsonFile = File('${extractDir.path}/invoice_items.json');
        if (await invoiceItemsJsonFile.exists()) {
          final List list = jsonDecode(await invoiceItemsJsonFile.readAsString());
          await isar.writeTxn(() async {
            for (var itemMap in list) {
              final currentUuid = itemMap['uuid'] as String;
              final invoiceUuid = itemMap['invoiceUuid'] as String?;
              final current = await isar.invoiceItems.filter().uuidEqualTo(currentUuid).findFirst();
              if (current != null && invoiceUuid != null) {
                final inv = await isar.invoices.filter().uuidEqualTo(invoiceUuid).findFirst();
                if (inv != null) {
                  current.parentInvoiceId = inv.id;
                  current.invoice.value = inv;
                  await isar.invoiceItems.put(current);
                }
              }
            }
          });
        }
      }

      // 10. Purchases & PurchaseItems
      await _restoreCollection<Purchase>(
        jsonFile: File('${extractDir.path}/purchases.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToPurchase(map),
        putAll: (items) async => await isar.purchases.putAll(items),
        deleteByUuids: (uuids) async => await isar.purchases.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.purchases.filter().uuidEqualTo(uuid).findFirst(),
      );

      await _restoreCollection<PurchaseItem>(
        jsonFile: File('${extractDir.path}/purchase_items.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToPurchaseItem(map),
        putAll: (items) async => await isar.purchaseItems.putAll(items),
        deleteByUuids: (uuids) async => await isar.purchaseItems.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.purchaseItems.filter().uuidEqualTo(uuid).findFirst(),
      );

      // Re-link purchase parent relation
      final purchaseItemsJsonFile = File('${extractDir.path}/purchase_items.json');
      if (await purchaseItemsJsonFile.exists()) {
        final List list = jsonDecode(await purchaseItemsJsonFile.readAsString());
        await isar.writeTxn(() async {
          for (var itemMap in list) {
            final currentUuid = itemMap['uuid'] as String;
            final purchaseUuid = itemMap['purchaseUuid'] as String?;
            final current = await isar.purchaseItems.filter().uuidEqualTo(currentUuid).findFirst();
            if (current != null && purchaseUuid != null) {
              final pur = await isar.purchases.filter().uuidEqualTo(purchaseUuid).findFirst();
              if (pur != null) {
                current.purchaseId = pur.id;
                current.purchase.value = pur;
                await isar.purchaseItems.put(current);
              }
            }
          }
        });
      }

      // 11. Expenses
      await _restoreCollection<Expense>(
        jsonFile: File('${extractDir.path}/expenses.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToExpense(map),
        putAll: (items) async => await isar.expenses.putAll(items),
        deleteByUuids: (uuids) async => await isar.expenses.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.expenses.filter().uuidEqualTo(uuid).findFirst(),
      );

      await _restoreCollection<ExpenseItem>(
        jsonFile: File('${extractDir.path}/expense_items.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToExpenseItem(map),
        putAll: (items) async => await isar.collection<ExpenseItem>().putAll(items),
        deleteByUuids: (uuids) async => await isar.collection<ExpenseItem>().filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.collection<ExpenseItem>().filter().uuidEqualTo(uuid).findFirst(),
      );

      // 12. Transactions
      await _restoreCollection<Transaction>(
        jsonFile: File('${extractDir.path}/transactions.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToTransaction(map),
        putAll: (items) async => await isar.transactions.putAll(items),
        deleteByUuids: (uuids) async => await isar.transactions.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.transactions.filter().uuidEqualTo(uuid).findFirst(),
      );

      // 13. Bank Accounts
      await _restoreCollection<BankAccount>(
        jsonFile: File('${extractDir.path}/bank_accounts.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToBankAccount(map),
        putAll: (items) async => await isar.bankAccounts.putAll(items),
        deleteByUuids: (uuids) async => await isar.bankAccounts.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.bankAccounts.filter().uuidEqualTo(uuid).findFirst(),
      );

      // 14. Credit Notes & Credit Note Items
      await _restoreCollection<CreditNote>(
        jsonFile: File('${extractDir.path}/credit_notes.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToCreditNote(map),
        putAll: (items) async => await isar.creditNotes.putAll(items),
        deleteByUuids: (uuids) async => await isar.creditNotes.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.creditNotes.filter().uuidEqualTo(uuid).findFirst(),
      );

      await _restoreCollection<CreditNoteItem>(
        jsonFile: File('${extractDir.path}/credit_note_items.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToCreditNoteItem(map),
        putAll: (items) async => await isar.creditNoteItems.putAll(items),
        deleteByUuids: (uuids) async => await isar.creditNoteItems.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.creditNoteItems.filter().uuidEqualTo(uuid).findFirst(),
      );

      // 15. Debit Notes & Debit Note Items
      await _restoreCollection<DebitNote>(
        jsonFile: File('${extractDir.path}/debit_notes.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToDebitNote(map),
        putAll: (items) async => await isar.debitNotes.putAll(items),
        deleteByUuids: (uuids) async => await isar.debitNotes.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.debitNotes.filter().uuidEqualTo(uuid).findFirst(),
      );

      await _restoreCollection<DebitNoteItem>(
        jsonFile: File('${extractDir.path}/debit_note_items.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToDebitNoteItem(map),
        putAll: (items) async => await isar.debitNoteItems.putAll(items),
        deleteByUuids: (uuids) async => await isar.debitNoteItems.filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.debitNoteItems.filter().uuidEqualTo(uuid).findFirst(),
      );

      // 16. Stock Adjustments
      await _restoreCollection<StockAdjustment>(
        jsonFile: File('${extractDir.path}/stock_adjustments.json'),
        strategy: duplicateStrategy,
        fromMap: (map) => _mapMapToStockAdjustment(map),
        putAll: (items) async => await isar.collection<StockAdjustment>().putAll(items),
        deleteByUuids: (uuids) async => await isar.collection<StockAdjustment>().filter().group((q) {
          var filter = q.uuidEqualTo(uuids.first);
          for (var i = 1; i < uuids.length; i++) {
            filter = filter.or().uuidEqualTo(uuids[i]);
          }
          return filter;
        }).deleteAll(),
        findByUuid: (uuid) async => await isar.collection<StockAdjustment>().filter().uuidEqualTo(uuid).findFirst(),
      );

      // 17. Sync Queues
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

      await extractDir.delete(recursive: true);
      if (isTemporaryDecrypted) {
        await File(zipToExtract).delete();
      }

      logger.info('Restore operation completed successfully.');
    } catch (e, stackTrace) {
      logger.error('Restore operation failed', e, stackTrace);
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      if (isTemporaryDecrypted && await File(zipToExtract).exists()) {
        await File(zipToExtract).delete();
      }
      throw RestoreException('Database restore failed: $e');
    }
  }

  Future<void> _restoreCollection<T>({
    required File jsonFile,
    required String strategy,
    required T Function(Map<String, dynamic> map) fromMap,
    required Future<void> Function(List<T> items) putAll,
    required Future<void> Function(List<String> uuids) deleteByUuids,
    required Future<dynamic> Function(String uuid) findByUuid,
  }) async {
    if (!await jsonFile.exists()) return;

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
        toPut.add(fromMap(map));
      } else {
        if (strategy == 'replace') {
          uuidsToDelete.add(uuid);
          toPut.add(fromMap(map));
        } else if (strategy == 'merge') {
          final localVersion = existingRecord.version as int;
          final backupVersion = map['version'] as int? ?? 1;

          if (backupVersion >= localVersion) {
            uuidsToDelete.add(uuid);
            toPut.add(fromMap(map));
          }
        }
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
  }

  String _rewriteImagePath(String? path, String currentDocsPrefix) {
    if (path == null) return '';
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
      ..partyCode = map['partyCode']
      ..partyName = map['partyName']
      ..partyType = map['partyType']
      ..gstNumber = map['gstNumber']
      ..panNumber = map['panNumber']
      ..gstType = map['gstType']
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
      ..locationAddress = map['locationAddress']
      ..googleMapUrl = map['googleMapUrl']
      ..openingBalance = (map['openingBalance'] as num?)?.toDouble()
      ..balanceType = map['balanceType']
      ..creditLimit = (map['creditLimit'] as num?)?.toDouble()
      ..paymentTerms = map['paymentTerms']
      ..dueDays = map['dueDays'] as int?
      ..contactPerson = map['contactPerson']
      ..businessCategory = map['businessCategory']
      ..notes = map['notes']
      ..shopPhotos = map['shopPhotos'] != null ? List<String>.from(map['shopPhotos']) : null
      ..shopPhotoUrls = map['shopPhotoUrls'] != null ? List<String>.from(map['shopPhotoUrls']) : null
      ..outstandingBalance = (map['outstandingBalance'] as num?)?.toDouble()
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Item _mapMapToItem(Map<String, dynamic> map, [String currentDocsPrefix = '']) {
    final imagePathsList = map['imagePaths'] != null ? List<String>.from(map['imagePaths']) : <String>[];
    final rewrittenPaths = imagePathsList.map((p) => _rewriteImagePath(p, currentDocsPrefix)).toList();
    final rewrittenThumb = map['thumbnailImage'] != null ? _rewriteImagePath(map['thumbnailImage'] as String, currentDocsPrefix) : null;

    return Item()
      ..uuid = map['uuid']
      ..itemCode = map['itemCode']
      ..itemName = map['itemName']
      ..shortName = map['shortName']
      ..description = map['description']
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
      ..primaryUnitName = map['primaryUnitName']
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
      ..subtotal = (map['subtotal'] as num?)?.toDouble()
      ..discountAmount = (map['discountAmount'] as num?)?.toDouble()
      ..totalGST = (map['totalGST'] as num?)?.toDouble()
      ..grandTotal = (map['grandTotal'] as num?)?.toDouble()
      ..remarks = map['remarks']
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
      ..unit = map['unit']
      ..rate = (map['rate'] as num?)?.toDouble()
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
      ..partyId = map['partyId'] as int?
      ..partyName = map['partyName']
      ..gstNumber = map['gstNumber']
      ..address = map['address']
      ..subtotal = (map['subtotal'] as num?)?.toDouble()
      ..discountAmount = (map['discountAmount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..totalGST = (map['totalGST'] as num?)?.toDouble()
      ..grandTotal = (map['grandTotal'] as num?)?.toDouble()
      ..paymentStatus = map['paymentStatus']
      ..paidAmount = (map['paidAmount'] as num?)?.toDouble()
      ..pendingAmount = (map['pendingAmount'] as num?)?.toDouble()
      ..remarks = map['remarks']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  InvoiceItem _mapMapToInvoiceItem(Map<String, dynamic> map) {
    return InvoiceItem()
      ..uuid = map['uuid']
      ..parentInvoiceId = map['parentInvoiceId'] as int?
      ..itemId = map['itemId'] as int?
      ..itemName = map['itemName']
      ..hsnCode = map['hsnCode']
      ..quantity = (map['quantity'] as num?)?.toDouble()
      ..freeQuantity = (map['freeQuantity'] as num?)?.toDouble()
      ..unit = map['unit']
      ..rate = (map['rate'] as num?)?.toDouble()
      ..discount = (map['discount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..gstRate = (map['gstRate'] as num?)?.toDouble()
      ..gstAmount = (map['gstAmount'] as num?)?.toDouble()
      ..totalAmount = (map['totalAmount'] as num?)?.toDouble()
      ..batchNumber = map['batchNumber']
      ..expiryDate = map['expiryDate']
      ..mfgDate = map['mfgDate']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Purchase _mapMapToPurchase(Map<String, dynamic> map) {
    return Purchase()
      ..uuid = map['uuid']
      ..purchaseNumber = map['purchaseNumber']
      ..supplierInvoiceNumber = map['supplierInvoiceNumber']
      ..purchaseDate = map['purchaseDate'] != null ? DateTime.parse(map['purchaseDate']) : null
      ..partyId = map['partyId'] as int?
      ..partyName = map['partyName']
      ..gstNumber = map['gstNumber']
      ..address = map['address']
      ..subtotal = (map['subtotal'] as num?)?.toDouble()
      ..discountAmount = (map['discountAmount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..totalGST = (map['totalGST'] as num?)?.toDouble()
      ..grandTotal = (map['grandTotal'] as num?)?.toDouble()
      ..paymentStatus = map['paymentStatus']
      ..paidAmount = (map['paidAmount'] as num?)?.toDouble()
      ..pendingAmount = (map['pendingAmount'] as num?)?.toDouble()
      ..remarks = map['remarks']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  PurchaseItem _mapMapToPurchaseItem(Map<String, dynamic> map) {
    return PurchaseItem()
      ..uuid = map['uuid']
      ..purchaseId = map['purchaseId'] as int?
      ..purchaseUuid = map['purchaseUuid']
      ..itemId = map['itemId'] as int?
      ..itemName = map['itemName']
      ..hsnCode = map['hsnCode']
      ..quantity = (map['quantity'] as num?)?.toDouble()
      ..unit = map['unit']
      ..rate = (map['rate'] as num?)?.toDouble()
      ..discount = (map['discount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..gstRate = (map['gstRate'] as num?)?.toDouble()
      ..gstAmount = (map['gstAmount'] as num?)?.toDouble()
      ..totalAmount = (map['totalAmount'] as num?)?.toDouble()
      ..batchNumber = map['batchNumber']
      ..expiryDate = map['expiryDate']
      ..mfgDate = map['mfgDate']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  Expense _mapMapToExpense(Map<String, dynamic> map) {
    return Expense()
      ..uuid = map['uuid']
      ..voucherNo = map['voucherNo'] as String?
      ..partyName = map['partyName'] as String?
      ..category = map['category'] as String?
      ..subtotal = (map['subtotal'] as num?)?.toDouble()
      ..roundOff = (map['roundOff'] as num?)?.toDouble()
      ..amount = (map['amount'] as num?)?.toDouble()
      ..expenseDate = map['expenseDate'] != null ? DateTime.parse(map['expenseDate']) : null
      ..paymentMode = map['paymentMode'] as String?
      ..remarks = map['remarks'] as String?
      ..itemsJson = map['itemsJson'] as String?
      ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()
      ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now()
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = (map['version'] as num?)?.toInt() ?? 1;
  }

  ExpenseItem _mapMapToExpenseItem(Map<String, dynamic> map) {
    return ExpenseItem()
      ..uuid = map['uuid'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}'
      ..itemName = map['itemName'] as String?
      ..defaultRate = (map['defaultRate'] as num?)?.toDouble()
      ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()
      ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now()
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = (map['version'] as num?)?.toInt() ?? 1;
  }

  Transaction _mapMapToTransaction(Map<String, dynamic> map) {
    return Transaction()
      ..uuid = map['uuid']
      ..transactionNumber = map['transactionNumber']
      ..transactionDate = map['transactionDate'] != null ? DateTime.parse(map['transactionDate']) : null
      ..partyUuid = map['partyUuid']
      ..partyName = map['partyName']
      ..transactionType = map['transactionType']
      ..amount = (map['amount'] as num?)?.toDouble()
      ..paymentMode = map['paymentMode']
      ..referenceNumber = map['referenceNumber']
      ..remarks = map['remarks']
      ..linkedBillUuid = map['linkedBillUuid']
      ..linkedBillNumber = map['linkedBillNumber']
      ..targetPartyUuid = map['targetPartyUuid']
      ..targetPartyName = map['targetPartyName']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  BankAccount _mapMapToBankAccount(Map<String, dynamic> map) {
    return BankAccount()
      ..uuid = map['uuid']
      ..accountName = map['accountName']
      ..bankName = map['bankName']
      ..accountNumber = map['accountNumber']
      ..ifscCode = map['ifscCode']
      ..branchName = map['branchName']
      ..openingBalance = (map['openingBalance'] as num?)?.toDouble()
      ..currentBalance = (map['currentBalance'] as num?)?.toDouble()
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  CreditNote _mapMapToCreditNote(Map<String, dynamic> map) {
    return CreditNote()
      ..uuid = map['uuid']
      ..creditNoteNumber = map['creditNoteNumber']
      ..creditNoteDate = map['creditNoteDate'] != null ? DateTime.parse(map['creditNoteDate']) : null
      ..originalInvoiceNumber = map['originalInvoiceNumber']
      ..originalInvoiceUuid = map['originalInvoiceUuid']
      ..partyId = map['partyId'] as int?
      ..partyName = map['partyName']
      ..gstNumber = map['gstNumber']
      ..address = map['address']
      ..subtotal = (map['subtotal'] as num?)?.toDouble()
      ..discountAmount = (map['discountAmount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..totalGST = (map['totalGST'] as num?)?.toDouble()
      ..grandTotal = (map['grandTotal'] as num?)?.toDouble()
      ..remarks = map['remarks']
      ..createdBy = map['createdBy']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  CreditNoteItem _mapMapToCreditNoteItem(Map<String, dynamic> map) {
    return CreditNoteItem()
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

  DebitNote _mapMapToDebitNote(Map<String, dynamic> map) {
    return DebitNote()
      ..uuid = map['uuid']
      ..debitNoteNumber = map['debitNoteNumber']
      ..debitNoteDate = map['debitNoteDate'] != null ? DateTime.parse(map['debitNoteDate']) : null
      ..originalPurchaseNumber = map['originalPurchaseNumber']
      ..originalPurchaseUuid = map['originalPurchaseUuid']
      ..partyId = map['partyId'] as int?
      ..partyName = map['partyName']
      ..gstNumber = map['gstNumber']
      ..address = map['address']
      ..subtotal = (map['subtotal'] as num?)?.toDouble()
      ..discountAmount = (map['discountAmount'] as num?)?.toDouble()
      ..taxableAmount = (map['taxableAmount'] as num?)?.toDouble()
      ..totalGST = (map['totalGST'] as num?)?.toDouble()
      ..grandTotal = (map['grandTotal'] as num?)?.toDouble()
      ..remarks = map['remarks']
      ..createdBy = map['createdBy']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }

  DebitNoteItem _mapMapToDebitNoteItem(Map<String, dynamic> map) {
    return DebitNoteItem()
      ..uuid = map['uuid']
      ..itemId = map['itemId'] as int?
      ..itemName = map['itemName']
      ..hsnCode = map['hsnCode']
      ..quantity = (map['quantity'] as num?)?.toDouble()
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

  StockAdjustment _mapMapToStockAdjustment(Map<String, dynamic> map) {
    return StockAdjustment()
      ..uuid = map['uuid']
      ..itemUuid = map['itemUuid']
      ..itemId = map['itemId'] as int?
      ..itemName = map['itemName']
      ..adjustmentType = map['adjustmentType']
      ..quantity = (map['quantity'] as num?)?.toDouble()
      ..unit = map['unit']
      ..adjustmentDate = map['adjustmentDate'] != null ? DateTime.parse(map['adjustmentDate']) : null
      ..reason = map['reason']
      ..notes = map['notes']
      ..createdAt = DateTime.parse(map['createdAt'])
      ..updatedAt = DateTime.parse(map['updatedAt'])
      ..isDeleted = map['isDeleted'] as bool? ?? false
      ..isSynced = map['isSynced'] as bool? ?? false
      ..version = map['version'] as int? ?? 1;
  }
}
