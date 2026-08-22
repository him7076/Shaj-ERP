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

  const TransactionSearchFilter({
    this.query = '',
    this.transactionType = 'All',
    this.dateRange,
    this.partyUuid,
    this.showAllHistory = false,
  });

  TransactionSearchFilter copyWith({
    String? query,
    String? transactionType,
    DateTimeRange? dateRange,
    String? partyUuid,
    bool? showAllHistory,
  }) {
    return TransactionSearchFilter(
      query: query ?? this.query,
      transactionType: transactionType ?? this.transactionType,
      dateRange: dateRange ?? this.dateRange,
      partyUuid: partyUuid ?? this.partyUuid,
      showAllHistory: showAllHistory ?? this.showAllHistory,
    );
  }
}

final transactionSearchFilterProvider = StateProvider<TransactionSearchFilter>((ref) => const TransactionSearchFilter());

final filteredTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final filter = ref.watch(transactionSearchFilterProvider);
  final isar = ref.watch(isarProvider);
  final repo = ref.watch(transactionRepositoryProvider);

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

  // 1. Fetch Transactions
  List<Transaction> rawTransactions = [];
  try {
    rawTransactions = await isar.transactions.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .transactionDateBetween(queryStart, queryEnd)
            .or()
            .group((q2) => q2.transactionDateIsNull().and().createdAtBetween(queryStart, queryEnd)))
        .findAll();
  } catch (_) {}

  // 2. Fetch Invoices (Sales)
  List<Transaction> invoiceTransactions = [];
  try {
    final rawInvoices = await isar.invoices.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .invoiceDateBetween(queryStart, queryEnd)
            .or()
            .group((q2) => q2.invoiceDateIsNull().and().createdAtBetween(queryStart, queryEnd)))
        .findAll();
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
        // Fallback for when not filtering by party but we need the UUID
        try {
          pUuid = isar.partys.getSync(inv.partyId!)?.uuid;
        } catch (_) {}
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

  // 3. Fetch Orders (Sales Orders)
  List<Transaction> orderTransactions = [];
  try {
    final rawOrders = await isar.orders.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .orderDateBetween(queryStart, queryEnd)
            .or()
            .group((q2) => q2.orderDateIsNull().and().createdAtBetween(queryStart, queryEnd)))
        .findAll();
    orderTransactions = rawOrders.map((ord) {
      String? pUuid;
      if (ord.partyId != null && ord.partyId == targetPartyId) {
        pUuid = filter.partyUuid;
      } else if (ord.partyId != null) {
        try {
          pUuid = isar.partys.getSync(ord.partyId!)?.uuid;
        } catch (_) {}
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
  } catch (_) {}

  // 4. Fetch Purchases (Purchase Bills)
  List<Transaction> purchaseTransactions = [];
  try {
    final rawPurchases = await isar.purchases.filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .purchaseDateBetween(queryStart, queryEnd)
            .or()
            .group((q2) => q2.purchaseDateIsNull().and().createdAtBetween(queryStart, queryEnd)))
        .findAll();
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
        try {
          pUuid = isar.partys.getSync(pur.partyId!)?.uuid;
        } catch (_) {}
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
  } catch (_) {}

  // Combine all 4 lists
  List<Transaction> list = [
    ...rawTransactions,
    ...invoiceTransactions,
    ...orderTransactions,
    ...purchaseTransactions,
  ];

  // Search Filter
  if (filter.query.trim().isNotEmpty) {
    final q = filter.query.trim().toLowerCase();
    list = list.where((t) {
      final tNo = t.transactionNumber?.toLowerCase() ?? '';
      final pName = t.partyName?.toLowerCase() ?? '';
      final tType = t.transactionType?.toLowerCase() ?? '';
      final rem = t.remarks?.toLowerCase() ?? '';
      final pMode = t.paymentMode?.toLowerCase() ?? '';
      final refNo = t.referenceNumber?.toLowerCase() ?? '';
      final billNo = t.linkedBillNumber?.toLowerCase() ?? '';
      final targetPName = t.targetPartyName?.toLowerCase() ?? '';
      return tNo.contains(q) ||
          pName.contains(q) ||
          tType.contains(q) ||
          rem.contains(q) ||
          pMode.contains(q) ||
          refNo.contains(q) ||
          billNo.contains(q) ||
          targetPName.contains(q);
    }).toList();
  }

  // Filter Transaction Type
  if (filter.transactionType != 'All') {
    list = list.where((t) => t.transactionType == filter.transactionType).toList();
  }

  // Filter Party
  if (filter.partyUuid != null) {
    list = list.where((t) => t.partyUuid == filter.partyUuid).toList();
  }

  // Filter Date Range (redundant if default dates handled above, but useful for strict boundaries)
  if (filter.dateRange != null) {
    list = list.where((t) {
      if (t.transactionDate == null) return false;
      return t.transactionDate!.isAfter(filter.dateRange!.start.subtract(const Duration(days: 1))) &&
          t.transactionDate!.isBefore(filter.dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  // Sort by date descending
  list.sort((a, b) => (b.transactionDate ?? DateTime.now()).compareTo(a.transactionDate ?? DateTime.now()));

  return list;
});

// Lightweight provider for Dashboard "Recent Transactions" widget ONLY.
// OPTIMIZED: Dashboard was using filteredTransactionsProvider which loads
// ALL parties + ALL transactions + ALL invoices + ALL orders + ALL purchases
// on every dashboard render. This provider only fetches the last 10 transactions.
final recentTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final isar = ref.watch(isarProvider);

  // Only fetch last 10 transactions sorted by date descending — instant response
  final recent = await isar.transactions.filter()
      .isDeletedEqualTo(false)
      .sortByTransactionDateDesc()
      .limit(10)
      .findAll();

  return recent;
});
