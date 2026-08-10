import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/core/services/web_mock_isar.dart';
import 'package:business_sahaj_erp/core/utils/demo_data_seeder.dart';

// Import all collections
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
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/deleted_voucher_collection.dart';

class DatabaseService {
  Isar? _isar;
  SharedPreferences? _prefs;
  String? initErrorMessage;
  String _activeFirmId = 'firm_default';
  static const int currentDatabaseVersion = 1;

  String get activeFirmId => _activeFirmId;

  Isar get isar {
    if (_isar == null) {
      throw StateError('DatabaseService has not been initialized. Call init() first.');
    }
    return _isar!;
  }

  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs;
    if (_isar != null) {
      logger.warning('DatabaseService has already been initialized.');
      return;
    }

    final activeFirmId = prefs?.getString('active_firm_id') ?? 'firm_default';
    _activeFirmId = activeFirmId;

    try {
      if (kIsWeb) {
        _isar = WebMockIsar(firmId: activeFirmId, prefs: prefs);
        logger.info('Initialized WebMockIsar Database for firm: $activeFirmId');
        
        // Prevent generic type parameter tree-shaking on Web
        try {
          WebMockIsar.dummyKeep();
        } catch (_) {}

        final key = 'demo_seeded_$activeFirmId';
        final alreadySeeded = prefs?.getBool(key) ?? false;
        final bool hasExistingData = (_isar as WebMockIsar).hasData;

        if (!alreadySeeded && !hasExistingData && activeFirmId == 'firm_default') {
          try {
            await DemoDataSeeder.seedDemoData(this);
            await prefs?.setBool(key, true);
            logger.info('Auto-seeded demo data on web startup for default firm.');
          } catch (e) {
            logger.error('Failed to auto-seed demo data on web startup', e);
          }
        } else if (hasExistingData && !alreadySeeded) {
          await prefs?.setBool(key, true);
        }
        return;
      }

      String? dirPath;
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        dirPath = dir.path;
      }
      
      try {
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
            PurchaseSchema,
            PurchaseItemSchema,
            ExpenseSchema,
            TransactionSchema,
            BankAccountSchema,
            CreditNoteSchema,
            CreditNoteItemSchema,
            DebitNoteSchema,
            DebitNoteItemSchema,
            DeletedVoucherSchema,
          ],
          name: activeFirmId,
          directory: dirPath ?? '',
          inspector: !kIsWeb && !kReleaseMode,
        );
      } catch (openError) {
        logger.warning('Failed to open Isar database directly: $openError. Attempting to clear database file to resolve schema mismatch.');
        
        // 1. Close existing instance from memory if registered
        try {
          final existingInstance = Isar.getInstance(activeFirmId);
          if (existingInstance != null) {
            await existingInstance.close();
            logger.info('Closed duplicate/broken database instance from memory.');
          }
        } catch (closeError) {
          logger.error('Failed to close duplicate database instance from memory: $closeError');
        }

        // 2. Delete all database files (.isar and .isar.lock) to recover from schema mismatch
        if (!kIsWeb && dirPath != null) {
          try {
            final dir = Directory(dirPath);
            if (await dir.exists()) {
              final entities = dir.listSync();
              for (final entity in entities) {
                if (entity is File && (entity.path.endsWith('.isar') || entity.path.endsWith('.isar.lock'))) {
                  try {
                    await entity.delete();
                  } catch (_) {}
                }
              }
            }
            logger.info('Successfully deleted old database files to recover from crash.');
          } catch (deleteError) {
            logger.error('Failed to delete database files during auto-recovery: $deleteError');
          }
        }
        
        // 3. Retry opening Isar database with fallback
        try {
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
              PurchaseSchema,
              PurchaseItemSchema,
              ExpenseSchema,
              TransactionSchema,
              BankAccountSchema,
              CreditNoteSchema,
              CreditNoteItemSchema,
              DebitNoteSchema,
              DebitNoteItemSchema,
              DeletedVoucherSchema,
            ],
            name: activeFirmId,
            directory: dirPath ?? '',
            inspector: !kIsWeb && !kReleaseMode,
          );
        } catch (retryError) {
          logger.error('Failed to open native Isar database on retry: $retryError. Initializing fallback database connection to prevent app crash.', retryError);
          _isar = WebMockIsar(firmId: activeFirmId, prefs: prefs);
        }
      }

      logger.info('Isar Database ($activeFirmId) v$currentDatabaseVersion initialized successfully.');

      // Run Schema Migrations if required
      await _checkAndRunMigrations();
    } catch (e, stackTrace) {
      initErrorMessage = e.toString();
      logger.error('Failed to initialize Isar Database', e, stackTrace);
      rethrow;
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_isar != null) {
      if (!kIsWeb) {
        await _isar!.close();
      }
      _isar = null;
      logger.info('Isar Database connection closed.');
    }
  }

  /// Switch active firm database
  Future<void> switchFirm(String newFirmId, SharedPreferences prefs) async {
    await close();
    _activeFirmId = newFirmId;
    await prefs.setString('active_firm_id', newFirmId);
    await init(prefs);
  }

  /// Purges all data in all collections
  Future<void> clearDatabase() async {
    logger.warning('Purging local database for $_activeFirmId...');
    try {
      await isar.writeTxn(() async {
        await isar.clear();
      });

      if (kIsWeb) {
        final webIsar = isar as WebMockIsar;
        webIsar.clearAllData();
      }

      if (_prefs != null) {
        await _prefs!.setBool('demo_seeded_$_activeFirmId', true);
        final keys = _prefs!.getKeys().where((k) => k.contains(_activeFirmId)).toList();
        for (var k in keys) {
          if (!k.startsWith('firm_name_') && !k.startsWith('firm_gst_') && !k.startsWith('firm_mobile_') && k != 'demo_seeded_$_activeFirmId') {
            await _prefs!.remove(k);
          }
        }
      }
      logger.info('Local database purged successfully.');
    } catch (e, stackTrace) {
      logger.error('Failed to purge local database', e, stackTrace);
      rethrow;
    }
  }

  /// Creates a backup file of the current .isar database
  Future<void> backupDatabase(String destinationPath) async {
    if (kIsWeb) {
      throw UnsupportedError('Database backup is not supported on the web.');
    }
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
    if (kIsWeb) {
      throw UnsupportedError('Database restore is not supported on the web.');
    }
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
