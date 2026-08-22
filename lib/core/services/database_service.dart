import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, debugPrint;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
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
import 'package:business_sahaj_erp/data/local/collections/expense_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/deleted_voucher_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/whatsapp_mapping_collection.dart';

class DatabaseService {
  Isar? _isar;
  SharedPreferences? _prefs;
  String? initErrorMessage;
  String _activeFirmId = 'firm_default';
  static const int currentDatabaseVersion = 1;

  String get activeFirmId => _activeFirmId;

  Isar get isar {
    if (_isar == null) {
      logger.warning('DatabaseService.isar accessed before init completed. Initializing fallback database connection.');
      _isar = WebMockIsar(firmId: _activeFirmId, prefs: _prefs);
    }
    return _isar!;
  }

  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs;
    if (_isar != null && _isar is! WebMockIsar) {
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
            ExpenseItemSchema,
            TransactionSchema,
            BankAccountSchema,
            CreditNoteSchema,
            CreditNoteItemSchema,
            DebitNoteSchema,
            DebitNoteItemSchema,
            DeletedVoucherSchema,
            StockAdjustmentSchema,
            WhatsAppMappingSchema,
          ],
          name: activeFirmId,
          directory: dirPath ?? '',
          inspector: !kIsWeb && !kReleaseMode,
        ).timeout(const Duration(seconds: 10));
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
              ExpenseItemSchema,
              TransactionSchema,
              BankAccountSchema,
              CreditNoteSchema,
              CreditNoteItemSchema,
              DebitNoteSchema,
              DebitNoteItemSchema,
              DeletedVoucherSchema,
              StockAdjustmentSchema,
              WhatsAppMappingSchema,
            ],
            name: activeFirmId,
            directory: dirPath ?? '',
            inspector: !kIsWeb && !kReleaseMode,
          ).timeout(const Duration(seconds: 3));
        } catch (retryError) {
          logger.error('Failed to open native Isar database on retry: $retryError. Initializing fallback database connection to prevent app crash.', retryError);
          debugPrint('[CRITICAL] Isar native DB failed on Android. Using WebMockIsar fallback. Data may be empty until restart.');
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

  /// Force close all open Isar instances across all firms for file swapping
  Future<void> closeAllInstances() async {
    if (kIsWeb) {
      _isar = null;
      return;
    }
    try {
      if (_isar != null) {
        await _isar!.close();
        _isar = null;
      }
      // Close any other named instance registered in Isar
      final activeFirmInstance = Isar.getInstance(_activeFirmId);
      if (activeFirmInstance != null && activeFirmInstance.isOpen) {
        await activeFirmInstance.close();
      }
      final defaultInstance = Isar.getInstance('firm_default');
      if (defaultInstance != null && defaultInstance.isOpen) {
        await defaultInstance.close();
      }
      logger.info('Closed all Isar database instances.');
    } catch (e) {
      logger.warning('Error closing all Isar instances: $e');
      _isar = null;
    }
  }

  /// Safely close Isar database connection for binary restore swap
  Future<void> closeDatabase() async {
    await closeAllInstances();
  }

  /// Re-open Isar database connection after binary file swap
  Future<void> reopenDatabase([SharedPreferences? prefs]) async {
    _prefs = prefs ?? _prefs;
    if (kIsWeb) {
      WebMockIsar.resetAllInMemDbs();
    }
    _isar = null;
    await init(_prefs);
  }

  /// Exports all database collections for firmId to a JSON Map
  Future<Map<String, dynamic>> exportCollectionsToJson([String? targetFirmId]) async {
    final firm = targetFirmId ?? _activeFirmId;
    if (kIsWeb) {
      if (_isar is WebMockIsar) {
        return (_isar as WebMockIsar).exportCollectionsJson();
      }
      return {};
    }
    final Map<String, dynamic> result = {};
    try {
      final parties = await isar.partys.where().exportJson();
      final items = await isar.items.where().exportJson();
      final invoices = await isar.invoices.where().exportJson();
      final invoiceItems = await isar.invoiceItems.where().exportJson();
      final purchases = await isar.purchases.where().exportJson();
      final purchaseItems = await isar.purchaseItems.where().exportJson();
      final orders = await isar.orders.where().exportJson();
      final orderItems = await isar.orderItems.where().exportJson();
      final expenses = await isar.expenses.where().exportJson();
      final expenseItems = await isar.expenseItems.where().exportJson();
      final transactions = await isar.transactions.where().exportJson();
      final categories = await isar.categorys.where().exportJson();
      final brands = await isar.brands.where().exportJson();
      final units = await isar.units.where().exportJson();
      final bankAccounts = await isar.bankAccounts.where().exportJson();
      final creditNotes = await isar.creditNotes.where().exportJson();
      final creditNoteItems = await isar.creditNoteItems.where().exportJson();
      final debitNotes = await isar.debitNotes.where().exportJson();
      final debitNoteItems = await isar.debitNoteItems.where().exportJson();
      final deletedVouchers = await isar.deletedVouchers.where().exportJson();
      final stockAdjustments = await isar.stockAdjustments.where().exportJson();
      final whatsAppMappings = await isar.whatsAppMappings.where().exportJson();
      final settings = await isar.settings.where().exportJson();
      final users = await isar.users.where().exportJson();

      result['partys'] = parties;
      result['items'] = items;
      result['invoices'] = invoices;
      result['invoiceItems'] = invoiceItems;
      result['purchases'] = purchases;
      result['purchaseItems'] = purchaseItems;
      result['orders'] = orders;
      result['orderItems'] = orderItems;
      result['expenses'] = expenses;
      result['expenseItems'] = expenseItems;
      result['transactions'] = transactions;
      result['categorys'] = categories;
      result['brands'] = brands;
      result['units'] = units;
      result['bankAccounts'] = bankAccounts;
      result['creditNotes'] = creditNotes;
      result['creditNoteItems'] = creditNoteItems;
      result['debitNotes'] = debitNotes;
      result['debitNoteItems'] = debitNoteItems;
      result['deletedVouchers'] = deletedVouchers;
      result['stockAdjustments'] = stockAdjustments;
      result['whatsAppMappings'] = whatsAppMappings;
      result['settings'] = settings;
      result['users'] = users;
    } catch (e) {
      logger.warning('Failed to export collections to JSON: $e');
    }
    return result;
  }

  /// Imports database collections from a JSON Map
  Future<void> importCollectionsFromJson(String firmId, Map<String, dynamic> collectionsData) async {
    if (kIsWeb) {
      if (_isar is WebMockIsar) {
        (_isar as WebMockIsar).importCollectionsJson(collectionsData);
      }
      return;
    }
    try {
      await isar.writeTxn(() async {
        if (collectionsData.containsKey('partys') && collectionsData['partys'] is List) {
          await isar.partys.importJson(collectionsData['partys'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('items') && collectionsData['items'] is List) {
          await isar.items.importJson(collectionsData['items'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('invoices') && collectionsData['invoices'] is List) {
          await isar.invoices.importJson(collectionsData['invoices'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('invoiceItems') && collectionsData['invoiceItems'] is List) {
          await isar.invoiceItems.importJson(collectionsData['invoiceItems'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('purchases') && collectionsData['purchases'] is List) {
          await isar.purchases.importJson(collectionsData['purchases'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('purchaseItems') && collectionsData['purchaseItems'] is List) {
          await isar.purchaseItems.importJson(collectionsData['purchaseItems'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('orders') && collectionsData['orders'] is List) {
          await isar.orders.importJson(collectionsData['orders'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('orderItems') && collectionsData['orderItems'] is List) {
          await isar.orderItems.importJson(collectionsData['orderItems'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('expenses') && collectionsData['expenses'] is List) {
          await isar.expenses.importJson(collectionsData['expenses'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('expenseItems') && collectionsData['expenseItems'] is List) {
          await isar.expenseItems.importJson(collectionsData['expenseItems'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('transactions') && collectionsData['transactions'] is List) {
          await isar.transactions.importJson(collectionsData['transactions'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('categorys') && collectionsData['categorys'] is List) {
          await isar.categorys.importJson(collectionsData['categorys'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('brands') && collectionsData['brands'] is List) {
          await isar.brands.importJson(collectionsData['brands'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('units') && collectionsData['units'] is List) {
          await isar.units.importJson(collectionsData['units'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('bankAccounts') && collectionsData['bankAccounts'] is List) {
          await isar.bankAccounts.importJson(collectionsData['bankAccounts'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('creditNotes') && collectionsData['creditNotes'] is List) {
          await isar.creditNotes.importJson(collectionsData['creditNotes'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('creditNoteItems') && collectionsData['creditNoteItems'] is List) {
          await isar.creditNoteItems.importJson(collectionsData['creditNoteItems'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('debitNotes') && collectionsData['debitNotes'] is List) {
          await isar.debitNotes.importJson(collectionsData['debitNotes'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('debitNoteItems') && collectionsData['debitNoteItems'] is List) {
          await isar.debitNoteItems.importJson(collectionsData['debitNoteItems'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('deletedVouchers') && collectionsData['deletedVouchers'] is List) {
          await isar.deletedVouchers.importJson(collectionsData['deletedVouchers'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('stockAdjustments') && collectionsData['stockAdjustments'] is List) {
          await isar.stockAdjustments.importJson(collectionsData['stockAdjustments'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('whatsAppMappings') && collectionsData['whatsAppMappings'] is List) {
          await isar.whatsAppMappings.importJson(collectionsData['whatsAppMappings'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('settings') && collectionsData['settings'] is List) {
          await isar.settings.importJson(collectionsData['settings'] as List<Map<String, dynamic>>);
        }
        if (collectionsData.containsKey('users') && collectionsData['users'] is List) {
          await isar.users.importJson(collectionsData['users'] as List<Map<String, dynamic>>);
        }
      });
    } catch (e) {
      logger.error('Failed to import collections from JSON', e);
      rethrow;
    }
  }

  /// Switch active firm database
  Future<void> switchFirm(String newFirmId, SharedPreferences prefs) async {
    await close();
    _activeFirmId = newFirmId;
    await prefs.setString('active_firm_id', newFirmId);
    await init(prefs);
  }

  /// Purges all data in all collections for active firm
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

  /// Cascading rename Party Name across all transactions, invoices, purchases, orders, credit notes, and debit notes
  Future<void> cascadeRenameParty(String partyUuid, String newPartyName) async {
    if (partyUuid.isEmpty || newPartyName.trim().isEmpty) return;
    try {
      final name = newPartyName.trim();
      final party = await isar.partys.filter().uuidEqualTo(partyUuid).findFirst();
      if (party == null) return;
      final partyId = party.id;
      final oldPartyName = party.partyName ?? '';

      await isar.writeTxn(() async {
        final invoices = await isar.invoices.filter().partyIdEqualTo(partyId).or().partyNameEqualTo(oldPartyName).findAll();
        for (var inv in invoices) {
          inv.partyName = name;
          inv.isSynced = false;
          inv.updatedAt = DateTime.now();
          await isar.invoices.put(inv);
        }

        final purchases = await isar.purchases.filter().partyIdEqualTo(partyId).or().partyNameEqualTo(oldPartyName).findAll();
        for (var pur in purchases) {
          pur.partyName = name;
          pur.isSynced = false;
          pur.updatedAt = DateTime.now();
          await isar.purchases.put(pur);
        }

        final orders = await isar.orders.filter().partyIdEqualTo(partyId).or().partyNameEqualTo(oldPartyName).findAll();
        for (var ord in orders) {
          ord.partyName = name;
          ord.isSynced = false;
          ord.updatedAt = DateTime.now();
          await isar.orders.put(ord);
        }

        final txns = await isar.transactions.filter().partyUuidEqualTo(partyUuid).or().partyNameEqualTo(oldPartyName).findAll();
        for (var t in txns) {
          t.partyName = name;
          t.isSynced = false;
          t.updatedAt = DateTime.now();
          await isar.transactions.put(t);
        }

        final creditNotes = await isar.creditNotes.filter().partyIdEqualTo(partyId).or().partyNameEqualTo(oldPartyName).findAll();
        for (var cn in creditNotes) {
          cn.partyName = name;
          cn.isSynced = false;
          cn.updatedAt = DateTime.now();
          await isar.creditNotes.put(cn);
        }

        final debitNotes = await isar.debitNotes.filter().partyIdEqualTo(partyId).or().partyNameEqualTo(oldPartyName).findAll();
        for (var dn in debitNotes) {
          dn.partyName = name;
          dn.isSynced = false;
          dn.updatedAt = DateTime.now();
          await isar.debitNotes.put(dn);
        }
      });
      logger.info('Cascaded party rename to "$name" for UUID: $partyUuid');
    } catch (e) {
      logger.error('Failed to cascade rename party', e);
    }
  }

  /// Cascading rename Item Name across all line item collections and stock adjustments
  Future<void> cascadeRenameItem(String itemUuid, String newItemName) async {
    if (itemUuid.isEmpty || newItemName.trim().isEmpty) return;
    try {
      final name = newItemName.trim();
      final item = await isar.items.filter().uuidEqualTo(itemUuid).findFirst();
      if (item == null) return;
      final itemId = item.id;
      final oldItemName = item.itemName ?? '';

      await isar.writeTxn(() async {
        final invItems = await isar.invoiceItems.filter().itemIdEqualTo(itemId).or().itemNameEqualTo(oldItemName).findAll();
        for (var ii in invItems) {
          ii.itemName = name;
          ii.isSynced = false;
          await isar.invoiceItems.put(ii);
        }

        final purItems = await isar.purchaseItems.filter().itemIdEqualTo(itemId).or().itemNameEqualTo(oldItemName).findAll();
        for (var pi in purItems) {
          pi.itemName = name;
          pi.isSynced = false;
          await isar.purchaseItems.put(pi);
        }

        final ordItems = await isar.orderItems.filter().itemIdEqualTo(itemId).or().itemNameEqualTo(oldItemName).findAll();
        for (var oi in ordItems) {
          oi.itemName = name;
          oi.isSynced = false;
          await isar.orderItems.put(oi);
        }

        final cniItems = await isar.creditNoteItems.filter().itemIdEqualTo(itemId).or().itemNameEqualTo(oldItemName).findAll();
        for (var cni in cniItems) {
          cni.itemName = name;
          cni.isSynced = false;
          await isar.creditNoteItems.put(cni);
        }

        final dniItems = await isar.debitNoteItems.filter().itemIdEqualTo(itemId).or().itemNameEqualTo(oldItemName).findAll();
        for (var dni in dniItems) {
          dni.itemName = name;
          dni.isSynced = false;
          await isar.debitNoteItems.put(dni);
        }

        final adjs = await isar.collection<StockAdjustment>().filter().itemUuidEqualTo(itemUuid).or().itemNameEqualTo(oldItemName).findAll();
        for (var adj in adjs) {
          adj.itemName = name;
          adj.isSynced = false;
          adj.updatedAt = DateTime.now();
          await isar.collection<StockAdjustment>().put(adj);
        }
      });
      logger.info('Cascaded item rename to "$name" for UUID: $itemUuid');
    } catch (e) {
      logger.error('Failed to cascade rename item', e);
    }
  }

  /// Cascading rename Category Name across items and expenses
  Future<void> cascadeRenameCategory(String oldCategoryName, String newCategoryName) async {
    if (oldCategoryName.trim().isEmpty || newCategoryName.trim().isEmpty) return;
    try {
      final oldName = oldCategoryName.trim();
      final newName = newCategoryName.trim();
      await isar.writeTxn(() async {
        final expenses = await isar.expenses.filter().categoryEqualTo(oldName).findAll();
        for (var exp in expenses) {
          exp.category = newName;
          exp.isSynced = false;
          exp.updatedAt = DateTime.now();
          await isar.expenses.put(exp);
        }
      });
      logger.info('Cascaded category rename from "$oldName" to "$newName"');
    } catch (e) {
      logger.error('Failed to cascade rename category', e);
    }
  }

  /// Cascading rename Unit Name across items and line item units
  Future<void> cascadeRenameUnit(String oldUnitName, String newUnitName) async {
    if (oldUnitName.trim().isEmpty || newUnitName.trim().isEmpty) return;
    try {
      final oldName = oldUnitName.trim();
      final newName = newUnitName.trim();
      await isar.writeTxn(() async {
        final allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();
        final items = allItems.where((i) => i.primaryUnitName == oldName).toList();
        for (var item in items) {
          item.primaryUnitName = newName;
          item.isSynced = false;
          item.updatedAt = DateTime.now();
          await isar.items.put(item);
        }

        final allInvItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
        final invItems = allInvItems.where((ii) => ii.unit == oldName).toList();
        for (var ii in invItems) {
          ii.unit = newName;
          ii.isSynced = false;
          await isar.invoiceItems.put(ii);
        }

        final allPurItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();
        final purItems = allPurItems.where((pi) => pi.unit == oldName).toList();
        for (var pi in purItems) {
          pi.unit = newName;
          pi.isSynced = false;
          await isar.purchaseItems.put(pi);
        }

        final allOrdItems = await isar.orderItems.filter().isDeletedEqualTo(false).findAll();
        final ordItems = allOrdItems.where((oi) => oi.unit == oldName).toList();
        for (var oi in ordItems) {
          oi.unit = newName;
          oi.isSynced = false;
          await isar.orderItems.put(oi);
        }
      });
      logger.info('Cascaded unit rename from "$oldName" to "$newName"');
    } catch (e) {
      logger.error('Failed to cascade rename unit', e);
    }
  }

  /// Cascading rename Bank Account Name across transactions paymentMode
  Future<void> cascadeRenameBankAccount(String oldAccountName, String newAccountName) async {
    if (oldAccountName.trim().isEmpty || newAccountName.trim().isEmpty) return;
    try {
      final oldName = oldAccountName.trim();
      final newName = newAccountName.trim();
      await isar.writeTxn(() async {
        final txns = await isar.transactions.filter().paymentModeEqualTo(oldName).findAll();
        for (var t in txns) {
          t.paymentMode = newName;
          t.isSynced = false;
          t.updatedAt = DateTime.now();
          await isar.transactions.put(t);
        }
      });
      logger.info('Cascaded bank account rename from "$oldName" to "$newName"');
    } catch (e) {
      logger.error('Failed to cascade rename bank account', e);
    }
  }

  /// Utility to repair missing parent links and item links in imported data
  Future<void> repairLegacyData() async {
    try {
      logger.info('Starting legacy data repair...');

      // Step 1: READ all data OUTSIDE the write transaction
      final allItems = await isar.items.where().findAll();
      final invItems = await isar.invoiceItems.where().findAll();
      final ordItems = await isar.orderItems.where().findAll();
      final purItems = await isar.purchaseItems.where().findAll();

      // Build a name-to-item map for fast lookup
      final Map<String, Item> itemByName = {
        for (var i in allItems) if (i.itemName != null) i.itemName!: i,
      };

      // Step 2: Identify what needs to change (outside transaction)
      final List<InvoiceItem> invToUpdate = [];
      for (var ii in invItems) {
        bool changed = false;
        if ((ii.itemId == null || ii.itemId == 0) && ii.itemName != null) {
          final match = itemByName[ii.itemName!];
          if (match != null) {
            ii.itemId = match.id;
            changed = true;
          }
        }
        if (changed) invToUpdate.add(ii);
      }

      final List<OrderItem> ordToUpdate = [];
      for (var oi in ordItems) {
        bool changed = false;
        if ((oi.itemId == null || oi.itemId == 0) && oi.itemName != null) {
          final match = itemByName[oi.itemName!];
          if (match != null) {
            oi.itemId = match.id;
            changed = true;
          }
        }
        if (changed) ordToUpdate.add(oi);
      }

      final List<PurchaseItem> purToUpdate = [];
      for (var pi in purItems) {
        bool changed = false;
        if ((pi.itemId == null || pi.itemId == 0) && pi.itemName != null) {
          final match = itemByName[pi.itemName!];
          if (match != null) {
            pi.itemId = match.id;
            changed = true;
          }
        }
        if (changed) purToUpdate.add(pi);
      }

      logger.info('Repair: ${invToUpdate.length} invoice items, ${ordToUpdate.length} order items, ${purToUpdate.length} purchase items to fix.');

      // Step 3: WRITE in a single batch transaction
      if (invToUpdate.isNotEmpty || ordToUpdate.isNotEmpty || purToUpdate.isNotEmpty) {
        await isar.writeTxn(() async {
          if (invToUpdate.isNotEmpty) await isar.invoiceItems.putAll(invToUpdate);
          if (ordToUpdate.isNotEmpty) await isar.orderItems.putAll(ordToUpdate);
          if (purToUpdate.isNotEmpty) await isar.purchaseItems.putAll(purToUpdate);
        });
      }

      logger.info('Legacy data repair completed. Fixed ${invToUpdate.length + ordToUpdate.length + purToUpdate.length} records.');
    } catch (e) {
      logger.error('Failed to repair legacy data', e);
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
