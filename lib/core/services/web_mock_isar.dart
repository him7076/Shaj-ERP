import 'dart:async';
import 'package:isar/isar.dart';
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

class WebMockIsar implements Isar {
  final String firmId;
  static final Map<String, Map<String, List<dynamic>>> _dbs = {};

  WebMockIsar({this.firmId = 'firm_default'});

  Map<String, List<dynamic>> get _db => _dbs[firmId] ??= {};

  // Forces dart2js compilation to keep the Query inheritance relation
  static void _dummyKeep() {
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
    if (T == User) return 'users';
    if (T == SyncQueue) return 'syncQueues';
    if (T == Purchase) return 'purchases';
    if (T == PurchaseItem) return 'purchaseItems';
    if (T == Expense) return 'expenses';
    if (T == Transaction) return 'transactions';
    return 'dynamics';
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
    if (name == 'users') return WebMockCollection<User>('users', _db, this);
    if (name == 'syncQueues') return WebMockCollection<SyncQueue>('syncQueues', _db, this);
    if (name == 'purchases') return WebMockCollection<Purchase>('purchases', _db, this);
    if (name == 'purchaseItems') return WebMockCollection<PurchaseItem>('purchaseItems', _db, this);
    if (name == 'expenses') return WebMockCollection<Expense>('expenses', _db, this);
    if (name == 'transactions') return WebMockCollection<Transaction>('transactions', _db, this);
    return WebMockCollection<dynamic>(name, _db, this);
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
    throw UnimplementedError('No schema defined for type $T');
  }

  void _attachEntity(dynamic entity) {
    if (entity == null) return;
    try {
      schema.attach(this, entity.id, entity as T);
    } catch (_) {}

    // Manually populate links for mock database on Web
    try {
      if (entity is Order) {
        if (entity.party.value == null && entity.partyId != null) {
          final parties = isarInstance.collection<Party>() as WebMockCollection<Party>;
          entity.party.value = parties._list.firstWhere((p) => p.id == entity.partyId, orElse: () => null) as Party?;
        }
        // Load OrderItems
        final orderItems = isarInstance.collection<OrderItem>() as WebMockCollection<OrderItem>;
        final matchingItems = orderItems._list.where((oi) => oi.order.value?.id == entity.id).toList();
        entity.orderItems.clear();
        entity.orderItems.addAll(matchingItems.cast<OrderItem>());
      } else if (entity is OrderItem) {
        if (entity.item.value == null && entity.itemId != null) {
          final items = isarInstance.collection<Item>() as WebMockCollection<Item>;
          entity.item.value = items._list.firstWhere((i) => i.id == entity.itemId, orElse: () => null) as Item?;
        }
      } else if (entity is Invoice) {
        if (entity.party.value == null && entity.partyId != null) {
          final parties = isarInstance.collection<Party>() as WebMockCollection<Party>;
          entity.party.value = parties._list.firstWhere((p) => p.id == entity.partyId, orElse: () => null) as Party?;
        }
        // Load InvoiceItems
        final invoiceItems = isarInstance.collection<InvoiceItem>() as WebMockCollection<InvoiceItem>;
        final matchingItems = invoiceItems._list.where((ii) => ii.invoice.value?.id == entity.id).toList();
        entity.invoiceItems.clear();
        entity.invoiceItems.addAll(matchingItems.cast<InvoiceItem>());
      } else if (entity is InvoiceItem) {
        if (entity.item.value == null && entity.itemId != null) {
          final items = isarInstance.collection<Item>() as WebMockCollection<Item>;
          entity.item.value = items._list.firstWhere((i) => i.id == entity.itemId, orElse: () => null) as Item?;
        }
      } else if (entity is Purchase) {
        if (entity.party.value == null && entity.partyId != null) {
          final parties = isarInstance.collection<Party>() as WebMockCollection<Party>;
          entity.party.value = parties._list.firstWhere((p) => p.id == entity.partyId, orElse: () => null) as Party?;
        }
        // Load PurchaseItems
        final purchaseItems = isarInstance.collection<PurchaseItem>() as WebMockCollection<PurchaseItem>;
        final matchingItems = purchaseItems._list.where((pi) => pi.purchase.value?.id == entity.id).toList();
        entity.purchaseItems.clear();
        entity.purchaseItems.addAll(matchingItems.cast<PurchaseItem>());
      } else if (entity is PurchaseItem) {
        if (entity.item.value == null && entity.itemId != null) {
          final items = isarInstance.collection<Item>() as WebMockCollection<Item>;
          entity.item.value = items._list.firstWhere((i) => i.id == entity.itemId, orElse: () => null) as Item?;
        }
      } else if (entity is Transaction) {
        if (entity.party.value == null && entity.partyUuid != null) {
          final parties = isarInstance.collection<Party>() as WebMockCollection<Party>;
          entity.party.value = parties._list.firstWhere((p) => p.uuid == entity.partyUuid, orElse: () => null) as Party?;
        }
      }
    } catch (_) {}
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
    if (type == Transaction) return WebMockQuery<Transaction>(list, isarInstance.collection<Transaction>() as WebMockCollection<Transaction>);
    return WebMockQuery<T>(list, this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString().replaceAll('Symbol("', '').replaceAll('")', '');

    if (invocation.isMethod) {
      if (name == 'put') {
        final entity = invocation.positionalArguments[0];
        if (entity.id == null || entity.id == 0 || entity.id == Isar.autoIncrement) {
          int maxId = 0;
          for (var item in _list) {
            if (item.id > maxId) maxId = item.id;
          }
          entity.id = maxId + 1;
        }
        
        final idx = _list.indexWhere((e) => e.uuid == entity.uuid || (e.id == entity.id && e.id != null));
        if (idx != -1) {
          _list[idx] = entity;
        } else {
          _list.add(entity);
        }
        _attachEntity(entity);
        return Future<int>.value(entity.id as int);
      }

      if (name == 'putAll') {
        final entities = invocation.positionalArguments[0] as List<dynamic>;
        final List<int> ids = [];
        for (var entity in entities) {
          if (entity.id == null || entity.id == 0 || entity.id == Isar.autoIncrement) {
            int maxId = 0;
            for (var item in _list) {
              if (item.id > maxId) maxId = item.id;
            }
            entity.id = maxId + 1;
          }
          final idx = _list.indexWhere((e) => e.uuid == entity.uuid || (e.id == entity.id && e.id != null));
          if (idx != -1) {
            _list[idx] = entity;
          } else {
            _list.add(entity);
          }
          _attachEntity(entity);
          ids.add(entity.id);
        }
        return Future<List<int>>.value(ids);
      }

      if (name == 'get') {
        final id = invocation.positionalArguments[0] as int;
        final entity = _list.firstWhere((e) => e.id == id, orElse: () => null);
        if (entity != null) {
          _attachEntity(entity);
        }
        return Future.value(entity as T?);
      }

      if (name == 'getAll') {
        final ids = invocation.positionalArguments[0] as List<int>;
        final result = ids.map((id) => _list.firstWhere((e) => e.id == id, orElse: () => null)).toList();
        for (var entity in result) {
          _attachEntity(entity);
        }
        return Future.value(result.cast<T>());
      }

      if (name == 'delete' || name == 'softDelete') {
        final id = invocation.positionalArguments[0] as int;
        _list.removeWhere((e) => e.id == id);
        return Future.value(true);
      }

      if (name == 'clear') {
        _list.clear();
        return Future.value(null);
      }

      if (name == 'buildQuery') {
        final filterGroup = invocation.namedArguments[Symbol('filter')] as FilterOperation?;
        final sortBy = invocation.namedArguments[Symbol('sortBy')] as List<SortProperty>?;
        final offset = invocation.namedArguments[Symbol('offset')] as int?;
        final limit = invocation.namedArguments[Symbol('limit')] as int?;
        
        var list = _list.toList();
        
        if (filterGroup != null) {
          list = list.where((item) => _matchFilter(item, filterGroup)).toList();
        }
        
        if (sortBy != null && sortBy.isNotEmpty) {
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
        
        if (offset != null && offset > 0 && offset < list.length) {
          list = list.sublist(offset);
        }
        if (limit != null && limit > 0 && limit < list.length) {
          list = list.sublist(0, limit);
        }
        
        final RType = invocation.typeArguments.isNotEmpty ? invocation.typeArguments.first : T;
        return _createWebMockQuery(RType, list);
      }
    }

    return null;
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
        return (itemValue as num) > (val as num);
      } else if (typeStr == 'lt' || typeStr == 'lessThan') {
        return (itemValue as num) < (val as num);
      } else if (typeStr == 'isNotNull') {
        return true;
      } else if (typeStr == 'isNull') {
        return false;
      }
    }
    
    return true;
  }

