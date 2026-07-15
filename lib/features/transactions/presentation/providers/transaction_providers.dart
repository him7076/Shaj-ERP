import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/transaction_repository.dart';
import 'package:business_sahaj_erp/data/repositories/transaction_repository_impl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:flutter/material.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TransactionRepositoryImpl(dbService.isar);
});

class TransactionSearchFilter {
  final String query;
  final String transactionType; // 'All', 'Receipt', 'Payment', 'Sales', 'Purchase', 'Credit Note', 'Debit Note', 'Expense', 'Transfer', 'Other Income'
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
  final repo = ref.watch(transactionRepositoryProvider);

  var list = await repo.searchTransactions(filter.query);

  // Load relations
  for (var t in list) {
    try { await t.party.load(); } catch (_) {}
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
