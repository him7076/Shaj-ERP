import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

// Import all 12 collections
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/user_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';

class DatabaseService {
  Isar? _isar;
  static const int currentDatabaseVersion = 1;

  Isar get isar {
    if (_isar == null) {
      throw StateError('DatabaseService has not been initialized. Call init() first.');
    }
    return _isar!;
  }

  Future<void> init() async {
    if (_isar != null) {
      logger.warning('DatabaseService has already been initialized.');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      
      _isar = await Isar.open(
        [
          CategorySchema,
          UnitSchema,
          BrandSchema,
          PartySchema,
          ItemSchema,
          OrderItemSchema,
          OrderSchema,
          InvoiceItemSchema,
          InvoiceSchema,
          SettingsSchema,
          UserSchema,
          SyncQueueSchema,
        ],
        directory: dir.path,
        inspector: true, // Enables Isar database inspector in debug builds
      );

      logger.info('Isar Database v$currentDatabaseVersion initialized successfully at: ${dir.path}');

      // Run Schema Migrations if required
      await _checkAndRunMigrations();
    } catch (e, stackTrace) {
      logger.error('Failed to initialize Isar Database', e, stackTrace);
      rethrow;
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      logger.info('Isar Database connection closed.');
    }
  }

  /// Purges all data in all collections
  Future<void> clearDatabase() async {
    logger.warning('Purging local database...');
    try {
      await isar.writeTxn(() async {
        await isar.clear();
      });
      logger.info('Local database purged successfully.');
    } catch (e, stackTrace) {
      logger.error('Failed to purge local database', e, stackTrace);
      rethrow;
    }
  }

  /// Creates a backup file of the current .isar database
  Future<void> backupDatabase(String destinationPath) async {
    logger.info('Backing up local database to: $destinationPath');
    try {
      final file = File(destinationPath);
      // Ensure directory exists
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // If destination file already exists, delete it first (Isar copy requires it)
      if (await file.exists()) {
        await file.delete();
      }
      
      await isar.copyToFile(destinationPath);
      logger.info('Database backup completed successfully.');
    } catch (e, stackTrace) {
      logger.error('Database backup failed', e, stackTrace);
      rethrow;
    }
  }

  /// Restores the database from a backup file
  Future<void> restoreDatabase(String sourcePath) async {
    logger.warning('Restoring database from backup: $sourcePath');
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileNotFoundException('Backup file not found at: $sourcePath');
      }

      final dir = await getApplicationDocumentsDirectory();
      final activeDbPath = '${dir.path}/default.isar';

      // 1. Close current Isar connection
      await close();

      // 2. Overwrite default.isar with backup
      final activeFile = File(activeDbPath);
      if (await activeFile.exists()) {
        await activeFile.delete();
      }
      await sourceFile.copy(activeDbPath);
      logger.info('Database restore complete. Re-opening connection...');

      // 3. Reinitialize Isar
      await init();
    } catch (e, stackTrace) {
      logger.error('Database restore failed', e, stackTrace);
      rethrow;
    }
  }

  /// Internal schema migration runner (migration hook)
  Future<void> _checkAndRunMigrations() async {
    // Read the version from local storage settings if any, or run custom migration logic
    // Currently at Version 1, so no active migrations.
    logger.debug('Database migration check complete. No migrations pending.');
  }
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => 'FileNotFoundException: $message';
}
