import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';

class WebMockIsar implements Isar {
  final String firmId;
  final SharedPreferences? prefs;
  static final Map<String, Map<String, List<dynamic>>> _dbs = {};

  WebMockIsar({this.firmId = 'firm_default', this.prefs}) {
    if (prefs != null) {
      loadFromPrefs(prefs!);
    }
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
    if (T == User) return 'users';
    if (T == SyncQueue) return 'syncQueues';
    if (T == Purchase) return 'purchases';
    if (T == PurchaseItem) return 'purchaseItems';
    if (T == Expense) return 'expenses';
    if (T == Transaction) return 'transactions';
    if (T == BankAccount) return 'bankAccounts';
    if (T == CreditNote) return 'creditNotes';
    if (T == CreditNoteItem) return 'creditNoteItems';
    if (T == DebitNote) return 'debitNotes';
    if (T == DebitNoteItem) return 'debitNoteItems';
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
    if (name == 'bankAccounts') return WebMockCollection<BankAccount>('bankAccounts', _db, this);
    if (name == 'creditNotes') return WebMockCollection<CreditNote>('creditNotes', _db, this);
    if (name == 'creditNoteItems') return WebMockCollection<CreditNoteItem>('creditNoteItems', _db, this);
    if (name == 'debitNotes') return WebMockCollection<DebitNote>('debitNotes', _db, this);
    if (name == 'debitNoteItems') return WebMockCollection<DebitNoteItem>('debitNoteItems', _db, this);
    return WebMockCollection<dynamic>(name, _db, this);
  }

  Future<void> saveToPrefs(SharedPreferences prefsInstance) async {
    try {
      final data = <String, List<Map<String, dynamic>>>{};
      _db.forEach((collectionName, list) {
        data[collectionName] = list.map((item) => _entityToMap(item)).toList();
      });
      final jsonStr = jsonEncode(data);
      await prefsInstance.setString('web_mock_db_$firmId', jsonStr);
    } catch (e) {
      print('Error saving web mock DB to SharedPreferences: $e');
    }
  }

