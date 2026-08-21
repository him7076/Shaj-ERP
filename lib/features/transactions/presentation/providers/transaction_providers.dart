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

  const TransactionSearchFilter({
    this.query = '',
    this.transactionType = 'All',
    this.dateRange,
    this.partyUuid,
  });

  TransactionSearchFilter copyWith({
    String? query,
    String? transactionType,
    DateTimeRange? dateRange,
    String? partyUuid,
  }) {
    return TransactionSearchFilter(
      query: query ?? this.query,
      transactionType: transactionType ?? this.transactionType,
      dateRange: dateRange ?? this.dateRange,
      partyUuid: partyUuid ?? this.partyUuid,
    );
  }
}

final transactionSearchFilterProvider = StateProvider<TransactionSearchFilter>((ref) => const TransactionSearchFilter());

final filteredTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final filter = ref.watch(transactionSearchFilterProvider);
  final isar = ref.watch(isarProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  // 0. Build Party ID/UUID lookup map to avoid unattached IsarLink dereference crashes
  final Map<int, String> partyIdToUuidMap = {};
  try {
    final allParties = await isar.partys.where().findAll();
    for (var p in allParties) {
      if (p.uuid != null && p.uuid!.isNotEmpty) {
        partyIdToUuidMap[p.id] = p.uuid!;
      }
    }
  } catch (_) {}

  // 1. Fetch Transactions
  List<Transaction> rawTransactions = [];
  try {
    rawTransactions = await repo.searchTransactions('');
  } catch (_) {}

  // 2. Fetch Invoices (Sales)
  List<Transaction> invoiceTransactions = [];
  try {
    final rawInvoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
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
      if (inv.partyId != null) {
        pUuid = partyIdToUuidMap[inv.partyId!];
      }
      if (pUuid == null) {
        try { pUuid = inv.party.value?.uuid; } catch (_) {}
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
    final rawOrders = await isar.orders.filter().isDeletedEqualTo(false).findAll();
    orderTransactions = rawOrders.map((ord) {
      String? pUuid;
      if (ord.partyId != null) {
        pUuid = partyIdToUuidMap[ord.partyId!];
      }
      if (pUuid == null) {
        try { pUuid = ord.party.value?.uuid; } catch (_) {}
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
    final rawPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
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
      if (pur.partyId != null) {
        pUuid = partyIdToUuidMap[pur.partyId!];
      }
      if (pUuid == null) {
        try { pUuid = pur.party.value?.uuid; } catch (_) {}
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

  // Filter Date Range
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
