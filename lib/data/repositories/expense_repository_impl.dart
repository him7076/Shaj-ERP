import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/expense_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class ExpenseRepositoryImpl extends BaseIsarRepository<Expense> implements ExpenseRepository {
  ExpenseRepositoryImpl(Isar isar) : super(isar, 'Expense');

  @override
  IsarCollection<Expense> get collection => isar.collection<Expense>();

  @override
  Future<List<Expense>> searchExpenses(String query) async {
    if (query.trim().isEmpty) {
      return await getAll();
    }

    try {
      final cleanQuery = query.trim();
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .categoryContains(cleanQuery, caseSensitive: false)
              .or()
              .remarksContains(cleanQuery, caseSensitive: false))
          .findAll();
    } catch (e) {
      throw DatabaseException('Failed to search expenses: $e');
    }
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String category) async {
    try {
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .categoryEqualTo(category, caseSensitive: false)
          .findAll();
    } catch (e) {
      throw DatabaseException('Failed to get expenses by category: $e');
    }
  }
}
