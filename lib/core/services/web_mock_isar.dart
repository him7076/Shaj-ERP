import 'dart:async';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/isar_model.dart';
import 'package:business_sahaj_erp/data/local/collections/task_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
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
import 'package:business_sahaj_erp/data/local/collections/deleted_voucher_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/whatsapp_mapping_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/machinery_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/machinery_category_collection.dart';

class WebMockIsar implements Isar {
  int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  bool? _parseBool(dynamic val) {
    if (val == null) return null;
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
    if (val is int) return val == 1;
    return null;
  }

  String? _parseString(dynamic val) {
    if (val == null) return null;
    if (val is String) return val;
    return val.toString();
  }

  final String firmId;
  final SharedPreferences? prefs;
  static final Map<String, Map<String, List<dynamic>>> _dbs = {};

  WebMockIsar({this.firmId = 'firm_default', this.prefs}) {
    if (prefs != null) {
      loadFromPrefs(prefs!);
    }
  }

  static void resetAllInMemDbs() {
    _dbs.clear();
  }

  Map<String, dynamic> exportCollectionsJson() {
    final Map<String, dynamic> exportedMap = {};
    _db.forEach((collectionName, list) {
      exportedMap[collectionName] = list.map((item) {
        try {
          return _entityToMap(item);
        } catch (_) {
          try {
            return (item as dynamic).toJson();
          } catch (_) {
            return <String, dynamic>{};
          }
        }
      }).toList();
    });
    return exportedMap;
  }

  void importCollectionsJson(Map<String, dynamic> jsonMap) {
    _db.clear();
    
    String _getTypeForCol(String col) {
      if (col == 'categorys') return 'Category';
      if (col == 'units') return 'Unit';
      if (col == 'brands') return 'Brand';
      if (col == 'partys') return 'Party';
      if (col == 'items') return 'Item';
      if (col == 'orderItems') return 'OrderItem';
      if (col == 'orders') return 'Order';
      if (col == 'invoiceItems') return 'InvoiceItem';
      if (col == 'invoices') return 'Invoice';
      if (col == 'settings') return 'Settings';
      if (col == 'tasks') return 'Task';
      if (col == 'users') return 'User';
      if (col == 'syncQueues') return 'SyncQueue';
      if (col == 'purchases') return 'Purchase';
      if (col == 'purchaseItems') return 'PurchaseItem';
      if (col == 'expenses') return 'Expense';
      if (col == 'expenseItems') return 'ExpenseItem';
      if (col == 'transactions') return 'Transaction';
      if (col == 'bankAccounts') return 'BankAccount';
      if (col == 'creditNotes') return 'CreditNote';
      if (col == 'creditNoteItems') return 'CreditNoteItem';
      if (col == 'debitNotes') return 'DebitNote';
      if (col == 'debitNoteItems') return 'DebitNoteItem';
      if (col == 'deletedVouchers') return 'DeletedVoucher';
      if (col == 'stockAdjustments') return 'StockAdjustment';
      if (col == 'whatsAppMappings') return 'WhatsAppMapping';
      if (col == 'machinerys') return 'Machinery';
      if (col == 'machineryCategorys') return 'MachineryCategory';
      return '';
    }

    jsonMap.forEach((collectionName, list) {
      if (list is List) {
        final expectedType = _getTypeForCol(collectionName);
        _db[collectionName] = list.map((item) {
          if (item is Map<String, dynamic>) {
            try {
              final parsed = _mapToEntity(item, expectedType);
              return parsed ?? item;
            } catch (e, stack) {
              print('WebMockIsar _mapToEntity failed for $expectedType: $e\n$stack');
              return item;
            }
          }
          return item;
        }).toList();
      }
    });
  }

  Timer? _autoSaveTimer;

