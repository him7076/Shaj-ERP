import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
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

  @override
  Future<String> generateNextVoucherNumber() async {
    try {
      final expenses = await collection.filter().isDeletedEqualTo(false).findAll();
      final txns = await isar.collection<Transaction>().filter().isDeletedEqualTo(false).and().transactionTypeEqualTo('Expense').findAll();

      int maxNum = 0;
      final regExp = RegExp(r'\d+');

      void checkNum(String? str) {
        if (str == null || str.trim().isEmpty) return;
        final matches = regExp.allMatches(str);
        if (matches.isNotEmpty) {
          final numStr = matches.last.group(0);
          if (numStr != null) {
            final parsed = int.tryParse(numStr);
            if (parsed != null && parsed > maxNum) {
              maxNum = parsed;
            }
          }
        }
      }

      for (var exp in expenses) {
        checkNum(exp.voucherNo);
      }

      for (var t in txns) {
        checkNum(t.referenceNumber);
        checkNum(t.transactionNumber);
      }

      final totalCount = expenses.length + txns.length;
      final nextNum = maxNum > 0 ? (maxNum + 1) : (totalCount + 1);
      return 'EXP-$nextNum';
    } catch (e) {
      final count = await collection.count();
      return 'EXP-${count + 1}';
    }
  }
}