  void loadFromPrefs(SharedPreferences prefsInstance) {
    try {
      final jsonStr = prefsInstance.getString('web_mock_db_$firmId');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        data.forEach((collectionName, listData) {
          final list = listData as List<dynamic>;
          _db[collectionName] = list.map((itemMap) => _mapToEntity(itemMap as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      print('Error loading web mock DB from SharedPreferences: $e');
    }
  }

  Map<String, dynamic> _entityToMap(dynamic entity) {
    if (entity is Category) {
      return {
        'type': 'Category',
        'id': entity.id,
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
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
        'conversionFactor': entity.conversionFactor,
        'barcode': entity.barcode,
        'sku': entity.sku,
        'skuCode': entity.skuCode,
        'imagePaths': entity.imagePaths,
        'firebaseImageUrls': entity.firebaseImageUrls,
        'thumbnailImage': entity.thumbnailImage,
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
        'uuid': entity.uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'parentInvoiceId': entity.parentInvoiceId,
        'quantity': entity.quantity,
        'freeQuantity': entity.freeQuantity,
        'rate': entity.rate,
        'discount': entity.discount,
        'taxableAmount': entity.taxableAmount,
        'gstRate': entity.gstRate,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
        'purchaseNumber': entity.purchaseNumber,
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
        'uuid': entity.uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'quantity': entity.quantity,
        'rate': entity.rate,
        'discount': entity.discount,
        'taxableAmount': entity.taxableAmount,
        'gstRate': entity.gstRate,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
        'transactionNumber': entity.transactionNumber,
        'transactionDate': entity.transactionDate?.toIso8601String(),
        'partyUuid': entity.partyUuid,
        'partyName': entity.partyName,
        'transactionType': entity.transactionType,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'parentCreditNoteId': entity.parentCreditNoteId,
        'quantity': entity.quantity,
        'freeQuantity': entity.freeQuantity,
        'rate': entity.rate,
        'discount': entity.discount,
        'taxableAmount': entity.taxableAmount,
        'gstRate': entity.gstRate,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
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
        'uuid': entity.uuid,
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
        'uuid': entity.uuid,
        'itemId': entity.itemId,
        'itemName': entity.itemName,
        'hsnCode': entity.hsnCode,
        'parentDebitNoteId': entity.parentDebitNoteId,
        'quantity': entity.quantity,
        'freeQuantity': entity.freeQuantity,
        'rate': entity.rate,
        'discount': entity.discount,
        'taxableAmount': entity.taxableAmount,
        'gstRate': entity.gstRate,
        'gstAmount': entity.gstAmount,
        'totalAmount': entity.totalAmount,
        'createdAt': entity.createdAt.toIso8601String(),
        'updatedAt': entity.updatedAt.toIso8601String(),
        'isDeleted': entity.isDeleted,
        'isSynced': entity.isSynced,
        'version': entity.version,
      };
    }
    return {};
  }

  dynamic _mapToEntity(Map<String, dynamic> map) {
    final type = map['type'] as String;
    switch (type) {
      case 'Category':
        return Category()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..categoryName = map['categoryName'] as String?
          ..description = map['description'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Unit':
        return Unit()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..unitName = map['unitName'] as String?
          ..shortName = map['shortName'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Brand':
        return Brand()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..brandName = map['brandName'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Party':
        return Party()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..partyCode = map['partyCode'] as String?
          ..partyName = map['partyName'] as String?
          ..partyType = map['partyType'] as String?
          ..mobileNumber = map['mobileNumber'] as String?
          ..whatsappNumber = map['whatsappNumber'] as String?
          ..email = map['email'] as String?
          ..gstNumber = map['gstNumber'] as String?
          ..panNumber = map['panNumber'] as String?
          ..gstType = map['gstType'] as String?
          ..addressLine1 = map['addressLine1'] as String?
          ..addressLine2 = map['addressLine2'] as String?
          ..city = map['city'] as String?
          ..state = map['state'] as String?
          ..pincode = map['pincode'] as String?
          ..latitude = map['latitude'] as double?
          ..longitude = map['longitude'] as double?
          ..locationAddress = map['locationAddress'] as String?
          ..googleMapUrl = map['googleMapUrl'] as String?
          ..openingBalance = map['openingBalance'] as double?
          ..balanceType = map['balanceType'] as String?
          ..creditLimit = map['creditLimit'] as double?
          ..outstandingBalance = map['outstandingBalance'] as double?
          ..paymentTerms = map['paymentTerms'] as String?
          ..dueDays = map['dueDays'] as int?
          ..contactPerson = map['contactPerson'] as String?
          ..businessCategory = map['businessCategory'] as String?
          ..notes = map['notes'] as String?
          ..shopPhotos = (map['shopPhotos'] as List<dynamic>?)?.cast<String>()
          ..shopPhotoUrls = (map['shopPhotoUrls'] as List<dynamic>?)?.cast<String>()
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Item':
        return Item()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..itemCode = map['itemCode'] as String?
          ..itemName = map['itemName'] as String?
          ..shortName = map['shortName'] as String?
          ..description = map['description'] as String?
          ..hsnCode = map['hsnCode'] as String?
          ..gstApplicable = map['gstApplicable'] as bool
          ..gstRate = map['gstRate'] as double?
          ..cessRate = map['cessRate'] as double?
          ..buyRate = map['buyRate'] as double?
          ..mrp = map['mrp'] as double?
          ..sellRate = map['sellRate'] as double?
          ..wholesaleRate = map['wholesaleRate'] as double?
          ..minimumSellingPrice = map['minimumSellingPrice'] as double?
          ..openingStock = map['openingStock'] as double?
          ..currentStock = map['currentStock'] as double?
          ..reorderLevel = map['reorderLevel'] as double?
          ..minimumStock = map['minimumStock'] as double?
          ..secondaryUnit = map['secondaryUnit'] as String?
          ..conversionFactor = map['conversionFactor'] as double?
          ..barcode = map['barcode'] as String?
          ..sku = map['sku'] as String?
          ..skuCode = map['skuCode'] as String?
          ..imagePaths = (map['imagePaths'] as List<dynamic>?)?.cast<String>()
          ..firebaseImageUrls = (map['firebaseImageUrls'] as List<dynamic>?)?.cast<String>()
          ..thumbnailImage = map['thumbnailImage'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'OrderItem':
        return OrderItem()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..itemId = map['itemId'] as int?
          ..itemName = map['itemName'] as String?
          ..hsnCode = map['hsnCode'] as String?
          ..quantity = map['quantity'] as double?
          ..freeQuantity = map['freeQuantity'] as double?
          ..unit = map['unit'] as String?
          ..rate = map['rate'] as double?
          ..discountPercent = map['discountPercent'] as double?
          ..discountAmount = map['discountAmount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..gstPercent = map['gstPercent'] as double?
          ..gstAmount = map['gstAmount'] as double?
          ..totalAmount = map['totalAmount'] as double?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Order':
        return Order()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..orderNumber = map['orderNumber'] as String?
          ..orderDate = map['orderDate'] != null ? DateTime.parse(map['orderDate'] as String) : null
          ..status = map['status'] as String?
          ..partyId = map['partyId'] as int?
          ..partyName = map['partyName'] as String?
          ..mobileNumber = map['mobileNumber'] as String?
          ..gstNumber = map['gstNumber'] as String?
          ..latitude = map['latitude'] as double?
          ..longitude = map['longitude'] as double?
          ..locationAddress = map['locationAddress'] as String?
          ..subtotal = map['subtotal'] as double?
          ..discountAmount = map['discountAmount'] as double?
          ..discountPercent = map['discountPercent'] as double?
          ..totalGST = map['totalGST'] as double?
          ..roundOff = map['roundOff'] as double?
          ..grandTotal = map['grandTotal'] as double?
          ..remarks = map['remarks'] as String?
          ..internalNotes = map['internalNotes'] as String?
          ..cancelledBy = map['cancelledBy'] as String?
          ..cancelledDate = map['cancelledDate'] != null ? DateTime.parse(map['cancelledDate'] as String) : null
          ..cancellationReason = map['cancellationReason'] as String?
          ..createdBy = map['createdBy'] as String?
          ..editedBy = map['editedBy'] as String?
          ..editTime = map['editTime'] != null ? DateTime.parse(map['editTime'] as String) : null
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'InvoiceItem':
        return InvoiceItem()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..itemId = map['itemId'] as int?
          ..itemName = map['itemName'] as String?
          ..hsnCode = map['hsnCode'] as String?
          ..parentInvoiceId = map['parentInvoiceId'] as int?
          ..quantity = map['quantity'] as double?
          ..freeQuantity = map['freeQuantity'] as double?
          ..rate = map['rate'] as double?
          ..discount = map['discount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..gstRate = map['gstRate'] as double?
          ..gstAmount = map['gstAmount'] as double?
          ..totalAmount = map['totalAmount'] as double?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Invoice':
        return Invoice()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..invoiceNumber = map['invoiceNumber'] as String?
          ..invoiceDate = map['invoiceDate'] != null ? DateTime.parse(map['invoiceDate'] as String) : null
          ..invoiceType = map['invoiceType'] as String?
          ..invoiceStatus = map['invoiceStatus'] as String?
          ..sourceOrderId = map['sourceOrderId'] as int?
          ..sourceOrderNumber = map['sourceOrderNumber'] as String?
          ..partyId = map['partyId'] as int?
          ..partyName = map['partyName'] as String?
          ..gstNumber = map['gstNumber'] as String?
          ..address = map['address'] as String?
          ..subtotal = map['subtotal'] as double?
          ..discountAmount = map['discountAmount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..cgstAmount = map['cgstAmount'] as double?
          ..sgstAmount = map['sgstAmount'] as double?
          ..igstAmount = map['igstAmount'] as double?
          ..totalGST = map['totalGST'] as double?
          ..roundOff = map['roundOff'] as double?
          ..grandTotal = map['grandTotal'] as double?
          ..paymentStatus = map['paymentStatus'] as String?
          ..paidAmount = map['paidAmount'] as double?
          ..pendingAmount = map['pendingAmount'] as double?
          ..dueDate = map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null
          ..remarks = map['remarks'] as String?
          ..termsAndConditions = map['termsAndConditions'] as String?
          ..cancelledBy = map['cancelledBy'] as String?
          ..cancelledDate = map['cancelledDate'] != null ? DateTime.parse(map['cancelledDate'] as String) : null
          ..cancellationReason = map['cancellationReason'] as String?
          ..createdBy = map['createdBy'] as String?
          ..editedBy = map['editedBy'] as String?
          ..editTime = map['editTime'] != null ? DateTime.parse(map['editTime'] as String) : null
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Settings':
        return Settings()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..companyName = map['companyName'] as String?
          ..companyGST = map['companyGST'] as String?
          ..companyAddress = map['companyAddress'] as String?
          ..companyPhone = map['companyPhone'] as String?
          ..companyEmail = map['companyEmail'] as String?
          ..logoPath = map['logoPath'] as String?
          ..themeMode = map['themeMode'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'User':
        return User()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..name = map['name'] as String?
          ..email = map['email'] as String?
          ..role = map['role'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'SyncQueue':
        return SyncQueue()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..entityType = map['entityType'] as String?
          ..entityId = map['entityId'] as int?
          ..entityUuid = map['entityUuid'] as String?
          ..operation = map['operation'] as String?
          ..retryCount = map['retryCount'] as int
          ..lastAttempt = map['lastAttempt'] != null ? DateTime.parse(map['lastAttempt'] as String) : null
          ..lastError = map['lastError'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Purchase':
        return Purchase()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..purchaseNumber = map['purchaseNumber'] as String?
          ..purchaseDate = map['purchaseDate'] != null ? DateTime.parse(map['purchaseDate'] as String) : null
          ..partyId = map['partyId'] as int?
          ..partyName = map['partyName'] as String?
          ..gstNumber = map['gstNumber'] as String?
          ..address = map['address'] as String?
          ..subtotal = map['subtotal'] as double?
          ..discountAmount = map['discountAmount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..cgstAmount = map['cgstAmount'] as double?
          ..sgstAmount = map['sgstAmount'] as double?
          ..igstAmount = map['igstAmount'] as double?
          ..totalGST = map['totalGST'] as double?
          ..roundOff = map['roundOff'] as double?
          ..grandTotal = map['grandTotal'] as double?
          ..paymentStatus = map['paymentStatus'] as String?
          ..paidAmount = map['paidAmount'] as double?
          ..pendingAmount = map['pendingAmount'] as double?
          ..remarks = map['remarks'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'PurchaseItem':
        return PurchaseItem()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..itemId = map['itemId'] as int?
          ..itemName = map['itemName'] as String?
          ..hsnCode = map['hsnCode'] as String?
          ..quantity = map['quantity'] as double?
          ..rate = map['rate'] as double?
          ..discount = map['discount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..gstRate = map['gstRate'] as double?
          ..gstAmount = map['gstAmount'] as double?
          ..totalAmount = map['totalAmount'] as double?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Expense':
        return Expense()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..category = map['category'] as String?
          ..amount = map['amount'] as double?
          ..expenseDate = map['expenseDate'] != null ? DateTime.parse(map['expenseDate'] as String) : null
          ..paymentMode = map['paymentMode'] as String?
          ..remarks = map['remarks'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'Transaction':
        return Transaction()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..transactionNumber = map['transactionNumber'] as String?
          ..transactionDate = map['transactionDate'] != null ? DateTime.parse(map['transactionDate'] as String) : null
          ..partyUuid = map['partyUuid'] as String?
          ..partyName = map['partyName'] as String?
          ..transactionType = map['transactionType'] as String?
          ..amount = map['amount'] as double?
          ..paymentMode = map['paymentMode'] as String?
          ..referenceNumber = map['referenceNumber'] as String?
          ..remarks = map['remarks'] as String?
          ..linkedBillUuid = map['linkedBillUuid'] as String?
          ..linkedBillNumber = map['linkedBillNumber'] as String?
          ..targetPartyUuid = map['targetPartyUuid'] as String?
          ..targetPartyName = map['targetPartyName'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'BankAccount':
        return BankAccount()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..accountName = map['accountName'] as String?
          ..bankName = map['bankName'] as String?
          ..accountNumber = map['accountNumber'] as String?
          ..ifscCode = map['ifscCode'] as String?
          ..branchName = map['branchName'] as String?
          ..openingBalance = map['openingBalance'] as double?
          ..currentBalance = map['currentBalance'] as double?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'CreditNote':
        return CreditNote()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..creditNoteNumber = map['creditNoteNumber'] as String?
          ..creditNoteDate = map['creditNoteDate'] != null ? DateTime.parse(map['creditNoteDate'] as String) : null
          ..originalInvoiceNumber = map['originalInvoiceNumber'] as String?
          ..originalInvoiceUuid = map['originalInvoiceUuid'] as String?
          ..partyId = map['partyId'] as int?
          ..partyName = map['partyName'] as String?
          ..gstNumber = map['gstNumber'] as String?
          ..address = map['address'] as String?
          ..subtotal = map['subtotal'] as double?
          ..discountAmount = map['discountAmount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..cgstAmount = map['cgstAmount'] as double?
          ..sgstAmount = map['sgstAmount'] as double?
          ..igstAmount = map['igstAmount'] as double?
          ..totalGST = map['totalGST'] as double?
          ..roundOff = map['roundOff'] as double?
          ..grandTotal = map['grandTotal'] as double?
          ..remarks = map['remarks'] as String?
          ..createdBy = map['createdBy'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'CreditNoteItem':
        return CreditNoteItem()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..itemId = map['itemId'] as int?
          ..itemName = map['itemName'] as String?
          ..hsnCode = map['hsnCode'] as String?
          ..parentCreditNoteId = map['parentCreditNoteId'] as int?
          ..quantity = map['quantity'] as double?
          ..freeQuantity = map['freeQuantity'] as double?
          ..rate = map['rate'] as double?
          ..discount = map['discount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..gstRate = map['gstRate'] as double?
          ..gstAmount = map['gstAmount'] as double?
          ..totalAmount = map['totalAmount'] as double?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'DebitNote':
        return DebitNote()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..debitNoteNumber = map['debitNoteNumber'] as String?
          ..debitNoteDate = map['debitNoteDate'] != null ? DateTime.parse(map['debitNoteDate'] as String) : null
          ..originalPurchaseNumber = map['originalPurchaseNumber'] as String?
          ..originalPurchaseUuid = map['originalPurchaseUuid'] as String?
          ..partyId = map['partyId'] as int?
          ..partyName = map['partyName'] as String?
          ..gstNumber = map['gstNumber'] as String?
          ..address = map['address'] as String?
          ..subtotal = map['subtotal'] as double?
          ..discountAmount = map['discountAmount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..cgstAmount = map['cgstAmount'] as double?
          ..sgstAmount = map['sgstAmount'] as double?
          ..igstAmount = map['igstAmount'] as double?
          ..totalGST = map['totalGST'] as double?
          ..roundOff = map['roundOff'] as double?
          ..grandTotal = map['grandTotal'] as double?
          ..remarks = map['remarks'] as String?
          ..createdBy = map['createdBy'] as String?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
      case 'DebitNoteItem':
        return DebitNoteItem()
          ..id = map['id'] as int
          ..uuid = map['uuid'] as String?
          ..itemId = map['itemId'] as int?
          ..itemName = map['itemName'] as String?
          ..hsnCode = map['hsnCode'] as String?
          ..parentDebitNoteId = map['parentDebitNoteId'] as int?
          ..quantity = map['quantity'] as double?
          ..freeQuantity = map['freeQuantity'] as double?
          ..rate = map['rate'] as double?
          ..discount = map['discount'] as double?
          ..taxableAmount = map['taxableAmount'] as double?
          ..gstRate = map['gstRate'] as double?
          ..gstAmount = map['gstAmount'] as double?
          ..totalAmount = map['totalAmount'] as double?
          ..createdAt = DateTime.parse(map['createdAt'] as String)
          ..updatedAt = DateTime.parse(map['updatedAt'] as String)
          ..isDeleted = map['isDeleted'] as bool
          ..isSynced = map['isSynced'] as bool
          ..version = map['version'] as int;
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
    if (type == Transaction) return WebMockQuery<Transaction>(list, isarInstance.collection<Transaction>() as WebMockCollection<Transaction>);
    return WebMockQuery<T>(list, this);
  }

  @override
  Future<Id> put(T object) async {
    final entity = object as dynamic;
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

    if (isarInstance.prefs != null) {
      await isarInstance.saveToPrefs(isarInstance.prefs!);
    }
    return entity.id as int;
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
    final entity = _list.firstWhere((e) => e.id == id, orElse: () => null);
    if (entity != null) {
      _attachEntity(entity);
    }
    return entity as T?;
  }

  @override
  Future<List<T?>> getAll(List<Id> ids) async {
    final result = ids.map((id) => _list.firstWhere((e) => e.id == id, orElse: () => null)).toList();
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
    if (deleted && isarInstance.prefs != null) {
      await isarInstance.saveToPrefs(isarInstance.prefs!);
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
    if (isarInstance.prefs != null) {
      await isarInstance.saveToPrefs(isarInstance.prefs!);
    }
  }

  @override
  Future<int> count() async {
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
    
    if (offset != null && offset > 0 && offset < list.length) {
      list = list.sublist(offset);
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