  Future<void> autoSave() async {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 100), () async {
      try {
        final p = prefs ?? await SharedPreferences.getInstance();
        await saveToPrefs(p);
      } catch (e) {
        print('WebMockIsar autoSave failed: $e');
      }
    });
  }

  void clearAllData() {
    _db.clear();
    if (prefs != null) {
      final keys = prefs!.getKeys().where((k) => k.contains(firmId)).toList();
      for (var k in keys) {
        if (!k.startsWith('firm_name_') && !k.startsWith('firm_gst_') && !k.startsWith('firm_mobile_')) {
          prefs!.remove(k);
        }
      }
    }
  }

  /// Deep Repair: Re-parse every entity in every collection.
  /// Converts raw Maps back to typed entities, fixes null/missing fields,
  /// and saves everything back to SharedPreferences.
  /// Returns a map of collection name -> number of items repaired.
  Future<Map<String, int>> deepRepairAllEntities() async {
    final Map<String, int> repairStats = {};
    int totalRepaired = 0;
    int totalSkipped = 0;

    for (final collectionName in _db.keys.toList()) {
      final list = _db[collectionName];
      if (list == null || list.isEmpty) continue;

      final expectedType = _getTypeForCol(collectionName);
      if (expectedType.isEmpty) continue;

      int repairedInCollection = 0;
      final repairedList = <dynamic>[];

      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        
        try {
          if (item is Map) {
            // Item is a raw Map — needs conversion to typed entity
            final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
            final repaired = _mapToEntity(map, expectedType);
            if (repaired != null) {
              repairedList.add(repaired);
              repairedInCollection++;
            } else {
              repairedList.add(item); // Keep as-is if parsing fails
              totalSkipped++;
            }
          } else {
            // Item is already a typed entity — re-serialize and re-parse to fix any field issues
            try {
              final map = _entityToMap(item);
              if (map.isNotEmpty && map.containsKey('id')) {
                final reparsed = _mapToEntity(map, expectedType);
                if (reparsed != null) {
                  repairedList.add(reparsed);
                  repairedInCollection++;
                } else {
                  repairedList.add(item);
                }
              } else {
                repairedList.add(item);
              }
            } catch (_) {
              repairedList.add(item); // Keep original if re-parse fails
            }
          }
        } catch (e) {
          print('Deep repair failed for $expectedType item $i: $e');
          repairedList.add(item); // Keep original
          totalSkipped++;
        }
      }

      _db[collectionName] = repairedList;
      if (repairedInCollection > 0) {
        repairStats[collectionName] = repairedInCollection;
        totalRepaired += repairedInCollection;
      }
    }

    // Save repaired data to SharedPreferences
    if (prefs != null) {
      await saveToPrefs(prefs!);
    }

    print('Deep Repair Complete: $totalRepaired entities repaired across ${repairStats.length} collections. $totalSkipped skipped.');
    return repairStats;
  }

  bool get hasData {
    final partyList = _db['partys'] ?? [];
    final itemList = _db['items'] ?? [];
    return partyList.isNotEmpty || itemList.isNotEmpty;
  }

  Map<String, List<dynamic>> get _db => _dbs[firmId] ??= {};

  // Forces dart2js compilation to keep the Query inheritance relation
  static void dummyKeep() {
    final Query<Category> _cat = WebMockQuery<Category>([], WebMockCollection<Category>('', {}, WebMockIsar()));
    print(_cat);
    final Query<Unit> _u = WebMockQuery<Unit>([], WebMockCollection<Unit>('', {}, WebMockIsar()));
    print(_u);
    final Query<Brand> _b = WebMockQuery<Brand>([], WebMockCollection<Brand>('', {}, WebMockIsar()));
    print(_b);
    final Query<Party> _part = WebMockQuery<Party>([], WebMockCollection<Party>('', {}, WebMockIsar()));
    print(_part);
    final Query<Item> _item = WebMockQuery<Item>([], WebMockCollection<Item>('', {}, WebMockIsar()));
    print(_item);
    final Query<OrderItem> _oi = WebMockQuery<OrderItem>([], WebMockCollection<OrderItem>('', {}, WebMockIsar()));
    print(_oi);
    final Query<Order> _o = WebMockQuery<Order>([], WebMockCollection<Order>('', {}, WebMockIsar()));
    print(_o);
    final Query<InvoiceItem> _ii = WebMockQuery<InvoiceItem>([], WebMockCollection<InvoiceItem>('', {}, WebMockIsar()));
    print(_ii);
    final Query<Invoice> _inv = WebMockQuery<Invoice>([], WebMockCollection<Invoice>('', {}, WebMockIsar()));
    print(_inv);
    final Query<Settings> _s = WebMockQuery<Settings>([], WebMockCollection<Settings>('', {}, WebMockIsar()));
    print(_s);
    final Query<User> _usr = WebMockQuery<User>([], WebMockCollection<User>('', {}, WebMockIsar()));
    print(_usr);
    final Query<SyncQueue> _sq = WebMockQuery<SyncQueue>([], WebMockCollection<SyncQueue>('', {}, WebMockIsar()));
    print(_sq);
    final Query<Purchase> _p = WebMockQuery<Purchase>([], WebMockCollection<Purchase>('', {}, WebMockIsar()));
    print(_p);
    final Query<PurchaseItem> _pi = WebMockQuery<PurchaseItem>([], WebMockCollection<PurchaseItem>('', {}, WebMockIsar()));
    print(_pi);
    final Query<Expense> _e = WebMockQuery<Expense>([], WebMockCollection<Expense>('', {}, WebMockIsar()));
    print(_e);
    final Query<Transaction> _txn = WebMockQuery<Transaction>([], WebMockCollection<Transaction>('', {}, WebMockIsar()));
    print(_txn);
    final Query<BankAccount> _ba = WebMockQuery<BankAccount>([], WebMockCollection<BankAccount>('', {}, WebMockIsar()));
    print(_ba);
    final Query<CreditNote> _cn = WebMockQuery<CreditNote>([], WebMockCollection<CreditNote>('', {}, WebMockIsar()));
    print(_cn);
    final Query<CreditNoteItem> _cni = WebMockQuery<CreditNoteItem>([], WebMockCollection<CreditNoteItem>('', {}, WebMockIsar()));
    print(_cni);
    final Query<DebitNote> _dn = WebMockQuery<DebitNote>([], WebMockCollection<DebitNote>('', {}, WebMockIsar()));
    print(_dn);
    final Query<DebitNoteItem> _dni = WebMockQuery<DebitNoteItem>([], WebMockCollection<DebitNoteItem>('', {}, WebMockIsar()));
    print(_dni);
  }

  @override
  IsarCollection<T> collection<T>() {
    return WebMockCollection<T>(collectionNameOf<T>(), _db, this);
  }

  String collectionNameOf<T>() {
    if (T == Category) return 'categorys';
    if (T == Unit) return 'units';
    if (T == Brand) return 'brands';
    if (T == Party) return 'partys';
    if (T == Item) return 'items';
    if (T == OrderItem) return 'orderItems';
    if (T == Order) return 'orders';
    if (T == InvoiceItem) return 'invoiceItems';
    if (T == Invoice) return 'invoices';
    if (T == Settings) return 'settings';
    if (T == Task) return 'tasks';
    if (T == User) return 'users';
    if (T == SyncQueue) return 'syncQueues';
    if (T == Purchase) return 'purchases';
    if (T == PurchaseItem) return 'purchaseItems';
    if (T == Expense) return 'expenses';
    if (T == ExpenseItem) return 'expenseItems';
    if (T == Machinery) return 'machinerys';
    if (T == Transaction) return 'transactions';
    if (T == BankAccount) return 'bankAccounts';
    if (T == CreditNote) return 'creditNotes';
    if (T == CreditNoteItem) return 'creditNoteItems';
    if (T == DebitNote) return 'debitNotes';
    if (T == DebitNoteItem) return 'debitNoteItems';
    if (T == DeletedVoucher) return 'deletedVouchers';
    if (T == StockAdjustment) return 'stockAdjustments';
    if (T == WhatsAppMapping) return 'whatsAppMappings';
    return 'dynamics';
  }

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString().replaceAll('Symbol("', '').replaceAll('")', '');
    
    if (invocation.isGetter) {
      return _createTypedCollectionByName(name);
    }
    
    if (invocation.isMethod && name == 'writeTxn') {
      final callback = invocation.positionalArguments[0] as Function;
      return Future.sync(() => callback());
    }

    if (invocation.isMethod) {
      return Future.value(true);
    }

    return null;
  }

  dynamic _createTypedCollectionByName(String name) {
    if (name == 'categorys') return WebMockCollection<Category>('categorys', _db, this);
    if (name == 'units') return WebMockCollection<Unit>('units', _db, this);
    if (name == 'brands') return WebMockCollection<Brand>('brands', _db, this);
    if (name == 'partys') return WebMockCollection<Party>('partys', _db, this);
    if (name == 'items') return WebMockCollection<Item>('items', _db, this);
    if (name == 'orderItems') return WebMockCollection<OrderItem>('orderItems', _db, this);
    if (name == 'orders') return WebMockCollection<Order>('orders', _db, this);
    if (name == 'invoiceItems') return WebMockCollection<InvoiceItem>('invoiceItems', _db, this);
    if (name == 'invoices') return WebMockCollection<Invoice>('invoices', _db, this);
    if (name == 'settings') return WebMockCollection<Settings>('settings', _db, this);
    if (name == 'tasks') return WebMockCollection<Task>('tasks', _db, this);
    if (name == 'users') return WebMockCollection<User>('users', _db, this);
    if (name == 'syncQueues') return WebMockCollection<SyncQueue>('syncQueues', _db, this);
    if (name == 'purchases') return WebMockCollection<Purchase>('purchases', _db, this);
    if (name == 'purchaseItems') return WebMockCollection<PurchaseItem>('purchaseItems', _db, this);
    if (name == 'expenses') return WebMockCollection<Expense>('expenses', _db, this);
    if (name == 'transactions') return WebMockCollection<Transaction>('transactions', _db, this);
    if (name == 'bankAccounts') return WebMockCollection<BankAccount>('bankAccounts', _db, this);
    if (name == 'creditNotes') return WebMockCollection<CreditNote>('creditNotes', _db, this);
    if (name == 'creditNoteItems') return WebMockCollection<CreditNoteItem>('creditNoteItems', _db, this);
    if (name == 'debitNotes') return WebMockCollection<DebitNote>('debitNotes', _db, this);
    if (name == 'debitNoteItems') return WebMockCollection<DebitNoteItem>('debitNoteItems', _db, this);
    if (name == 'deletedVouchers') return WebMockCollection<DeletedVoucher>('deletedVouchers', _db, this);
    if (name == 'stockAdjustments') return WebMockCollection<StockAdjustment>('stockAdjustments', _db, this);
    if (name == 'whatsAppMappings') return WebMockCollection<WhatsAppMapping>('whatsAppMappings', _db, this);

    return WebMockCollection<dynamic>(name, _db, this);
  }

  Future<void> saveToPrefs(SharedPreferences prefsInstance) async {
    try {
      // 1. Save per-collection to prevent single-key 5MB browser localStorage QuotaExceededError
      _db.forEach((collectionName, list) {
        try {
          final collectionMaps = list.map((item) => _entityToMap(item)).toList();
          final colJson = jsonEncode(collectionMaps);
          final compressedBytes = GZipEncoder().encode(utf8.encode(colJson));
          if (compressedBytes != null) {
            final base64Str = base64Encode(compressedBytes);
            prefsInstance.setString('web_mock_col_${firmId}_$collectionName', base64Str);
          } else {
            prefsInstance.setString('web_mock_col_${firmId}_$collectionName', colJson);
          }
        } catch (colError) {
          print('Error saving web collection $collectionName: $colError');
        }
      });

      // 2. Also save master index list of non-empty collections
      final collectionNames = _db.keys.toList();
      await prefsInstance.setStringList('web_mock_cols_$firmId', collectionNames);

      // 3. Save backward-compatible full DB snapshot if within safe size limit (< 1.5MB)
      final fullData = <String, List<Map<String, dynamic>>>{};
      _db.forEach((collectionName, list) {
        fullData[collectionName] = list.map((item) => _entityToMap(item)).toList();
      });
      final jsonStr = jsonEncode(fullData);
      if (jsonStr.length < 1500000) {
        await prefsInstance.setString('web_mock_db_$firmId', jsonStr);
      } else {
        await prefsInstance.remove('web_mock_db_$firmId');
      }
    } catch (e) {
      print('Error saving web mock DB to SharedPreferences: $e');
    }
  }

  void loadFromPrefs(SharedPreferences prefsInstance) {
    try {
      bool loadedAnyCollection = false;
      final collectionNames = prefsInstance.getStringList('web_mock_cols_$firmId') ?? [
        'categorys', 'units', 'brands', 'partys', 'items', 'orderItems', 'orders',
        'invoiceItems', 'invoices', 'settings', 'users', 'syncQueues', 'purchases',
        'purchaseItems', 'expenses', 'transactions', 'bankAccounts', 'creditNotes',
        'creditNoteItems', 'debitNotes', 'debitNoteItems', 'tasks'
      ];

      for (var colName in collectionNames) {
        final colJson = prefsInstance.getString('web_mock_col_${firmId}_$colName');
        if (colJson != null && colJson.isNotEmpty) {
          try {
            List<dynamic> listData;
              if (colJson.startsWith('[')) {
                listData = jsonDecode(colJson) as List<dynamic>;
              } else {
                try {
                  final compressedBytes = base64Decode(colJson);
                  final jsonBytes = GZipDecoder().decodeBytes(compressedBytes);
                  listData = jsonDecode(utf8.decode(jsonBytes)) as List<dynamic>;
                } catch (_) {
                  listData = jsonDecode(colJson) as List<dynamic>;
                }
              }
            final expectedType = _getTypeForCol(colName);
            _db[colName] = listData.map((itemMap) {
               try {
                 return _mapToEntity(itemMap as Map<String, dynamic>, expectedType) ?? itemMap;
               } catch (e, stack) { 
                 print('WebMockIsar load from prefs failed for $expectedType: $e\n$stack');
                 return itemMap; 
               }
            }).toList();
            loadedAnyCollection = true;
          } catch (_) {}
        }
      }

      // Fallback: If per-collection loading found nothing, attempt loading legacy master string key
      if (!loadedAnyCollection) {
        final jsonStr = prefsInstance.getString('web_mock_db_$firmId');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          data.forEach((collectionName, listData) {
            final list = listData as List<dynamic>;
            final expectedType = _getTypeForCol(collectionName);
            _db[collectionName] = list.map((itemMap) {
              try {
                return _mapToEntity(itemMap as Map<String, dynamic>, expectedType) ?? itemMap;
              } catch (e, stack) { 
                print('WebMockIsar initial data load failed for $expectedType: $e\n$stack');
                return itemMap; 
              }
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading web mock DB from SharedPreferences: $e');
    }
  }

  String _getTypeForCol(String col) {
    if (col == 'categorys') return 'Category';
    if (col == 'units') return 'Unit';
    if (col == 'brands') return 'Brand';
    if (col == 'partys') return 'Party';
    if (col == 'items') return 'Item';
    if (col == 'orderItems') return 'OrderItem';
    if (col == 'orders') return 'Order';
    if (col == 'invoiceItems') return 'InvoiceItem';
    if (col == 'invoices') return 'Invoice';
    if (col == 'settings') return 'Settings';
    if (col == 'tasks') return 'Task';
    if (col == 'users') return 'User';
    if (col == 'syncQueues') return 'SyncQueue';
    if (col == 'purchases') return 'Purchase';
    if (col == 'purchaseItems') return 'PurchaseItem';
    if (col == 'expenses') return 'Expense';
    if (col == 'expenseItems') return 'ExpenseItem';
    if (col == 'transactions') return 'Transaction';
    if (col == 'bankAccounts') return 'BankAccount';
    if (col == 'creditNotes') return 'CreditNote';
    if (col == 'creditNoteItems') return 'CreditNoteItem';
    if (col == 'debitNotes') return 'DebitNote';
    if (col == 'debitNoteItems') return 'DebitNoteItem';
    if (col == 'deletedVouchers') return 'DeletedVoucher';
    if (col == 'stockAdjustments') return 'StockAdjustment';
    if (col == 'whatsAppMappings') return 'WhatsAppMapping';
    return '';
  }

  Map<String, dynamic> _entityToMap(dynamic entity) {
    if (entity is Category) {
      return {
        'type': 'Category',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'categoryName': entity.categoryName,
        'description': entity.description,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Unit) {
      return {
        'type': 'Unit',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'unitName': entity.unitName,
        'shortName': entity.shortName,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Brand) {
      return {
        'type': 'Brand',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'brandName': entity.brandName,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Party) {
      return {
        'type': 'Party',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'partyCode': entity.partyCode,
        'partyName': entity.partyName,
        'partyType': entity.partyType,
        'mobileNumber': entity.mobileNumber,
        'whatsappNumber': entity.whatsappNumber,
        'email': entity.email,
        'gstNumber': entity.gstNumber,
        'panNumber': entity.panNumber,
        'gstType': entity.gstType,
        'addressLine1': entity.addressLine1,
        'addressLine2': entity.addressLine2,
        'city': entity.city,
        'state': entity.state,
        'pincode': entity.pincode,
        'latitude': entity.latitude,
        'longitude': entity.longitude,
        'locationAddress': entity.locationAddress,
        'googleMapUrl': entity.googleMapUrl,
        'openingBalance': entity.openingBalance,
        'balanceType': entity.balanceType,
        'creditLimit': entity.creditLimit,
        'outstandingBalance': entity.outstandingBalance,
        'paymentTerms': entity.paymentTerms,
        'dueDays': entity.dueDays,
        'contactPerson': entity.contactPerson,
        'businessCategory': entity.businessCategory,
        'notes': entity.notes,
        'shopPhotos': entity.shopPhotos,
        'shopPhotoUrls': entity.shopPhotoUrls,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Item) {
      return {
        'type': 'Item',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'itemCode': entity.itemCode,
        'itemName': entity.itemName,
        'shortName': entity.shortName,
        'description': entity.description,
        'hsnCode': entity.hsnCode,
        'gstApplicable': entity.gstApplicable,
        'gstRate': entity.gstRate,
        'cessRate': entity.cessRate,
        'buyRate': entity.buyRate,
        'mrp': entity.mrp,
        'sellRate': entity.sellRate,
        'wholesaleRate': entity.wholesaleRate,
        'minimumSellingPrice': entity.minimumSellingPrice,
        'openingStock': entity.openingStock,
        'currentStock': entity.currentStock,
        'reorderLevel': entity.reorderLevel,
        'minimumStock': entity.minimumStock,
        'secondaryUnit': entity.secondaryUnit,
        'primaryUnitName': entity.primaryUnitName,
        'conversionFactor': entity.conversionFactor,
        'barcode': entity.barcode,
        'sku': entity.sku,
        'skuCode': entity.skuCode,
        'imagePaths': entity.imagePaths,
        'firebaseImageUrls': entity.firebaseImageUrls,
        'thumbnailImage': entity.thumbnailImage,
        'isBundle': entity.isBundle,
        'itemType': entity.itemType,
        'bundleComponentUuids': entity.bundleComponentUuids,
        'bundleComponentQuantities': entity.bundleComponentQuantities,
        'bundleComponentUnits': entity.bundleComponentUnits,
        'categoryId': entity.category.value?.id,
        'brandId': entity.brand.value?.id,
        'unitId': entity.unit.value?.id,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is OrderItem) {
      return {
        'type': 'OrderItem',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'selectedSubItemUuid': entity.selectedSubItemUuid,
        'selectedSubItemName': entity.selectedSubItemName,
        'quantity': entity.quantity,
        'freeQuantity': entity.freeQuantity,
        'unit': entity.unit,
        'rate': entity.rate,
        'discountPercent': entity.discountPercent,
        'discountAmount': entity.discountAmount,
        'taxableAmount': entity.taxableAmount,
        'gstPercent': entity.gstPercent,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Order) {
      return {
        'type': 'Order',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'orderNumber': entity.orderNumber,
        'orderDate': entity.orderDate?.toIso8601String(),
        'status': entity.status,
        'partyId': entity.partyId,
        'partyName': entity.partyName,
        'mobileNumber': entity.mobileNumber,
        'gstNumber': entity.gstNumber,
        'latitude': entity.latitude,
        'longitude': entity.longitude,
        'locationAddress': entity.locationAddress,
        'subtotal': entity.subtotal,
        'discountAmount': entity.discountAmount,
        'discountPercent': entity.discountPercent,
        'totalGST': entity.totalGST,
        'roundOff': entity.roundOff,
        'grandTotal': entity.grandTotal,
        'remarks': entity.remarks,
        'internalNotes': entity.internalNotes,
        'cancelledBy': entity.cancelledBy,
        'cancelledDate': entity.cancelledDate?.toIso8601String(),
        'cancellationReason': entity.cancellationReason,
        'createdBy': entity.createdBy,
        'editedBy': entity.editedBy,
        'editTime': entity.editTime?.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is InvoiceItem) {
      return {
        'type': 'InvoiceItem',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'description': entity.description,
        'selectedSubItemUuid': entity.selectedSubItemUuid,
        'selectedSubItemName': entity.selectedSubItemName,
        'parentInvoiceId': entity.parentInvoiceId,
        'parentInvoiceUuid': entity.parentInvoiceUuid,
        'quantity': entity.quantity,
        'freeQuantity': entity.freeQuantity,
        'unit': entity.unit,
        'rate': entity.rate,
        'buyRate': entity.buyRate,
        'discount': entity.discount,
        'taxableAmount': entity.taxableAmount,
        'gstRate': entity.gstRate,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
        'batchNumber': entity.batchNumber,
        'expiryDate': entity.expiryDate,
        'mfgDate': entity.mfgDate,
        'isBundle': entity.isBundle,
        'bundleComponentUuids': entity.bundleComponentUuids,
        'bundleComponentQuantities': entity.bundleComponentQuantities,
        'bundleComponentUnits': entity.bundleComponentUnits,
        'bundleComponentRates': entity.bundleComponentRates,
        'bundleComponentBuyRates': entity.bundleComponentBuyRates,
        'bundleComponentGstPercents': entity.bundleComponentGstPercents,
        'bundleComponentDescriptions': entity.bundleComponentDescriptions,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Invoice) {
      return {
        'type': 'Invoice',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'invoiceNumber': entity.invoiceNumber,
        'invoiceDate': entity.invoiceDate?.toIso8601String(),
        'invoiceType': entity.invoiceType,
        'invoiceStatus': entity.invoiceStatus,
        'sourceOrderId': entity.sourceOrderId,
        'sourceOrderNumber': entity.sourceOrderNumber,
        'partyId': entity.partyId,
        'partyName': entity.partyName,
        'gstNumber': entity.gstNumber,
        'address': entity.address,
        'subtotal': entity.subtotal,
        'discountAmount': entity.discountAmount,
        'taxableAmount': entity.taxableAmount,
        'cgstAmount': entity.cgstAmount,
        'sgstAmount': entity.sgstAmount,
        'igstAmount': entity.igstAmount,
        'totalGST': entity.totalGST,
        'roundOff': entity.roundOff,
        'grandTotal': entity.grandTotal,
        'paymentStatus': entity.paymentStatus,
        'paidAmount': entity.paidAmount,
        'pendingAmount': entity.pendingAmount,
        'dueDate': entity.dueDate?.toIso8601String(),
        'remarks': entity.remarks,
        'termsAndConditions': entity.termsAndConditions,
        'cancelledBy': entity.cancelledBy,
        'cancelledDate': entity.cancelledDate?.toIso8601String(),
        'cancellationReason': entity.cancellationReason,
        'createdBy': entity.createdBy,
        'editedBy': entity.editedBy,
        'editTime': entity.editTime?.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Settings) {
      return {
        'type': 'Settings',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'companyName': entity.companyName,
        'companyGST': entity.companyGST,
        'companyAddress': entity.companyAddress,
        'companyPhone': entity.companyPhone,
        'companyEmail': entity.companyEmail,
        'logoPath': entity.logoPath,
        'themeMode': entity.themeMode,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is User) {
      return {
        'type': 'User',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'name': entity.name,
        'email': entity.email,
        'role': entity.role,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is SyncQueue) {
      return {
        'type': 'SyncQueue',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'entityType': entity.entityType,
        'entityId': entity.entityId,
        'entityUuid': entity.entityUuid,
        'operation': entity.operation,
        'retryCount': entity.retryCount,
        'lastAttempt': entity.lastAttempt?.toIso8601String(),
        'lastError': entity.lastError,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Purchase) {
      return {
        'type': 'Purchase',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'purchaseNumber': entity.purchaseNumber,
        'supplierInvoiceNumber': entity.supplierInvoiceNumber,
        'purchaseDate': entity.purchaseDate?.toIso8601String(),
        'partyId': entity.partyId,
        'partyName': entity.partyName,
        'gstNumber': entity.gstNumber,
        'address': entity.address,
        'subtotal': entity.subtotal,
        'discountAmount': entity.discountAmount,
        'taxableAmount': entity.taxableAmount,
        'cgstAmount': entity.cgstAmount,
        'sgstAmount': entity.sgstAmount,
        'igstAmount': entity.igstAmount,
        'totalGST': entity.totalGST,
        'roundOff': entity.roundOff,
        'grandTotal': entity.grandTotal,
        'paymentStatus': entity.paymentStatus,
        'paidAmount': entity.paidAmount,
        'pendingAmount': entity.pendingAmount,
        'remarks': entity.remarks,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is PurchaseItem) {
      return {
        'type': 'PurchaseItem',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'purchaseId': entity.purchaseId,
        'purchaseUuid': entity.purchaseUuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'selectedSubItemUuid': entity.selectedSubItemUuid,
        'selectedSubItemName': entity.selectedSubItemName,
        'quantity': entity.quantity,
        'unit': entity.unit,
        'rate': entity.rate,
        'discount': entity.discount,
        'taxableAmount': entity.taxableAmount,
        'gstRate': entity.gstRate,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
        'batchNumber': entity.batchNumber,
        'expiryDate': entity.expiryDate,
        'mfgDate': entity.mfgDate,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Expense) {
      return {
        'type': 'Expense',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'category': entity.category,
        'amount': entity.amount,
        'expenseDate': entity.expenseDate?.toIso8601String(),
        'paymentMode': entity.paymentMode,
        'remarks': entity.remarks,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Transaction) {
      return {
        'type': 'Transaction',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'transactionNumber': entity.transactionNumber,
        'transactionDate': entity.transactionDate?.toIso8601String(),
        'partyUuid': entity.partyUuid,
        'partyName': entity.partyName,
        'transactionType': entity.transactionType,
        'tags': entity.tags,
        'amount': entity.amount,
        'paymentMode': entity.paymentMode,
        'referenceNumber': entity.referenceNumber,
        'remarks': entity.remarks,
        'linkedBillUuid': entity.linkedBillUuid,
        'linkedBillNumber': entity.linkedBillNumber,
        'targetPartyUuid': entity.targetPartyUuid,
        'targetPartyName': entity.targetPartyName,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is BankAccount) {
      return {
        'type': 'BankAccount',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'accountName': entity.accountName,
        'bankName': entity.bankName,
        'accountNumber': entity.accountNumber,
        'ifscCode': entity.ifscCode,
        'branchName': entity.branchName,
        'openingBalance': entity.openingBalance,
        'currentBalance': entity.currentBalance,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is CreditNote) {
      return {
        'type': 'CreditNote',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'creditNoteNumber': entity.creditNoteNumber,
        'creditNoteDate': entity.creditNoteDate?.toIso8601String(),
        'originalInvoiceNumber': entity.originalInvoiceNumber,
        'originalInvoiceUuid': entity.originalInvoiceUuid,
        'partyId': entity.partyId,
        'partyName': entity.partyName,
        'gstNumber': entity.gstNumber,
        'address': entity.address,
        'subtotal': entity.subtotal,
        'discountAmount': entity.discountAmount,
        'taxableAmount': entity.taxableAmount,
        'cgstAmount': entity.cgstAmount,
        'sgstAmount': entity.sgstAmount,
        'igstAmount': entity.igstAmount,
        'totalGST': entity.totalGST,
        'roundOff': entity.roundOff,
        'grandTotal': entity.grandTotal,
        'remarks': entity.remarks,
        'createdBy': entity.createdBy,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is CreditNoteItem) {
      return {
        'type': 'CreditNoteItem',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'selectedSubItemUuid': entity.selectedSubItemUuid,
        'selectedSubItemName': entity.selectedSubItemName,
        'parentCreditNoteId': entity.parentCreditNoteId,
        'quantity': entity.quantity,
        'freeQuantity': entity.freeQuantity,
        'rate': entity.rate,
        'discount': entity.discount,
        'taxableAmount': entity.taxableAmount,
        'gstRate': entity.gstRate,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
        'batchNumber': entity.batchNumber,
        'expiryDate': entity.expiryDate,
        'mfgDate': entity.mfgDate,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is DebitNote) {
      return {
        'type': 'DebitNote',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'debitNoteNumber': entity.debitNoteNumber,
        'debitNoteDate': entity.debitNoteDate?.toIso8601String(),
        'originalPurchaseNumber': entity.originalPurchaseNumber,
        'originalPurchaseUuid': entity.originalPurchaseUuid,
        'partyId': entity.partyId,
        'partyName': entity.partyName,
        'gstNumber': entity.gstNumber,
        'address': entity.address,
        'subtotal': entity.subtotal,
        'discountAmount': entity.discountAmount,
        'taxableAmount': entity.taxableAmount,
        'cgstAmount': entity.cgstAmount,
        'sgstAmount': entity.sgstAmount,
        'igstAmount': entity.igstAmount,
        'totalGST': entity.totalGST,
        'roundOff': entity.roundOff,
        'grandTotal': entity.grandTotal,
        'remarks': entity.remarks,
        'createdBy': entity.createdBy,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is DebitNoteItem) {
      return {
        'type': 'DebitNoteItem',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'selectedSubItemUuid': entity.selectedSubItemUuid,
        'selectedSubItemName': entity.selectedSubItemName,
        'parentDebitNoteId': entity.parentDebitNoteId,
        'quantity': entity.quantity,
        'freeQuantity': entity.freeQuantity,
        'unit': entity.unit,
        'rate': entity.rate,
        'discount': entity.discount,
        'taxableAmount': entity.taxableAmount,
        'gstRate': entity.gstRate,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
        'batchNumber': entity.batchNumber,
        'expiryDate': entity.expiryDate,
        'mfgDate': entity.mfgDate,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }

    if (entity is DeletedVoucher) {
      return {
        'type': 'DeletedVoucher',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'voucherType': entity.voucherType,
        'voucherNumber': entity.voucherNumber,
        'partyName': entity.partyName,
        'amount': entity.amount,
        'remarks': entity.remarks,
        'deletedAt': entity.deletedAt?.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is WhatsAppMapping) {
      return {
        'type': 'WhatsAppMapping',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'mappingType': entity.mappingType,
        'rawKey': entity.rawKey,
        'targetUuid': entity.targetUuid,
        'pcsPerBundle': entity.pcsPerBundle,
        'pcsPerCarton': entity.pcsPerCarton,
        'customRate': entity.customRate,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Task) {
      return {
        'type': 'Task',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'title': entity.title,
        'description': entity.description,
        'status': entity.status,
        'priority': entity.priority,
        'dueDate': entity.dueDate?.toIso8601String(),
        'completedAt': entity.completedAt?.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is ExpenseItem) {
      return {
        'type': 'ExpenseItem',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'itemName': entity.itemName,
        'defaultRate': entity.defaultRate,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is Machinery) {
      return {
        'type': 'Machinery',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'partyUuid': entity.partyUuid,
        'categoryUuid': entity.categoryUuid,
        'machineName': entity.machineName,
        'brandName': entity.brandName,
        'modelNumber': entity.modelNumber,
        'serialNumber': entity.serialNumber,
        'description': entity.description,
        'photos': entity.photos,
        'googlePhotosLink': entity.googlePhotosLink,
        'serviceIntervalMonths': entity.serviceIntervalMonths,
        'serviceIntervalDays': entity.serviceIntervalDays,
        'lastServiceDate': entity.lastServiceDate?.toIso8601String(),
        'nextServiceDate': entity.nextServiceDate?.toIso8601String(),
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is StockAdjustment) {
      return {
        'type': 'StockAdjustment',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'itemUuid': entity.itemUuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'adjustmentType': entity.adjustmentType,
        'quantity': entity.quantity,
        'unit': entity.unit,
        'ratePerUnit': entity.ratePerUnit,
        'totalValue': entity.totalValue,
        'adjustmentDate': entity.adjustmentDate?.toIso8601String(),
        'reason': entity.reason,
        'notes': entity.notes,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    if (entity is MachineryCategory) {
      return {
        'type': 'MachineryCategory',
        'id': entity.id,
        'uuid': (entity as IsarModel).uuid,
        'categoryName': entity.categoryName,
        'description': entity.description,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    // CRITICAL FALLBACK: If entity is a raw Map (failed _mapToEntity during load),
    // return it as-is so data is NOT lost during export/backup/save.
    if (entity is Map<String, dynamic>) {
      return entity;
    }
    if (entity is Map) {
      return Map<String, dynamic>.from(entity);
    }
    return {};
  }


  dynamic _mapToEntity(Map<String, dynamic> map, [String? defaultType]) {
    final type = _parseString(map['type']) ?? defaultType ?? '';
    switch (type) {
      case 'Category':
        return Category()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..categoryName = _parseString(map['categoryName'])
          ..description = _parseString(map['description'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'WhatsAppMapping':
        return WhatsAppMapping()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..mappingType = _parseString(map['mappingType'])
          ..rawKey = _parseString(map['rawKey'])
          ..targetUuid = _parseString(map['targetUuid'])
          ..pcsPerBundle = _parseDouble(map['pcsPerBundle'])
          ..pcsPerCarton = _parseDouble(map['pcsPerCarton'])
          ..customRate = _parseDouble(map['customRate'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Unit':
        return Unit()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..unitName = _parseString(map['unitName'])
          ..shortName = _parseString(map['shortName'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Brand':
        return Brand()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..brandName = _parseString(map['brandName'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Party':
        return Party()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..partyCode = _parseString(map['partyCode'])
          ..partyName = _parseString(map['partyName'])
          ..partyType = _parseString(map['partyType'])
          ..mobileNumber = _parseString(map['mobileNumber'])
          ..whatsappNumber = _parseString(map['whatsappNumber'])
          ..email = _parseString(map['email'])
          ..gstNumber = _parseString(map['gstNumber'])
          ..panNumber = _parseString(map['panNumber'])
          ..gstType = _parseString(map['gstType'])
          ..addressLine1 = _parseString(map['addressLine1'])
          ..addressLine2 = _parseString(map['addressLine2'])
          ..city = _parseString(map['city'])
          ..state = _parseString(map['state'])
          ..pincode = _parseString(map['pincode'])
          ..latitude = _parseDouble(map['latitude'])
          ..longitude = _parseDouble(map['longitude'])
          ..locationAddress = _parseString(map['locationAddress'])
          ..googleMapUrl = _parseString(map['googleMapUrl'])
          ..openingBalance = _parseDouble(map['openingBalance'])
          ..balanceType = _parseString(map['balanceType'])
          ..creditLimit = _parseDouble(map['creditLimit'])
          ..outstandingBalance = _parseDouble(map['outstandingBalance'])
          ..paymentTerms = _parseString(map['paymentTerms'])
          ..dueDays = _parseInt(map['dueDays'])
          ..contactPerson = _parseString(map['contactPerson'])
          ..businessCategory = _parseString(map['businessCategory'])
          ..notes = _parseString(map['notes'])
          ..shopPhotos = (map['shopPhotos'] as List<dynamic>?)?.cast<String>()
          ..shopPhotoUrls = (map['shopPhotoUrls'] as List<dynamic>?)?.cast<String>()
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Item':
        final item = Item()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..itemCode = _parseString(map['itemCode'])
          ..itemName = _parseString(map['itemName'])
          ..shortName = _parseString(map['shortName'])
          ..description = _parseString(map['description'])
          ..hsnCode = _parseString(map['hsnCode'])
          ..gstApplicable = (_parseBool(map['gstApplicable']) == true)
          ..gstRate = _parseDouble(map['gstRate'])
          ..cessRate = _parseDouble(map['cessRate'])
          ..buyRate = _parseDouble(map['buyRate'])
          ..mrp = _parseDouble(map['mrp'])
          ..sellRate = _parseDouble(map['sellRate'])
          ..wholesaleRate = _parseDouble(map['wholesaleRate'])
          ..minimumSellingPrice = _parseDouble(map['minimumSellingPrice'])
          ..openingStock = _parseDouble(map['openingStock'])
          ..currentStock = (() {
            final c = _parseDouble(map['currentStock']) ?? 0.0;
            final s = _parseDouble(map['stock']) ?? 0.0;
            final o = _parseDouble(map['openingStock']) ?? 0.0;
            if (c > 0.0) return c;
            if (s > 0.0) return s;
            if (o > 0.0) return o;
            return c;
          })()
          ..reorderLevel = _parseDouble(map['reorderLevel'])
          ..minimumStock = _parseDouble(map['minimumStock'])
          ..secondaryUnit = _parseString(map['secondaryUnit'])
          ..primaryUnitName = _parseString(map['primaryUnitName'])
          ..conversionFactor = _parseDouble(map['conversionFactor'])
          ..barcode = _parseString(map['barcode'])
          ..sku = _parseString(map['sku'])
          ..skuCode = _parseString(map['skuCode'])
          ..imagePaths = (map['imagePaths'] as List<dynamic>?)?.cast<String>()
          ..firebaseImageUrls = (map['firebaseImageUrls'] as List<dynamic>?)?.cast<String>()
          ..thumbnailImage = _parseString(map['thumbnailImage'])
          ..isBundle = map['isBundle'] as bool? ?? false
          ..itemType = _parseString(map['itemType'])
          ..bundleComponentUuids = (map['bundleComponentUuids'] as List<dynamic>?)?.cast<String>()
          ..bundleComponentQuantities = (map['bundleComponentQuantities'] as List<dynamic>?)?.cast<num>().map((e) => e.toDouble()).toList()
          ..bundleComponentUnits = (map['bundleComponentUnits'] as List<dynamic>?)?.cast<String>()
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;

        final catId = _parseInt(map['categoryId']);
        if (catId != null) {
          final catList = _db['categorys'];
          if (catList != null) {
            final cat = catList.firstWhere((e) => (e as IsarModel).id == catId, orElse: () => null);
            if (cat != null) item.category.value = cat as Category;
          }
        }

        final brandId = _parseInt(map['brandId']);
        if (brandId != null) {
          final brandList = _db['brands'];
          if (brandList != null) {
            final brand = brandList.firstWhere((e) => (e as IsarModel).id == brandId, orElse: () => null);
            if (brand != null) item.brand.value = brand as Brand;
          }
        }

        final unitId = _parseInt(map['unitId']);
        if (unitId != null) {
          final unitList = _db['units'];
          if (unitList != null) {
            final unit = unitList.firstWhere((e) => (e as IsarModel).id == unitId, orElse: () => null);
            if (unit != null) item.unit.value = unit as Unit;
          }
        }
        return item;
      case 'OrderItem':
        return OrderItem()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..itemId = _parseInt(map['itemId'])
          ..itemName = _parseString(map['itemName'])
          ..hsnCode = _parseString(map['hsnCode'])
          ..selectedSubItemUuid = _parseString(map['selectedSubItemUuid'])
          ..selectedSubItemName = _parseString(map['selectedSubItemName'])
          ..quantity = _parseDouble(map['quantity'])
          ..freeQuantity = _parseDouble(map['freeQuantity'])
          ..unit = _parseString(map['unit'])
          ..rate = _parseDouble(map['rate'])
          ..discountPercent = _parseDouble(map['discountPercent'])
          ..discountAmount = _parseDouble(map['discountAmount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..gstPercent = _parseDouble(map['gstPercent'])
          ..gstAmount = _parseDouble(map['gstAmount'])
          ..totalAmount = _parseDouble(map['totalAmount'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Order':
        return Order()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..orderNumber = _parseString(map['orderNumber'])
          ..orderDate = map['orderDate'] != null ? DateTime.parse(map['orderDate'] as String) : null
          ..status = _parseString(map['status'])
          ..partyId = _parseInt(map['partyId'])
          ..partyName = _parseString(map['partyName'])
          ..mobileNumber = _parseString(map['mobileNumber'])
          ..gstNumber = _parseString(map['gstNumber'])
          ..latitude = _parseDouble(map['latitude'])
          ..longitude = _parseDouble(map['longitude'])
          ..locationAddress = _parseString(map['locationAddress'])
          ..subtotal = _parseDouble(map['subtotal'])
          ..discountAmount = _parseDouble(map['discountAmount'])
          ..discountPercent = _parseDouble(map['discountPercent'])
          ..totalGST = _parseDouble(map['totalGST'])
          ..roundOff = _parseDouble(map['roundOff'])
          ..grandTotal = _parseDouble(map['grandTotal'])
          ..remarks = _parseString(map['remarks'])
          ..internalNotes = _parseString(map['internalNotes'])
          ..cancelledBy = _parseString(map['cancelledBy'])
          ..cancelledDate = map['cancelledDate'] != null ? DateTime.parse(map['cancelledDate'] as String) : null
          ..cancellationReason = _parseString(map['cancellationReason'])
          ..createdBy = _parseString(map['createdBy'])
          ..editedBy = _parseString(map['editedBy'])
          ..editTime = map['editTime'] != null ? DateTime.parse(map['editTime'] as String) : null
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'InvoiceItem':
        return InvoiceItem()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..itemId = _parseInt(map['itemId'])
          ..itemName = _parseString(map['itemName'])
          ..hsnCode = _parseString(map['hsnCode'])
          ..description = _parseString(map['description'])
          ..selectedSubItemUuid = _parseString(map['selectedSubItemUuid'])
          ..selectedSubItemName = _parseString(map['selectedSubItemName'])
          ..parentInvoiceId = _parseInt(map['parentInvoiceId'])
          ..parentInvoiceUuid = _parseString(map['parentInvoiceUuid'])
          ..quantity = _parseDouble(map['quantity'])
          ..freeQuantity = _parseDouble(map['freeQuantity'])
          ..unit = _parseString(map['unit'])
          ..rate = _parseDouble(map['rate'])
          ..buyRate = _parseDouble(map['buyRate'])
          ..discount = _parseDouble(map['discount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..gstRate = _parseDouble(map['gstRate'])
          ..gstAmount = _parseDouble(map['gstAmount'])
          ..totalAmount = _parseDouble(map['totalAmount'])
          ..batchNumber = _parseString(map['batchNumber'])
          ..expiryDate = _parseString(map['expiryDate'])
          ..mfgDate = _parseString(map['mfgDate'])
          ..isBundle = (_parseBool(map['isBundle']) == true)
          ..bundleComponentUuids = (map['bundleComponentUuids'] as List?)?.cast<String>()
          ..bundleComponentQuantities = (map['bundleComponentQuantities'] as List?)?.map((e) => (e as num).toDouble()).toList()
          ..bundleComponentUnits = (map['bundleComponentUnits'] as List?)?.cast<String>()
          ..bundleComponentRates = (map['bundleComponentRates'] as List?)?.map((e) => (e as num).toDouble()).toList()
          ..bundleComponentBuyRates = (map['bundleComponentBuyRates'] as List?)?.map((e) => (e as num).toDouble()).toList()
          ..bundleComponentGstPercents = (map['bundleComponentGstPercents'] as List?)?.map((e) => (e as num).toDouble()).toList()
          ..bundleComponentDescriptions = (map['bundleComponentDescriptions'] as List?)?.cast<String>()
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Invoice':
        return Invoice()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..invoiceNumber = _parseString(map['invoiceNumber'])
          ..invoiceDate = map['invoiceDate'] != null ? DateTime.parse(map['invoiceDate'] as String) : null
          ..invoiceType = _parseString(map['invoiceType'])
          ..invoiceStatus = _parseString(map['invoiceStatus'])
          ..sourceOrderId = _parseInt(map['sourceOrderId'])
          ..sourceOrderNumber = _parseString(map['sourceOrderNumber'])
          ..partyId = _parseInt(map['partyId'])
          ..partyName = _parseString(map['partyName'])
          ..gstNumber = _parseString(map['gstNumber'])
          ..address = _parseString(map['address'])
          ..subtotal = _parseDouble(map['subtotal'])
          ..discountAmount = _parseDouble(map['discountAmount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..cgstAmount = _parseDouble(map['cgstAmount'])
          ..sgstAmount = _parseDouble(map['sgstAmount'])
          ..igstAmount = _parseDouble(map['igstAmount'])
          ..totalGST = _parseDouble(map['totalGST'])
          ..roundOff = _parseDouble(map['roundOff'])
          ..grandTotal = _parseDouble(map['grandTotal'])
          ..paymentStatus = _parseString(map['paymentStatus'])
          ..paidAmount = _parseDouble(map['paidAmount'])
          ..pendingAmount = _parseDouble(map['pendingAmount'])
          ..dueDate = map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null
          ..remarks = _parseString(map['remarks'])
          ..termsAndConditions = _parseString(map['termsAndConditions'])
          ..cancelledBy = _parseString(map['cancelledBy'])
          ..cancelledDate = map['cancelledDate'] != null ? DateTime.parse(map['cancelledDate'] as String) : null
          ..cancellationReason = _parseString(map['cancellationReason'])
          ..createdBy = _parseString(map['createdBy'])
          ..editedBy = _parseString(map['editedBy'])
          ..editTime = map['editTime'] != null ? DateTime.parse(map['editTime'] as String) : null
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Settings':
        return Settings()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..companyName = _parseString(map['companyName'])
          ..companyGST = _parseString(map['companyGST'])
          ..companyAddress = _parseString(map['companyAddress'])
          ..companyPhone = _parseString(map['companyPhone'])
          ..companyEmail = _parseString(map['companyEmail'])
          ..logoPath = _parseString(map['logoPath'])
          ..themeMode = _parseString(map['themeMode'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'User':
        return User()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..name = _parseString(map['name'])
          ..email = _parseString(map['email'])
          ..role = _parseString(map['role'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'SyncQueue':
        return SyncQueue()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..entityType = _parseString(map['entityType'])
          ..entityId = _parseInt(map['entityId'])
          ..entityUuid = _parseString(map['entityUuid'])
          ..operation = _parseString(map['operation'])
          ..retryCount = _parseInt(map['retryCount']) ?? 0
          ..lastAttempt = map['lastAttempt'] != null ? DateTime.parse(map['lastAttempt'] as String) : null
          ..lastError = _parseString(map['lastError'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Purchase':
        return Purchase()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..purchaseNumber = _parseString(map['purchaseNumber'])
          ..supplierInvoiceNumber = _parseString(map['supplierInvoiceNumber'])
          ..purchaseDate = map['purchaseDate'] != null ? DateTime.parse(map['purchaseDate'] as String) : null
          ..partyId = _parseInt(map['partyId'])
          ..partyName = _parseString(map['partyName'])
          ..gstNumber = _parseString(map['gstNumber'])
          ..address = _parseString(map['address'])
          ..subtotal = _parseDouble(map['subtotal'])
          ..discountAmount = _parseDouble(map['discountAmount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..cgstAmount = _parseDouble(map['cgstAmount'])
          ..sgstAmount = _parseDouble(map['sgstAmount'])
          ..igstAmount = _parseDouble(map['igstAmount'])
          ..totalGST = _parseDouble(map['totalGST'])
          ..roundOff = _parseDouble(map['roundOff'])
          ..grandTotal = _parseDouble(map['grandTotal'])
          ..paymentStatus = _parseString(map['paymentStatus'])
          ..paidAmount = _parseDouble(map['paidAmount'])
          ..pendingAmount = _parseDouble(map['pendingAmount'])
          ..remarks = _parseString(map['remarks'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'PurchaseItem':
        return PurchaseItem()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..purchaseId = _parseInt(map['purchaseId'])
          ..purchaseUuid = _parseString(map['purchaseUuid'])
          ..itemId = _parseInt(map['itemId'])
          ..itemName = _parseString(map['itemName'])
          ..hsnCode = _parseString(map['hsnCode'])
          ..selectedSubItemUuid = _parseString(map['selectedSubItemUuid'])
          ..selectedSubItemName = _parseString(map['selectedSubItemName'])
          ..quantity = _parseDouble(map['quantity'])
          ..unit = _parseString(map['unit'])
          ..rate = _parseDouble(map['rate'])
          ..discount = _parseDouble(map['discount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..gstRate = _parseDouble(map['gstRate'])
          ..gstAmount = _parseDouble(map['gstAmount'])
          ..totalAmount = _parseDouble(map['totalAmount'])
          ..batchNumber = _parseString(map['batchNumber'])
          ..expiryDate = _parseString(map['expiryDate'])
          ..mfgDate = _parseString(map['mfgDate'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Expense':
        return Expense()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..category = _parseString(map['category'])
          ..amount = _parseDouble(map['amount'])
          ..expenseDate = map['expenseDate'] != null ? DateTime.parse(map['expenseDate'] as String) : null
          ..paymentMode = _parseString(map['paymentMode'])
          ..remarks = _parseString(map['remarks'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Transaction':
        return Transaction()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..transactionNumber = _parseString(map['transactionNumber'])
          ..transactionDate = map['transactionDate'] != null ? DateTime.parse(map['transactionDate'] as String) : null
          ..partyUuid = _parseString(map['partyUuid'])
          ..partyName = _parseString(map['partyName'])
          ..transactionType = _parseString(map['transactionType'])
          ..tags = (map['tags'] as List?)?.map((e) => e.toString()).toList()
          ..amount = _parseDouble(map['amount'])
          ..paymentMode = _parseString(map['paymentMode'])
          ..referenceNumber = _parseString(map['referenceNumber'])
          ..remarks = _parseString(map['remarks'])
          ..linkedBillUuid = _parseString(map['linkedBillUuid'])
          ..linkedBillNumber = _parseString(map['linkedBillNumber'])
          ..targetPartyUuid = _parseString(map['targetPartyUuid'])
          ..targetPartyName = _parseString(map['targetPartyName'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'BankAccount':
        return BankAccount()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..accountName = _parseString(map['accountName'])
          ..bankName = _parseString(map['bankName'])
          ..accountNumber = _parseString(map['accountNumber'])
          ..ifscCode = _parseString(map['ifscCode'])
          ..branchName = _parseString(map['branchName'])
          ..openingBalance = _parseDouble(map['openingBalance'])
          ..currentBalance = _parseDouble(map['currentBalance'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'CreditNote':
        return CreditNote()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..creditNoteNumber = _parseString(map['creditNoteNumber'])
          ..creditNoteDate = map['creditNoteDate'] != null ? DateTime.parse(map['creditNoteDate'] as String) : null
          ..originalInvoiceNumber = _parseString(map['originalInvoiceNumber'])
          ..originalInvoiceUuid = _parseString(map['originalInvoiceUuid'])
          ..partyId = _parseInt(map['partyId'])
          ..partyName = _parseString(map['partyName'])
          ..gstNumber = _parseString(map['gstNumber'])
          ..address = _parseString(map['address'])
          ..subtotal = _parseDouble(map['subtotal'])
          ..discountAmount = _parseDouble(map['discountAmount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..cgstAmount = _parseDouble(map['cgstAmount'])
          ..sgstAmount = _parseDouble(map['sgstAmount'])
          ..igstAmount = _parseDouble(map['igstAmount'])
          ..totalGST = _parseDouble(map['totalGST'])
          ..roundOff = _parseDouble(map['roundOff'])
          ..grandTotal = _parseDouble(map['grandTotal'])
          ..remarks = _parseString(map['remarks'])
          ..createdBy = _parseString(map['createdBy'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'CreditNoteItem':
        return CreditNoteItem()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..itemId = _parseInt(map['itemId'])
          ..itemName = _parseString(map['itemName'])
          ..hsnCode = _parseString(map['hsnCode'])
          ..selectedSubItemUuid = _parseString(map['selectedSubItemUuid'])
          ..selectedSubItemName = _parseString(map['selectedSubItemName'])
          ..parentCreditNoteId = _parseInt(map['parentCreditNoteId'])
          ..quantity = _parseDouble(map['quantity'])
          ..freeQuantity = _parseDouble(map['freeQuantity'])
          ..unit = _parseString(map['unit'])
          ..rate = _parseDouble(map['rate'])
          ..discount = _parseDouble(map['discount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..gstRate = _parseDouble(map['gstRate'])
          ..gstAmount = _parseDouble(map['gstAmount'])
          ..totalAmount = _parseDouble(map['totalAmount'])
          ..batchNumber = _parseString(map['batchNumber'])
          ..expiryDate = _parseString(map['expiryDate'])
          ..mfgDate = _parseString(map['mfgDate'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'DebitNote':
        return DebitNote()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..debitNoteNumber = _parseString(map['debitNoteNumber'])
          ..debitNoteDate = map['debitNoteDate'] != null ? DateTime.parse(map['debitNoteDate'] as String) : null
          ..originalPurchaseNumber = _parseString(map['originalPurchaseNumber'])
          ..originalPurchaseUuid = _parseString(map['originalPurchaseUuid'])
          ..partyId = _parseInt(map['partyId'])
          ..partyName = _parseString(map['partyName'])
          ..gstNumber = _parseString(map['gstNumber'])
          ..address = _parseString(map['address'])
          ..subtotal = _parseDouble(map['subtotal'])
          ..discountAmount = _parseDouble(map['discountAmount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..cgstAmount = _parseDouble(map['cgstAmount'])
          ..sgstAmount = _parseDouble(map['sgstAmount'])
          ..igstAmount = _parseDouble(map['igstAmount'])
          ..totalGST = _parseDouble(map['totalGST'])
          ..roundOff = _parseDouble(map['roundOff'])
          ..grandTotal = _parseDouble(map['grandTotal'])
          ..remarks = _parseString(map['remarks'])
          ..createdBy = _parseString(map['createdBy'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'DebitNoteItem':
        return DebitNoteItem()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..itemId = _parseInt(map['itemId'])
          ..itemName = _parseString(map['itemName'])
          ..hsnCode = _parseString(map['hsnCode'])
          ..selectedSubItemUuid = _parseString(map['selectedSubItemUuid'])
          ..selectedSubItemName = _parseString(map['selectedSubItemName'])
          ..parentDebitNoteId = _parseInt(map['parentDebitNoteId'])
          ..quantity = _parseDouble(map['quantity'])
          ..freeQuantity = _parseDouble(map['freeQuantity'])
          ..unit = _parseString(map['unit'])
          ..rate = _parseDouble(map['rate'])
          ..discount = _parseDouble(map['discount'])
          ..taxableAmount = _parseDouble(map['taxableAmount'])
          ..gstRate = _parseDouble(map['gstRate'])
          ..gstAmount = _parseDouble(map['gstAmount'])
          ..totalAmount = _parseDouble(map['totalAmount'])
          ..batchNumber = _parseString(map['batchNumber'])
          ..expiryDate = _parseString(map['expiryDate'])
          ..mfgDate = _parseString(map['mfgDate'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'DeletedVoucher':
        return DeletedVoucher()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..voucherType = _parseString(map['voucherType'])
          ..voucherNumber = _parseString(map['voucherNumber'])
          ..partyName = _parseString(map['partyName'])
          ..amount = _parseDouble(map['amount'])
          ..remarks = _parseString(map['remarks'])
          ..deletedAt = map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'StockAdjustment':
        return StockAdjustment()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..itemUuid = _parseString(map['itemUuid'])
          ..itemId = _parseInt(map['itemId'])
          ..itemName = _parseString(map['itemName'])
          ..adjustmentType = _parseString(map['adjustmentType'])
          ..quantity = _parseDouble(map['quantity'])
          ..unit = _parseString(map['unit'])
          ..adjustmentDate = map['adjustmentDate'] != null ? DateTime.parse(map['adjustmentDate'] as String) : null
          ..reason = _parseString(map['reason'])
          ..notes = _parseString(map['notes'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Task':
        return Task()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..title = _parseString(map['title'])
          ..description = _parseString(map['description'])
          ..status = _parseString(map['status'])
          ..priority = _parseString(map['priority'])
          ..dueDate = map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null
          ..completedAt = map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'ExpenseItem':
        return ExpenseItem()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..itemName = _parseString(map['itemName'])
          ..defaultRate = _parseDouble(map['defaultRate'])
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      case 'Machinery':
        return Machinery()
          ..id = _parseInt(map['id']) ?? Isar.autoIncrement
          ..uuid = _parseString(map['uuid'])
          ..partyUuid = _parseString(map['partyUuid'])
          ..categoryUuid = _parseString(map['categoryUuid'])
          ..machineName = _parseString(map['machineName'])
          ..brandName = _parseString(map['brandName'])
          ..modelNumber = _parseString(map['modelNumber'])
          ..serialNumber = _parseString(map['serialNumber'])
          ..description = _parseString(map['description'])
          ..photos = (map['photos'] as List?)?.cast<String>()
          ..googlePhotosLink = _parseString(map['googlePhotosLink'])
          ..serviceIntervalMonths = _parseInt(map['serviceIntervalMonths'])
          ..serviceIntervalDays = _parseInt(map['serviceIntervalDays'])
          ..lastServiceDate = map['lastServiceDate'] != null ? DateTime.parse(map['lastServiceDate'] as String) : null
          ..nextServiceDate = map['nextServiceDate'] != null ? DateTime.parse(map['nextServiceDate'] as String) : null
          ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
          ..updatedAt = map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()
          ..isDeleted = (_parseBool(map['isDeleted']) == true)
          ..isSynced = (_parseBool(map['isSynced']) == true)
          ..version = _parseInt(map['version']) ?? 1;
      default:
        return null;
    }
  }

}

class WebMockCollection<T> extends IsarCollection<T> {
  final String collectionName;
  final Map<String, List<dynamic>> db;
  final WebMockIsar isarInstance;

  WebMockCollection(this.collectionName, this.db, this.isarInstance);

  @override
  Isar get isar => isarInstance;

  List<dynamic> get _list => db[collectionName] ??= [];

  @override
  CollectionSchema<T> get schema {
    if (T == Category) return CategorySchema as CollectionSchema<T>;
    if (T == Unit) return UnitSchema as CollectionSchema<T>;
    if (T == Brand) return BrandSchema as CollectionSchema<T>;
    if (T == Party) return PartySchema as CollectionSchema<T>;
    if (T == Item) return ItemSchema as CollectionSchema<T>;
    if (T == OrderItem) return OrderItemSchema as CollectionSchema<T>;
    if (T == Order) return OrderSchema as CollectionSchema<T>;
    if (T == InvoiceItem) return InvoiceItemSchema as CollectionSchema<T>;
    if (T == Invoice) return InvoiceSchema as CollectionSchema<T>;
    if (T == Settings) return SettingsSchema as CollectionSchema<T>;
    if (T == User) return UserSchema as CollectionSchema<T>;
    if (T == SyncQueue) return SyncQueueSchema as CollectionSchema<T>;
    if (T == Purchase) return PurchaseSchema as CollectionSchema<T>;
    if (T == PurchaseItem) return PurchaseItemSchema as CollectionSchema<T>;
    if (T == Expense) return ExpenseSchema as CollectionSchema<T>;
    if (T == Transaction) return TransactionSchema as CollectionSchema<T>;
    // ExpenseItem, StockAdjustment, Machinery, BankAccount, CreditNote, CreditNoteItem,
    // DebitNote, DebitNoteItem, Task, WhatsAppMapping do not use schema getter in practice.
    // Return a safe fallback to prevent UnimplementedError crashes.
    throw UnimplementedError('No schema defined for type $T');
  }

  void _attachEntity(dynamic entity) {
    // No-op on Web Mock to avoid unattached IsarLink runtime crashes (aU/aY) in release minified builds
  }

  dynamic _createWebMockQuery(Type type, List<dynamic> list) {
    if (type == Category) return WebMockQuery<Category>(list, isarInstance.collection<Category>() as WebMockCollection<Category>);
    if (type == Unit) return WebMockQuery<Unit>(list, isarInstance.collection<Unit>() as WebMockCollection<Unit>);
    if (type == Brand) return WebMockQuery<Brand>(list, isarInstance.collection<Brand>() as WebMockCollection<Brand>);
    if (type == Party) return WebMockQuery<Party>(list, isarInstance.collection<Party>() as WebMockCollection<Party>);
    if (type == Item) return WebMockQuery<Item>(list, isarInstance.collection<Item>() as WebMockCollection<Item>);
    if (type == OrderItem) return WebMockQuery<OrderItem>(list, isarInstance.collection<OrderItem>() as WebMockCollection<OrderItem>);
    if (type == Order) return WebMockQuery<Order>(list, isarInstance.collection<Order>() as WebMockCollection<Order>);
    if (type == InvoiceItem) return WebMockQuery<InvoiceItem>(list, isarInstance.collection<InvoiceItem>() as WebMockCollection<InvoiceItem>);
    if (type == Invoice) return WebMockQuery<Invoice>(list, isarInstance.collection<Invoice>() as WebMockCollection<Invoice>);
    if (type == Settings) return WebMockQuery<Settings>(list, isarInstance.collection<Settings>() as WebMockCollection<Settings>);
    if (type == User) return WebMockQuery<User>(list, isarInstance.collection<User>() as WebMockCollection<User>);
    if (type == SyncQueue) return WebMockQuery<SyncQueue>(list, isarInstance.collection<SyncQueue>() as WebMockCollection<SyncQueue>);
    if (type == Purchase) return WebMockQuery<Purchase>(list, isarInstance.collection<Purchase>() as WebMockCollection<Purchase>);
    if (type == PurchaseItem) return WebMockQuery<PurchaseItem>(list, isarInstance.collection<PurchaseItem>() as WebMockCollection<PurchaseItem>);
    if (type == Expense) return WebMockQuery<Expense>(list, isarInstance.collection<Expense>() as WebMockCollection<Expense>);
    if (type == ExpenseItem) return WebMockQuery<ExpenseItem>(list, isarInstance.collection<ExpenseItem>() as WebMockCollection<ExpenseItem>);
    if (type == Transaction) return WebMockQuery<Transaction>(list, isarInstance.collection<Transaction>() as WebMockCollection<Transaction>);
    if (type == BankAccount) return WebMockQuery<BankAccount>(list, isarInstance.collection<BankAccount>() as WebMockCollection<BankAccount>);
    if (type == CreditNote) return WebMockQuery<CreditNote>(list, isarInstance.collection<CreditNote>() as WebMockCollection<CreditNote>);
    if (type == CreditNoteItem) return WebMockQuery<CreditNoteItem>(list, isarInstance.collection<CreditNoteItem>() as WebMockCollection<CreditNoteItem>);
    if (type == DebitNote) return WebMockQuery<DebitNote>(list, isarInstance.collection<DebitNote>() as WebMockCollection<DebitNote>);
    if (type == DebitNoteItem) return WebMockQuery<DebitNoteItem>(list, isarInstance.collection<DebitNoteItem>() as WebMockCollection<DebitNoteItem>);
    if (type == StockAdjustment) return WebMockQuery<StockAdjustment>(list, isarInstance.collection<StockAdjustment>() as WebMockCollection<StockAdjustment>);
    if (type == WhatsAppMapping) return WebMockQuery<WhatsAppMapping>(list, isarInstance.collection<WhatsAppMapping>() as WebMockCollection<WhatsAppMapping>);
    if (type == Task) return WebMockQuery<Task>(list, isarInstance.collection<Task>() as WebMockCollection<Task>);
    if (type == Machinery) return WebMockQuery<Machinery>(list, isarInstance.collection<Machinery>() as WebMockCollection<Machinery>);
    return WebMockQuery<T>(list, this);
  }

  @override
  Future<Id> put(T object) async {
    final entity = object as IsarModel;
    if (entity.id == null || entity.id == 0 || entity.id == Isar.autoIncrement) {
      int maxId = 0;
      for (var item in _list) {
        if ((item as IsarModel).id > maxId) maxId = (item as IsarModel).id;
      }
      entity.id = maxId + 1;
    }
    
    final idx = _list.indexWhere((e) => (e as IsarModel).uuid == (entity as IsarModel).uuid || ((e as IsarModel).id == (entity as IsarModel).id && e.id != null));
    if (idx != -1) {
      _list[idx] = entity;
    } else {
      _list.add(entity);
    }
    _attachEntity(entity);

    await isarInstance.autoSave();
    return entity.id;
  }

  @override
  Future<List<Id>> putAll(List<T> objects) async {
    final List<int> ids = [];
    for (var entity in objects) {
      final id = await put(entity);
      ids.add(id);
    }
    return ids;
  }

  @override
  Future<T?> get(Id id) async {
    final entity = _list.firstWhere((e) => (e as IsarModel).id == id, orElse: () => null);
    if (entity != null) {
      _attachEntity(entity);
    }
    return entity as T?;
  }

  @override
  Future<List<T?>> getAll(List<Id> ids) async {
    final result = ids.map((id) => _list.firstWhere((e) => (e as IsarModel).id == id, orElse: () => null)).toList();
    for (var entity in result) {
      if (entity != null) {
        _attachEntity(entity);
      }
    }
    return result.cast<T?>();
  }

  @override
  Future<bool> delete(Id id) async {
    final len = _list.length;
    _list.removeWhere((e) => e.id == id);
    final deleted = _list.length < len;
    if (deleted) {
      await isarInstance.autoSave();
    }
    return deleted;
  }

  @override
  Future<int> deleteAll(List<Id> ids) async {
    int count = 0;
    for (var id in ids) {
      if (await delete(id)) {
        count++;
      }
    }
    return count;
  }

  @override
  Future<void> clear() async {
    _list.clear();
    await isarInstance.autoSave();
  }

  @override
  Future<int> count() async {
    return _list.length;
  }

  int countSync() {
    return _list.length;
  }

  @override
  Query<R> buildQuery<R>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) {
    var list = _list.toList();
    
    if (filter != null) {
      list = list.where((item) => _matchFilter(item, filter)).toList();
    }
    
    if (sortBy.isNotEmpty) {
      list.sort((a, b) {
        for (var sortProp in sortBy) {
          final prop = sortProp.property;
          final sortAsc = sortProp.sort == Sort.asc;
          final valA = _getPropertyValue(a, prop);
          final valB = _getPropertyValue(b, prop);
          if (valA == null || valB == null) continue;
          
          final cmp = (valA as Comparable).compareTo(valB);
          if (cmp != 0) {
            return sortAsc ? cmp : -cmp;
          }
        }
        return 0;
      });
    }
    
    if (offset != null && offset > 0) {
      if (offset >= list.length) {
        list = [];
      } else {
        list = list.sublist(offset);
      }
    }
    if (limit != null && limit > 0 && limit < list.length) {
      list = list.sublist(0, limit);
    }
    
    return _createWebMockQuery(R, list) as Query<R>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  bool _matchFilter(dynamic item, FilterOperation? filter) {
    if (filter == null) return true;
    
    if (filter is FilterGroup) {
      if (filter.filters.isEmpty) return true;
      if (filter.type == FilterGroupType.and) {
        return filter.filters.every((f) => _matchFilter(item, f));
      } else {
        return filter.filters.any((f) => _matchFilter(item, f));
      }
    }
    
    if (filter is FilterCondition) {
      final prop = filter.property;
      final val = filter.value1;
      final type = filter.type;
      final caseSensitive = filter.caseSensitive;
      
      final itemValue = _getPropertyValue(item, prop);
      if (itemValue == null) {
        final typeStr = type.toString().split('.').last;
        if (typeStr == 'isNull') return true;
        if (typeStr == 'isNotNull') return false;
        return false;
      }
      
      final itemStr = itemValue.toString();
      final valStr = val?.toString() ?? '';
      
      final matchStr = caseSensitive ? itemStr : itemStr.toLowerCase();
      final targetStr = caseSensitive ? valStr : valStr.toLowerCase();

      final typeStr = type.toString().split('.').last;
      if (typeStr == 'eq' || typeStr == 'equalTo') {
        return itemValue == val;
      } else if (typeStr == 'matches' || typeStr == 'contains') {
        return matchStr.contains(targetStr);
      } else if (typeStr == 'startsWith') {
        return matchStr.startsWith(targetStr);
      } else if (typeStr == 'endsWith') {
        return matchStr.endsWith(targetStr);
      } else if (typeStr == 'gt' || typeStr == 'greaterThan') {
        if (itemValue is DateTime && val is DateTime) return itemValue.isAfter(val);
        return (itemValue as num) > (val as num);
      } else if (typeStr == 'gte' || typeStr == 'greaterThanOrEqualTo') {
        if (itemValue is DateTime && val is DateTime) return !itemValue.isBefore(val);
        return (itemValue as num) >= (val as num);
      } else if (typeStr == 'lt' || typeStr == 'lessThan') {
        if (itemValue is DateTime && val is DateTime) return itemValue.isBefore(val);
        return (itemValue as num) < (val as num);
      } else if (typeStr == 'lte' || typeStr == 'lessThanOrEqualTo') {
        if (itemValue is DateTime && val is DateTime) return !itemValue.isAfter(val);
        return (itemValue as num) <= (val as num);
      } else if (typeStr == 'between') {
        final val2 = filter.value2;
        if (itemValue is DateTime) {
          final lower = val is DateTime ? val : DateTime(2000);
          final upper = val2 is DateTime ? val2 : DateTime(2100);
          return !itemValue.isBefore(lower) && !itemValue.isAfter(upper);
        }
        if (itemValue is num && val is num && val2 is num) {
          return itemValue >= val && itemValue <= val2;
        }
        return true;
      } else if (typeStr == 'isNotNull') {
        return true;
      } else if (typeStr == 'isNull') {
        return false;
      }
    }
    
    // Unsupported filter type (like Link filters in Web Mock) should NOT match all items!
    return false;
  }

  dynamic _getPropertyValue(dynamic item, String propName) {
    final prop = propName.toLowerCase();
    
    // CRITICAL: If item is a raw Map (failed _mapToEntity), read from map directly
    if (item is Map) {
      final mapItem = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
      if (mapItem.containsKey(propName)) return mapItem[propName];
      for (final key in mapItem.keys) {
        if (key.toLowerCase() == prop) return mapItem[key];
      }
      return null;
    }
    
    // Common properties for all IsarModel types
    if (prop == 'uuid') return item.uuid;
    if (prop == 'id') return (item as IsarModel).id;
    if (prop == 'isdeleted') return item.isDeleted;
    if (prop == 'issynced') return item.isSynced;
    if (prop == 'createdat') return item.createdAt;
    if (prop == 'updatedat') return item.updatedAt;
    if (prop == 'version') return item.version;
    
    if (item is Item) {
      if (prop == 'itemname') return item.itemName;
      if (prop == 'itemcode') return item.itemCode;
      if (prop == 'barcode') return item.barcode;
      if (prop == 'hsncode') return item.hsnCode;
      if (prop == 'sku') return item.sku;
      if (prop == 'skucode') return item.skuCode;
      if (prop == 'currentstock') return item.currentStock;
      if (prop == 'sellrate') return item.sellRate;
      if (prop == 'buyrate') return item.buyRate;
      if (prop == 'gstrate') return item.gstRate;
      if (prop == 'itemtype') return item.itemType;
      if (prop == 'isbundle') return item.isBundle;
    }
    if (item is Party) {
      if (prop == 'partyname') return item.partyName;
      if (prop == 'partycode') return item.partyCode;
      if (prop == 'mobilenumber') return item.mobileNumber;
      if (prop == 'partytype') return item.partyType;
      if (prop == 'email') return item.email;
      if (prop == 'gstnumber') return item.gstNumber;
      if (prop == 'outstandingbalance') return item.outstandingBalance;
    }
    if (item is Order) {
      if (prop == 'ordernumber') return item.orderNumber;
      if (prop == 'orderdate') return item.orderDate;
      if (prop == 'status') return item.status;
      if (prop == 'partyid') return item.partyId;
      if (prop == 'partyname') return item.partyName;
      if (prop == 'grandtotal') return item.grandTotal;
      if (prop == 'remarks') return item.remarks;
    }
    if (item is Invoice) {
      if (prop == 'invoicenumber') return item.invoiceNumber;
      if (prop == 'invoicedate') return item.invoiceDate;
      if (prop == 'invoicetype') return item.invoiceType;
      if (prop == 'invoicestatus') return item.invoiceStatus;
      if (prop == 'paymentstatus') return item.paymentStatus;
      if (prop == 'partyid') return item.partyId;
      if (prop == 'partyname') return item.partyName;
      if (prop == 'grandtotal') return item.grandTotal;
      if (prop == 'paidamount') return item.paidAmount;
      if (prop == 'pendingamount') return item.pendingAmount;
      if (prop == 'remarks') return item.remarks;
    }
    if (item is Category) {
      if (prop == 'categoryname') return item.categoryName;
    }
    if (item is Brand) {
      if (prop == 'brandname') return item.brandName;
    }
    if (item is Unit) {
      if (prop == 'unitname') return item.unitName;
      if (prop == 'shortname') return item.shortName;
    }
    if (item is Purchase) {
      if (prop == 'purchasenumber') return item.purchaseNumber;
      if (prop == 'supplierinvoicenumber') return item.supplierInvoiceNumber;
      if (prop == 'purchasedate') return item.purchaseDate;
      if (prop == 'partyname') return item.partyName;
      if (prop == 'partyid') return item.partyId;
      if (prop == 'paymentstatus') return item.paymentStatus;
      if (prop == 'grandtotal') return item.grandTotal;
      if (prop == 'paidamount') return item.paidAmount;
      if (prop == 'remarks') return item.remarks;
    }
    if (item is PurchaseItem) {
      if (prop == 'purchaseid') return item.purchaseId;
      if (prop == 'purchaseuuid') return item.purchaseUuid;
      if (prop == 'itemid') return item.itemId;
      if (prop == 'itemname') return item.itemName;
    }
    if (item is OrderItem) {
      if (prop == 'itemid') return item.itemId;
      if (prop == 'itemname') return item.itemName;
    }
    if (item is InvoiceItem) {
      if (prop == 'parentinvoiceid') return item.parentInvoiceId;
      if (prop == 'parentinvoiceuuid') return item.parentInvoiceUuid;
      if (prop == 'itemid') return item.itemId;
      if (prop == 'itemname') return item.itemName;
    }
    if (item is CreditNote) {
      if (prop == 'partyid') return item.partyId;
      if (prop == 'partyname') return item.partyName;
      if (prop == 'creditnotenumber') return item.creditNoteNumber;
      if (prop == 'creditnotedate') return item.creditNoteDate;
    }
    if (item is DebitNote) {
      if (prop == 'partyid') return item.partyId;
      if (prop == 'partyname') return item.partyName;
      if (prop == 'debitnotenumber') return item.debitNoteNumber;
      if (prop == 'debitnotedate') return item.debitNoteDate;
    }
    if (item is Expense) {
      if (prop == 'category') return item.category;
      if (prop == 'amount') return item.amount;
      if (prop == 'expensedate') return item.expenseDate;
      if (prop == 'paymentmode') return item.paymentMode;
      if (prop == 'remarks') return item.remarks;
    }
    if (item is Transaction) {
      if (prop == 'transactionnumber') return item.transactionNumber;
      if (prop == 'transactiondate') return item.transactionDate;
      if (prop == 'transactiontype') return item.transactionType;
      if (prop == 'partyuuid') return item.partyUuid;
      if (prop == 'partyname') return item.partyName;
      if (prop == 'targetpartyuuid') return item.targetPartyUuid;
      if (prop == 'targetpartyname') return item.targetPartyName;
      if (prop == 'linkedbilluuid') return item.linkedBillUuid;
      if (prop == 'linkedbillnumber') return item.linkedBillNumber;
      if (prop == 'amount') return item.amount;
      if (prop == 'paymentmode') return item.paymentMode;
      if (prop == 'paymentstatus') return item.paymentStatus;
      if (prop == 'referencenumber') return item.referenceNumber;
      if (prop == 'remarks') return item.remarks;
    }
    if (item is BankAccount) {
      if (prop == 'accountname') return item.accountName;
      if (prop == 'bankname') return item.bankName;
    }
    if (item is StockAdjustment) {
      if (prop == 'itemuuid') return item.itemUuid;
      if (prop == 'itemname') return item.itemName;
    }
    if (item is Task) {
      if (prop == 'title') return item.title;
      if (prop == 'status') return item.status;
      if (prop == 'priority') return item.priority;
    }
    
    // CRITICAL FALLBACK: If item is a raw Map (failed _mapToEntity during load),
    // read properties directly from map keys so filters still work.
    if (item is Map<String, dynamic>) {
      // Try exact prop name first, then camelCase variations
      if (item.containsKey(propName)) return item[propName];
      // propName comes in lowercase from FilterCondition, try original camelCase keys
      for (final key in item.keys) {
        if (key.toLowerCase() == prop) return item[key];
      }
    }
    if (item is Map) {
      final mapItem = Map<String, dynamic>.from(item);
      if (mapItem.containsKey(propName)) return mapItem[propName];
      for (final key in mapItem.keys) {
        if (key.toLowerCase() == prop) return mapItem[key];
      }
    }
    
    return null;
  }
}

class WebMockQuery<T> extends Query<T> {
  final List<dynamic> list;
  final WebMockCollection<T> collection;

  WebMockQuery(this.list, this.collection);

  @override
  Future<T?> findFirst() async {
    final entity = list.isEmpty ? null : list.first as T?;
    if (entity != null) {
      collection._attachEntity(entity);
    }
    return entity;
  }

  @override
  Future<List<T>> findAll() async {
    for (var entity in list) {
      collection._attachEntity(entity);
    }
    return list.cast<T>();
  }

  @override
  Future<int> count() async {
    return list.length;
  }

  int countSync() {
    return list.length;
  }

  @override
  Future<int> deleteAll() async {
    final count = list.length;
    for (var entity in list) {
      collection._list.remove(entity);
    }
    if (count > 0 && collection.isarInstance.prefs != null) {
      await collection.isarInstance.saveToPrefs(collection.isarInstance.prefs!);
    }
    return count;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

