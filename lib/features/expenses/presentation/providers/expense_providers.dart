import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/expense_repository.dart';
import 'package:business_sahaj_erp/data/repositories/expense_repository_impl.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ExpenseRepositoryImpl(isar);
});

final expenseSearchQueryProvider = StateProvider<String>((ref) => '');

final expenseListProvider = FutureProvider<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final query = ref.watch(expenseSearchQueryProvider);

  if (query.trim().isEmpty) {
    return await repo.getAll();
  } else {
    return await repo.searchExpenses(query);
  }
});

class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  final ExpenseRepository _repository;
  final Ref _ref;

  ExpenseNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> saveExpense(Expense expense) async {
    state = const AsyncValue.loading();
    try {
      if (expense.id == 0 || expense.id == null) {
        await _repository.create(expense);
      } else {
        await _repository.update(expense);
      }
      state = const AsyncValue.data(null);
      _ref.invalidate(expenseListProvider);
      return true;
    } catch (e, stack) {
      logger.error('Failed to save expense log', e, stack);
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(expenseListProvider);
      return true;
    } catch (e, stack) {
      logger.error('Failed to delete expense log', e, stack);
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return ExpenseNotifier(repo, ref);
});
