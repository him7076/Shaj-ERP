import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/vault/presentation/providers/vault_provider.dart';

class PersonalStatsState {
  final String type; // 'Expense' or 'Income'
  final String timeRange; // 'TODAY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM'
  final DateTimeRange? customDateRange;
  final String? selectedCategory;

  const PersonalStatsState({
    this.type = 'Expense',
    this.timeRange = 'MONTHLY',
    this.customDateRange,
    this.selectedCategory,
  });

  PersonalStatsState copyWith({
    String? type,
    String? timeRange,
    DateTimeRange? customDateRange,
    String? selectedCategory,
    bool clearCategory = false,
  }) {
    return PersonalStatsState(
      type: type ?? this.type,
      timeRange: timeRange ?? this.timeRange,
      customDateRange: customDateRange ?? this.customDateRange,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }
}

class PersonalStatsNotifier extends StateNotifier<PersonalStatsState> {
  PersonalStatsNotifier() : super(const PersonalStatsState());

  void setType(String type) {
    if (state.type != type) {
      state = state.copyWith(type: type, clearCategory: true);
    }
  }

  void setTimeRange(String range, {DateTimeRange? customRange}) {
    state = state.copyWith(timeRange: range, customDateRange: customRange, clearCategory: true);
  }

  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category, clearCategory: category == null);
  }
}

final personalStatsStateProvider = StateNotifierProvider<PersonalStatsNotifier, PersonalStatsState>((ref) {
  return PersonalStatsNotifier();
});

class PersonalStatsData {
  final List<Transaction> allTransactions; // filtered by type and time
  final Map<String, double> categoryTotals;
  final double totalAmount;
  
  PersonalStatsData({
    required this.allTransactions,
    required this.categoryTotals,
    required this.totalAmount,
  });
}

final personalStatsDataProvider = FutureProvider<PersonalStatsData>((ref) async {
  final filter = ref.watch(personalStatsStateProvider);
  final isar = ref.watch(isarProvider);
  final isPersonal = ref.watch(vaultModeProvider) == VaultMode.personal;

  if (!isPersonal) {
    return PersonalStatsData(allTransactions: [], categoryTotals: {}, totalAmount: 0);
  }

  DateTime now = DateTime.now();
  DateTime startDate;
  DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (filter.timeRange) {
    case 'TODAY':
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case 'WEEKLY':
      int daysToSubtract = now.weekday - 1;
      startDate = DateTime(now.year, now.month, now.day - daysToSubtract);
      break;
    case 'MONTHLY':
      startDate = DateTime(now.year, now.month, 1);
      break;
    case 'YEARLY':
      startDate = DateTime(now.year, 1, 1);
      break;
    case 'CUSTOM':
      startDate = filter.customDateRange?.start ?? DateTime(2000);
      endDate = filter.customDateRange?.end.add(const Duration(hours: 23, 59, 59)) ?? now;
      break;
    default:
      startDate = DateTime(2000);
  }

  final isIncome = filter.type == 'Income';
  final allowedTypes = isIncome ? ['Receipt', 'Other Income', 'Income'] : ['Payment', 'Expense'];

  var query = isar.transactions.filter()
      .isDeletedEqualTo(false)
      .isPersonalVaultEqualTo(true)
      .and()
      .group((q) => q.transactionDateBetween(startDate, endDate)
           .or()
           .group((q2) => q2.transactionDateIsNull().and().createdAtBetween(startDate, endDate)))
      .and()
      .anyOf(allowedTypes, (q, String type) => q.transactionTypeEqualTo(type))
      .sortByTransactionDateDesc();

  final transactions = await query.findAll();

  double totalAmt = 0;
  Map<String, double> catTotals = {};

  for (var txn in transactions) {
    final amt = txn.amount ?? 0;
    totalAmt += amt;
    final catName = txn.categoryName?.isNotEmpty == true ? txn.categoryName! : 'Other';
    catTotals[catName] = (catTotals[catName] ?? 0) + amt;
  }

  final sortedEntries = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  catTotals = Map.fromEntries(sortedEntries);

  return PersonalStatsData(
    allTransactions: transactions,
    categoryTotals: catTotals,
    totalAmount: totalAmt,
  );
});
