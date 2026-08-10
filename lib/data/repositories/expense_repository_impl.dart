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

  @override
  Future<String> generateNextVoucherNumber() async {
    try {
      final expenses = await collection.filter().isDeletedEqualTo(false).findAll();

      // Migration: Convert old EXP-100x format to clean EXP-x format
      bool migrated = false;
      for (var exp in expenses) {
        final vNo = exp.voucherNo;
        if (vNo != null && vNo.startsWith('EXP-100')) {
          final suffix = vNo.replaceFirst('EXP-100', '');
          final numVal = int.tryParse(suffix);
          if (numVal != null && numVal > 0) {
            exp.voucherNo = 'EXP-$numVal';
            migrated = true;
          }
        }
      }

      if (migrated) {
        await isar.writeTxn(() async {
          await collection.putAll(expenses);
        });
      }

      int maxNum = 0;
      final regExp = RegExp(r'\d+');

      for (var exp in expenses) {
        final vNo = exp.voucherNo;
        if (vNo != null && vNo.isNotEmpty) {
          final matches = regExp.allMatches(vNo);
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
      }

      final nextNum = maxNum + 1;
      return 'EXP-$nextNum';
    } catch (e) {
      final count = await collection.count();
      return 'EXP-${count + 1}';
    }
  }
}
