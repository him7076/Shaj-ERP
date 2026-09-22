import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/transaction_repository.dart';
import 'package:business_sahaj_erp/data/repositories/transaction_repository_impl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/orders/presentation/providers/order_providers.dart';
import 'package:business_sahaj_erp/core/services/gst_service.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';
import 'package:flutter/material.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TransactionRepositoryImpl(isar);
});

class TransactionSearchFilter {
  final String query;
  final String transactionType; // 'All', 'Receipt', 'Payment', 'Sales', 'Sales Order', 'Purchase', 'Credit Note', 'Debit Note', 'Expense', 'Transfer', 'Other Income'
  final DateTimeRange? dateRange;
  final String? partyUuid;
  final bool showAllHistory;
  final int limit;

  const TransactionSearchFilter({
    this.query = '',
    this.transactionType = 'All',
    this.dateRange,
    this.partyUuid,
    this.showAllHistory = true,
    this.limit = 50,
  });

  TransactionSearchFilter copyWith({
    String? query,
    String? transactionType,
    DateTimeRange? dateRange,
    String? partyUuid,
    bool? showAllHistory,
    int? limit,
  }) {
    return TransactionSearchFilter(
      query: query ?? this.query,
      transactionType: transactionType ?? this.transactionType,
      dateRange: dateRange ?? this.dateRange,
      partyUuid: partyUuid ?? this.partyUuid,
      showAllHistory: showAllHistory ?? this.showAllHistory,
      limit: limit ?? this.limit,
    );
  }
}

final transactionSearchFilterProvider = StateProvider<TransactionSearchFilter>((ref) => const TransactionSearchFilter());

final filteredTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final filter = ref.watch(transactionSearchFilterProvider);
  final isar = ref.watch(isarProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final isPersonal = ref.watch(vaultModeProvider) == VaultMode.personal;

  // 0. Resolve filter party ID to avoid filtering blindly
  int? targetPartyId;
  if (filter.partyUuid != null) {
    try {
      final p = await isar.partys.filter().uuidEqualTo(filter.partyUuid!).findFirst();
      if (p != null) targetPartyId = p.id;
    } catch (_) {}
  }

  // Date bounds for fetching: use provided filter or default to last 90 days if showAllHistory is false
  final now = DateTime.now();
  final queryStart = filter.showAllHistory 
      ? DateTime(2000, 1, 1) 
      : filter.dateRange?.start.subtract(const Duration(days: 1)) ?? now.subtract(const Duration(days: 90));
  final queryEnd = filter.showAllHistory 
      ? DateTime(2100, 1, 1) 
      : filter.dateRange?.end.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1));

  final cleanQuery = filter.query.trim().toLowerCase();
  final bool hasQuery = cleanQuery.isNotEmpty;
  
  // Helper to build queries with limit
  final int queryLimit = filter.limit;

  // 1. Fetch Transactions
  List<Transaction> rawTransactions = [];
  if (filter.transactionType == 'All' || 
      ['Receipt', 'Payment', 'Expense', 'Transfer', 'Other Income'].contains(filter.transactionType)) {
    try {
      var qb = isar.transactions.filter().isDeletedEqualTo(false);
      
      if (filter.transactionType != 'All') {
        qb = qb.transactionTypeEqualTo(filter.transactionType);
      }
      
      if (filter.partyUuid != null) {
        qb = qb.partyUuidEqualTo(filter.partyUuid);
      }
      
      qb = qb.and().group((q) => q
          .transactionDateBetween(queryStart, queryEnd)
          .or()
          .group((q2) => q2.transactionDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
          
      if (hasQuery) {
        qb = qb.and().group((q) => q
            .transactionNumberContains(cleanQuery, caseSensitive: false)
            .or()
            .partyNameContains(cleanQuery, caseSensitive: false)
            .or()
            .remarksContains(cleanQuery, caseSensitive: false)
            .or()
            .referenceNumberContains(cleanQuery, caseSensitive: false)
            .or()
            .linkedBillNumberContains(cleanQuery, caseSensitive: false));
      }
      
      var results = await qb.findAll();
      results = results.where((t) => t.isPersonalVault == isPersonal).toList();
      results.sort((a, b) => (b.transactionDate ?? b.createdAt).compareTo(a.transactionDate ?? a.createdAt));
      rawTransactions = results.take(queryLimit).toList();
    } catch (e, stack) {
      debugPrint('Error fetching rawTransactions: $e\n$stack');
    }
  }

  // 2. Fetch Invoices (Sales)
  List<Transaction> invoiceTransactions = [];
  if (!isPersonal && (filter.transactionType == 'All' || filter.transactionType == 'Sales')) {
    try {
      var qb = isar.invoices.filter().isDeletedEqualTo(false);
      
      if (targetPartyId != null) {
        qb = qb.partyIdEqualTo(targetPartyId);
      }
      
      qb = qb.and().group((q) => q
          .invoiceDateBetween(queryStart, queryEnd)
          .or()
          .group((q2) => q2.invoiceDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
          
      if (hasQuery) {
        qb = qb.and().group((q) => q
            .invoiceNumberContains(cleanQuery, caseSensitive: false)
            .or()
            .partyNameContains(cleanQuery, caseSensitive: false)
            .or()
            .remarksContains(cleanQuery, caseSensitive: false));
      }
      
      var results = await qb.findAll();
      results.sort((a, b) => (b.invoiceDate ?? b.createdAt ?? DateTime.now()).compareTo(a.invoiceDate ?? a.createdAt ?? DateTime.now()));
      final rawInvoices = results.take(queryLimit).toList();

      // Batch fetch parties
      final Set<int> allPartyIds = {};
      for (var i in rawInvoices) { if (i.partyId != null) allPartyIds.add(i.partyId!); }
      
      final Map<int, String> partyUuidMap = {};
      if (allPartyIds.isNotEmpty) {
        try {
          final parties = await isar.partys.getAll(allPartyIds.toList());
          for (var p in parties) {
            if (p != null && p.uuid != null) partyUuidMap[p.id] = p.uuid!;
          }
        } catch (_) {}
      }

      invoiceTransactions = rawInvoices.map((inv) {
        String pMode = 'Credit';
        if (inv.remarks != null && inv.remarks!.contains('[Paid via ')) {
          final match = RegExp(r'\[Paid via ([^\]]+)\]').firstMatch(inv.remarks!);
          if (match != null) pMode = match.group(1) ?? 'Cash';
        } else if ((inv.paidAmount ?? 0) >= (inv.grandTotal ?? 0) && (inv.grandTotal ?? 0) > 0) {
          pMode = 'Cash';
        }

        String pStatus = inv.paymentStatus ?? 'Unpaid';
        final paid = inv.paidAmount ?? 0.0;
        final grand = inv.grandTotal ?? 0.0;
        if (paid >= grand && grand > 0) {
          pStatus = 'Paid';
        } else if (paid > 0) {
          pStatus = 'Partially Paid';
        }

        String? pUuid;
        if (inv.partyId != null && inv.partyId == targetPartyId) {
          pUuid = filter.partyUuid;
        } else if (inv.partyId != null) {
          pUuid = partyUuidMap[inv.partyId!];
        }

        return Transaction()
          ..id = 100000000 + (inv.id ?? 0)
          ..uuid = inv.uuid
          ..transactionNumber = inv.invoiceNumber ?? 'INV-01'
          ..transactionType = 'Sales'
          ..transactionDate = inv.invoiceDate ?? inv.createdAt ?? DateTime.now()
          ..amount = inv.grandTotal ?? 0.0
          ..partyName = inv.partyName ?? 'Party'
          ..partyUuid = pUuid ?? (inv.partyId != null ? inv.partyId.toString() : null)
          ..paymentMode = pMode
          ..paymentStatus = pStatus
          ..remarks = inv.remarks
          ..createdAt = inv.createdAt ?? DateTime.now();
      }).toList();
    } catch (_) {}
  }

  // 3. Fetch Orders (Sales Orders)
  List<Transaction> orderTransactions = [];
  if (!isPersonal && (filter.transactionType == 'All' || filter.transactionType == 'Sales Order')) {
    try {
      var qb = isar.orders.filter().isDeletedEqualTo(false);
      
      if (targetPartyId != null) {
        qb = qb.partyIdEqualTo(targetPartyId);
      }
      
      qb = qb.and().group((q) => q
          .orderDateBetween(queryStart, queryEnd)
          .or()
          .group((q2) => q2.orderDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
          
      if (hasQuery) {
        qb = qb.and().group((q) => q
            .orderNumberContains(cleanQuery, caseSensitive: false)
            .or()
            .partyNameContains(cleanQuery, caseSensitive: false)
            .or()
            .remarksContains(cleanQuery, caseSensitive: false));
      }
      
      var results = await qb.findAll();
      results.sort((a, b) => (b.orderDate ?? b.createdAt ?? DateTime.now()).compareTo(a.orderDate ?? a.createdAt ?? DateTime.now()));
      final rawOrders = results.take(queryLimit).toList();

      final Set<int> orderPartyIds = {};
      for (var o in rawOrders) { if (o.partyId != null) orderPartyIds.add(o.partyId!); }
      
      final Map<int, String> orderPartyUuidMap = {};
      if (orderPartyIds.isNotEmpty) {
        try {
          final parties = await isar.partys.getAll(orderPartyIds.toList());
          for (var p in parties) {
            if (p != null && p.uuid != null) orderPartyUuidMap[p.id] = p.uuid!;
          }
        } catch (_) {}
      }

      orderTransactions = rawOrders.map((ord) {
        String? pUuid;
        if (ord.partyId != null && ord.partyId == targetPartyId) {
          pUuid = filter.partyUuid;
        } else if (ord.partyId != null) {
          pUuid = orderPartyUuidMap[ord.partyId!];
        }

        return Transaction()
          ..id = 200000000 + (ord.id ?? 0)
          ..uuid = ord.uuid
          ..transactionNumber = ord.orderNumber ?? 'SO-01'
          ..transactionType = 'Sales Order'
          ..transactionDate = ord.orderDate ?? ord.createdAt ?? DateTime.now()
          ..amount = ord.grandTotal ?? 0.0
          ..partyName = ord.partyName ?? 'Party'
          ..partyUuid = pUuid ?? (ord.partyId != null ? ord.partyId.toString() : null)
          ..paymentMode = 'Order'
          ..paymentStatus = ord.status ?? 'Pending'
          ..remarks = ord.remarks
          ..createdAt = ord.createdAt ?? DateTime.now();
      }).toList();
    } catch (e, stack) {
      debugPrint('Error fetching orderTransactions: $e\n$stack');
    }
  }

  // 4. Fetch Purchases (Purchase Bills)
  List<Transaction> purchaseTransactions = [];
  if (!isPersonal && (filter.transactionType == 'All' || filter.transactionType == 'Purchase')) {
    try {
      var qb = isar.purchases.filter().isDeletedEqualTo(false);
      
      if (targetPartyId != null) {
        qb = qb.partyIdEqualTo(targetPartyId);
      }
      
      qb = qb.and().group((q) => q
          .purchaseDateBetween(queryStart, queryEnd)
          .or()
          .group((q2) => q2.purchaseDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
          
      if (hasQuery) {
        qb = qb.and().group((q) => q
            .purchaseNumberContains(cleanQuery, caseSensitive: false)
            .or()
            .partyNameContains(cleanQuery, caseSensitive: false)
            .or()
            .remarksContains(cleanQuery, caseSensitive: false));
      }
      
      var results = await qb.findAll();
      results.sort((a, b) => (b.purchaseDate ?? b.createdAt ?? DateTime.now()).compareTo(a.purchaseDate ?? a.createdAt ?? DateTime.now()));
      final rawPurchases = results.take(queryLimit).toList();

      final Set<int> purPartyIds = {};
      for (var p in rawPurchases) { if (p.partyId != null) purPartyIds.add(p.partyId!); }
      
      final Map<int, String> purPartyUuidMap = {};
      if (purPartyIds.isNotEmpty) {
        try {
          final parties = await isar.partys.getAll(purPartyIds.toList());
          for (var p in parties) {
            if (p != null && p.uuid != null) purPartyUuidMap[p.id] = p.uuid!;
          }
        } catch (_) {}
      }

      purchaseTransactions = rawPurchases.map((pur) {
        String pStatus = pur.paymentStatus ?? 'Unpaid';
        final paid = pur.paidAmount ?? 0.0;
        final grand = pur.grandTotal ?? 0.0;
        if (paid >= grand && grand > 0) {
          pStatus = 'Paid';
        } else if (paid > 0) {
          pStatus = 'Partially Paid';
        }

        String? pUuid;
        if (pur.partyId != null && pur.partyId == targetPartyId) {
          pUuid = filter.partyUuid;
        } else if (pur.partyId != null) {
          pUuid = purPartyUuidMap[pur.partyId!];
        }

        return Transaction()
          ..id = 300000000 + (pur.id ?? 0)
          ..uuid = pur.uuid
          ..transactionNumber = pur.purchaseNumber ?? 'PUR-01'
          ..transactionType = 'Purchase'
          ..transactionDate = pur.purchaseDate ?? pur.createdAt ?? DateTime.now()
          ..amount = pur.grandTotal ?? 0.0
          ..partyName = pur.partyName ?? 'Supplier'
          ..partyUuid = pUuid ?? (pur.partyId != null ? pur.partyId.toString() : null)
          ..paymentMode = 'Bill'
          ..paymentStatus = pStatus
          ..remarks = pur.remarks
          ..createdAt = pur.createdAt ?? DateTime.now();
      }).toList();
    } catch (e, stack) {
      debugPrint('Error fetching purchaseTransactions: $e\n$stack');
    }
  }

  // Combine all lists
  List<Transaction> list = [
    ...rawTransactions,
    ...invoiceTransactions,
    ...orderTransactions,
    ...purchaseTransactions,
  ];

  // Sort by date descending
  list.sort((a, b) => (b.transactionDate ?? DateTime.now()).compareTo(a.transactionDate ?? DateTime.now()));

  // Take global limit (since we might have up to 4 * limit records)
  if (list.length > queryLimit) {
    list = list.sublist(0, queryLimit);
  }

  return list;
});

class TransactionTotals {
  final double totalIn;
  final double totalOut;
  final double totalAmount;
  const TransactionTotals({this.totalIn = 0.0, this.totalOut = 0.0, this.totalAmount = 0.0});
}

// Provider for accurate totals without loading full DB objects into RAM
final transactionTotalsProvider = FutureProvider<TransactionTotals>((ref) async {
  final filter = ref.watch(transactionSearchFilterProvider);
  final isar = ref.watch(isarProvider);
  final isPersonal = ref.watch(vaultModeProvider) == VaultMode.personal;
  
  int? targetPartyId;
  if (filter.partyUuid != null) {
    try {
      final p = await isar.partys.filter().uuidEqualTo(filter.partyUuid!).findFirst();
      if (p != null) targetPartyId = p.id;
    } catch (_) {}
  }

  final now = DateTime.now();
  final queryStart = filter.showAllHistory 
      ? DateTime(2000, 1, 1) 
      : filter.dateRange?.start.subtract(const Duration(days: 1)) ?? now.subtract(const Duration(days: 90));
  final queryEnd = filter.showAllHistory 
      ? DateTime(2100, 1, 1) 
      : filter.dateRange?.end.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1));

  final cleanQuery = filter.query.trim().toLowerCase();
  final bool hasQuery = cleanQuery.isNotEmpty;

  double sumList(List<double?> list) => list.whereType<double>().fold(0.0, (a, b) => a + b);

  double totalIn = 0.0;
  double totalOut = 0.0;
  double lockedTotal = 0.0;

  // 1. Transactions Collection
  if (filter.transactionType == 'All' || 
      ['Receipt', 'Payment', 'Expense', 'Transfer', 'Other Income'].contains(filter.transactionType)) {
    var qb = isar.transactions.filter().isDeletedEqualTo(false);
    
    if (filter.partyUuid != null) qb = qb.partyUuidEqualTo(filter.partyUuid);
    qb = qb.and().group((q) => q
        .transactionDateBetween(queryStart, queryEnd)
        .or()
        .group((q2) => q2.transactionDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
        
    if (hasQuery) {
      qb = qb.and().group((q) => q
          .transactionNumberContains(cleanQuery, caseSensitive: false)
          .or().partyNameContains(cleanQuery, caseSensitive: false)
          .or().remarksContains(cleanQuery, caseSensitive: false)
          .or().referenceNumberContains(cleanQuery, caseSensitive: false)
          .or().linkedBillNumberContains(cleanQuery, caseSensitive: false));
    }

    if (filter.transactionType != 'All') {
      final allMatching = await qb.transactionTypeEqualTo(filter.transactionType).findAll();
      final sum = sumList(allMatching.where((t) => t.isPersonalVault == isPersonal).map((t) => t.amount).toList());
      lockedTotal += sum;
      if (['Receipt', 'Other Income'].contains(filter.transactionType)) totalIn += sum;
      if (['Payment', 'Expense'].contains(filter.transactionType)) totalOut += sum;
    } else {
      // Must query separately to know type if we want IN/OUT without loading objects
      var qbIn = qb.and().group((q) => q.transactionTypeEqualTo('Receipt').or().transactionTypeEqualTo('Other Income'));
      var allIn = await qbIn.findAll();
      totalIn += sumList(allIn.where((t) => t.isPersonalVault == isPersonal).map((t) => t.amount).toList());
      
      var qbOut = qb.and().group((q) => q.transactionTypeEqualTo('Payment').or().transactionTypeEqualTo('Expense'));
      var allOut = await qbOut.findAll();
      totalOut += sumList(allOut.where((t) => t.isPersonalVault == isPersonal).map((t) => t.amount).toList());
    }
  }

  // 2. Invoices (Sales -> IN)
  if (!isPersonal && (filter.transactionType == 'All' || filter.transactionType == 'Sales')) {
    var qb = isar.invoices.filter().isDeletedEqualTo(false);
    if (targetPartyId != null) qb = qb.partyIdEqualTo(targetPartyId);
    qb = qb.and().group((q) => q
        .invoiceDateBetween(queryStart, queryEnd)
        .or()
        .group((q2) => q2.invoiceDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
        
    if (hasQuery) {
      qb = qb.and().group((q) => q
          .invoiceNumberContains(cleanQuery, caseSensitive: false)
          .or().partyNameContains(cleanQuery, caseSensitive: false)
          .or().remarksContains(cleanQuery, caseSensitive: false));
    }
    
    final sum = sumList(await qb.grandTotalProperty().findAll());
    totalIn += sum;
    if (filter.transactionType == 'Sales') lockedTotal += sum;
  }

  // 3. Purchases (Purchase Bills -> OUT)
  if (!isPersonal && (filter.transactionType == 'All' || filter.transactionType == 'Purchase')) {
    var qb = isar.purchases.filter().isDeletedEqualTo(false);
    if (targetPartyId != null) qb = qb.partyIdEqualTo(targetPartyId);
    qb = qb.and().group((q) => q
        .purchaseDateBetween(queryStart, queryEnd)
        .or()
        .group((q2) => q2.purchaseDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
        
    if (hasQuery) {
      qb = qb.and().group((q) => q
          .purchaseNumberContains(cleanQuery, caseSensitive: false)
          .or().partyNameContains(cleanQuery, caseSensitive: false)
          .or().remarksContains(cleanQuery, caseSensitive: false));
    }
    
    final sum = sumList(await qb.grandTotalProperty().findAll());
    totalOut += sum;
    if (filter.transactionType == 'Purchase') lockedTotal += sum;
  }
  
  // 4. Orders, Credit Note, Debit Note (for lockedTotal only)
  if (!isPersonal && ['Sales Order', 'Credit Note', 'Debit Note'].contains(filter.transactionType)) {
    if (filter.transactionType == 'Sales Order') {
      var qb = isar.orders.filter().isDeletedEqualTo(false);
      if (targetPartyId != null) qb = qb.partyIdEqualTo(targetPartyId);
      qb = qb.and().group((q) => q.orderDateBetween(queryStart, queryEnd).or().group((q2) => q2.orderDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
      if (hasQuery) {
        qb = qb.and().group((q) => q.orderNumberContains(cleanQuery, caseSensitive: false).or().partyNameContains(cleanQuery, caseSensitive: false).or().remarksContains(cleanQuery, caseSensitive: false));
      }
      lockedTotal += sumList(await qb.grandTotalProperty().findAll());
    } else {
      var qb = isar.transactions.filter().isDeletedEqualTo(false).transactionTypeEqualTo(filter.transactionType);
      if (filter.partyUuid != null) qb = qb.partyUuidEqualTo(filter.partyUuid);
      qb = qb.and().group((q) => q.transactionDateBetween(queryStart, queryEnd).or().group((q2) => q2.transactionDateIsNull().and().createdAtBetween(queryStart, queryEnd)));
      if (hasQuery) {
        qb = qb.and().group((q) => q.transactionNumberContains(cleanQuery, caseSensitive: false).or().partyNameContains(cleanQuery, caseSensitive: false).or().remarksContains(cleanQuery, caseSensitive: false).or().referenceNumberContains(cleanQuery, caseSensitive: false).or().linkedBillNumberContains(cleanQuery, caseSensitive: false));
      }
      lockedTotal += sumList(await qb.amountProperty().findAll());
    }
  }

  return TransactionTotals(totalIn: totalIn, totalOut: totalOut, totalAmount: lockedTotal);
});

// OPTIMIZED: Dashboard was using filteredTransactionsProvider which loads
// ALL parties + ALL transactions + ALL invoices + ALL orders + ALL purchases
// on every dashboard render. This provider only fetches the last 10 transactions.
final recentTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final isar = ref.watch(isarProvider);

  final isPersonal = ref.watch(vaultModeProvider) == VaultMode.personal;
  
  // Only fetch last 10 transactions sorted by date descending — instant response
  var recent = await isar.transactions.filter()
      .isDeletedEqualTo(false)
      .sortByTransactionDateDesc()
      .findAll();
      
  recent = recent.where((t) => t.isPersonalVault == isPersonal).take(10).toList();

  return recent;
});

class CreditNoteCart {
  final Party? selectedParty;
  final List<CartItemState> items;
  final bool isGstInclusive;
  final double discountPercent;
  final double discountAmount;
  final DateTime date;
  final String remarks;
  final double? customRoundOff;
  final String? originalInvoiceNumber;
  final String? originalInvoiceUuid;

  CreditNoteCart({
    this.selectedParty,
    this.items = const [],
    this.isGstInclusive = true,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.remarks = '',
    this.customRoundOff,
    this.originalInvoiceNumber,
    this.originalInvoiceUuid,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  CreditNoteCart copyWith({
    Party? selectedParty,
    List<CartItemState>? items,
    bool? isGstInclusive,
    double? discountPercent,
    double? discountAmount,
    DateTime? date,
    String? remarks,
    double? customRoundOff,
    String? originalInvoiceNumber,
    String? originalInvoiceUuid,
  }) {
    return CreditNoteCart(
      selectedParty: selectedParty ?? this.selectedParty,
      items: items ?? this.items,
      isGstInclusive: isGstInclusive ?? this.isGstInclusive,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      date: date ?? this.date,
      remarks: remarks ?? this.remarks,
      customRoundOff: customRoundOff ?? this.customRoundOff,
      originalInvoiceNumber: originalInvoiceNumber ?? this.originalInvoiceNumber,
      originalInvoiceUuid: originalInvoiceUuid ?? this.originalInvoiceUuid,
    );
  }
}

class CreditNoteCartNotifier extends StateNotifier<CreditNoteCart> {
  final GstService _gstService = GstService();

  CreditNoteCartNotifier() : super(CreditNoteCart());

  void setParty(Party? party) {
    state = state.copyWith(selectedParty: party);
  }

  void addItem(Item item, {double qty = 1.0}) {
    final rate = item.sellRate ?? 0.0;
    final gst = item.gstRate ?? 18.0;
    final defaultUnit = item.primaryUnitName ?? item.unit.value?.shortName ?? item.unit.value?.unitName ?? 'PCS';

    final newItem = CartItemState(
      item: item,
      quantity: qty,
      unit: defaultUnit,
      rate: rate,
      gstPercent: gst,
    );

    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateItemAt(
    int index, {
    double? quantity,
    double? freeQuantity,
    String? unit,
    double? rate,
    double? discountPercent,
    double? discountAmount,
    String? batchNumber,
    String? expiryDate,
    String? mfgDate,
  }) {
    if (index < 0 || index >= state.items.length) return;

    final current = state.items[index];

    double finalDiscPercent = discountPercent ?? current.discountPercent;
    double finalDiscAmount = discountAmount ?? current.discountAmount;

    if (discountPercent != null) {
      final targetRate = rate ?? current.rate;
      final targetQty = quantity ?? current.quantity;
      finalDiscAmount = (targetRate * targetQty) * (discountPercent / 100.0);
    } else if (discountAmount != null) {
      final targetRate = rate ?? current.rate;
      final targetQty = quantity ?? current.quantity;
      final totalBase = targetRate * targetQty;
      finalDiscPercent = totalBase > 0 ? (discountAmount / totalBase) * 100.0 : 0.0;
    }

    final updated = current.copyWith(
      quantity: quantity,
      freeQuantity: freeQuantity,
      unit: unit,
      rate: rate,
      discountPercent: finalDiscPercent,
      discountAmount: finalDiscAmount,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      mfgDate: mfgDate,
    );

    final updatedList = List<CartItemState>.from(state.items);
    updatedList[index] = updated;
    state = state.copyWith(items: updatedList);
  }
  
  void updateItem(
    String itemUuid, {
    double? quantity,
    double? freeQuantity,
    String? unit,
    double? rate,
    double? discountPercent,
    double? discountAmount,
  }) {
    final index = state.items.indexWhere((element) => element.item.uuid == itemUuid);
    if (index == -1) return;
    updateItemAt(
      index,
      quantity: quantity,
      freeQuantity: freeQuantity,
      unit: unit,
      rate: rate,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
    );
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updatedList = List<CartItemState>.from(state.items);
    updatedList.removeAt(index);
    state = state.copyWith(items: updatedList);
  }

  void toggleGstInclusive(bool val) {
    state = state.copyWith(isGstInclusive: val);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setRemarks(String remarks) {
    state = state.copyWith(remarks: remarks);
  }

  void setCustomRoundOff(double? val) {
    state = CreditNoteCart(
      selectedParty: state.selectedParty,
      items: state.items,
      isGstInclusive: state.isGstInclusive,
      discountPercent: state.discountPercent,
      discountAmount: state.discountAmount,
      date: state.date,
      remarks: state.remarks,
      customRoundOff: val,
      originalInvoiceNumber: state.originalInvoiceNumber,
      originalInvoiceUuid: state.originalInvoiceUuid,
    );
  }

  void setDiscounts(double? percent, double? amount) {
    state = state.copyWith(
      discountPercent: percent ?? state.discountPercent,
      discountAmount: amount ?? state.discountAmount,
    );
  }

  void setOriginalInvoice(String? number, String? uuid) {
    state = state.copyWith(
      originalInvoiceNumber: number,
      originalInvoiceUuid: uuid,
    );
  }
  
  void loadCreditNote({
    required Party party,
    required Transaction creditNote,
    required List<CartItemState> items,
    bool isGstInclusive = false,
  }) {
    state = CreditNoteCart(
      selectedParty: party,
      items: items,
      isGstInclusive: isGstInclusive,
      discountPercent: 0.0,
      discountAmount: 0.0,
      date: creditNote.transactionDate ?? DateTime.now(),
      remarks: creditNote.remarks ?? '',
      customRoundOff: null,
      originalInvoiceNumber: creditNote.referenceNumber,
      originalInvoiceUuid: creditNote.linkedBillUuid,
    );
  }

  void clear() {
    state = CreditNoteCart();
  }

  Map<String, double> calculateTotals(String? companyGst) {
    double subtotal = 0.0;
    double totalGst = 0.0;
    double totalDiscount = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    final partyGst = state.selectedParty?.gstNumber;
    final partyState = state.selectedParty?.state;

    for (var cartItem in state.items) {
      final res = _gstService.calculateTax(
        rate: cartItem.rate,
        quantity: cartItem.quantity,
        gstRatePercent: cartItem.gstPercent,
        isInclusive: state.isGstInclusive,
        itemDiscountAmount: cartItem.discountAmount,
        companyGst: companyGst,
        partyGst: partyGst,
        partyState: partyState,
      );

      subtotal += res.taxableAmount;
      totalGst += res.gstAmount;
      totalDiscount += cartItem.discountAmount;
      cgst += res.cgst;
      sgst += res.sgst;
      igst += res.igst;
    }

    // Apply Order Level Discount
    double orderDiscountVal = state.discountAmount;
    if (state.discountPercent > 0) {
      orderDiscountVal = (subtotal + totalGst) * (state.discountPercent / 100.0);
    }
    totalDiscount += orderDiscountVal;

    final double rawGrandTotal = (subtotal + totalGst) - orderDiscountVal;
    final double roundOff = state.customRoundOff ?? (rawGrandTotal.roundToDouble() - rawGrandTotal);
    final double roundedGrandTotal = rawGrandTotal + roundOff;

    return {
      'subtotal': subtotal,
      'discountAmount': totalDiscount,
      'totalGST': totalGst,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'roundOff': roundOff,
      'grandTotal': roundedGrandTotal < 0 ? 0.0 : roundedGrandTotal,
    };
  }
}

final creditNoteCartProvider = StateNotifierProvider<CreditNoteCartNotifier, CreditNoteCart>((ref) {
  return CreditNoteCartNotifier();
});

