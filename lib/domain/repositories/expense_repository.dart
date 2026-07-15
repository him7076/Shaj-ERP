import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'base_repository.dart';

abstract class ExpenseRepository implements BaseRepository<Expense> {
  /// Searches expenses by category or remarks
  Future<List<Expense>> searchExpenses(String query);

  /// Retrieves list of expenses filtered by category or dates
  Future<List<Expense>> getExpensesByCategory(String category);
}