  dynamic _getPropertyValue(dynamic item, String propName) {
    final prop = propName.toLowerCase();
    
    if (prop == 'uuid') return item.uuid;
    if (prop == 'id') return item.id;
    if (prop == 'isdeleted') return item.isDeleted;
    if (prop == 'issynced') return item.isSynced;
    
    if (item is Item) {
      if (prop == 'itemname') return item.itemName;
      if (prop == 'itemcode') return item.itemCode;
      if (prop == 'barcode') return item.barcode;
      if (prop == 'hsncode') return item.hsnCode;
      if (prop == 'sku') return item.sku;
      if (prop == 'skucode') return item.skuCode;
    }
    if (item is Party) {
      if (prop == 'partyname') return item.partyName;
      if (prop == 'partycode') return item.partyCode;
      if (prop == 'mobilenumber') return item.mobileNumber;
      if (prop == 'partytype') return item.partyType;
    }
    if (item is Order) {
      if (prop == 'ordernumber') return item.orderNumber;
      if (prop == 'status') return item.status;
    }
    if (item is Invoice) {
      if (prop == 'invoicenumber') return item.invoiceNumber;
      if (prop == 'paymentstatus') return item.paymentStatus;
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
      if (prop == 'partyname') return item.partyName;
    }
    if (item is Expense) {
      if (prop == 'category') return item.category;
      if (prop == 'amount') return item.amount;
    }
    if (item is Transaction) {
      if (prop == 'transactionnumber') return item.transactionNumber;
      if (prop == 'transactiontype') return item.transactionType;
      if (prop == 'partyuuid') return item.partyUuid;
      if (prop == 'targetpartyuuid') return item.targetPartyUuid;
      if (prop == 'linkedbilluuid') return item.linkedBillUuid;
      if (prop == 'amount') return item.amount;
    }
    
    return null;
  }
}

class WebMockQuery<T> extends Query<T> {
  final List<dynamic> list;
  final WebMockCollection<T> collection;

  WebMockQuery(this.list, this.collection);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString().replaceAll('Symbol("', '').replaceAll('")', '');

    if (name == 'findFirst') {
      final entity = list.isEmpty ? null : list.first as T?;
      if (entity != null) {
        collection._attachEntity(entity);
      }
      return Future.value(entity);
    }
    
    if (name == 'findAll') {
      for (var entity in list) {
        collection._attachEntity(entity);
      }
      return Future.value(list.cast<T>());
    }

    if (name == 'count') {
      return Future.value(list.length);
    }

    if (name == 'deleteAll') {
      return Future.value(list.length);
    }

    return null;
  }
}
