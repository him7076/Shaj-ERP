import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'expense_collection.g.dart';

@collection
class Expense implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index()
  String? category; // Rent, Salaries, Office Expense, Utilities, Tea & Snacks, Other

  double? amount;

  DateTime? expenseDate;

  String? paymentMode; // Cash, Bank Transfer, Card, UPI

  String? remarks;

  @override
  DateTime createdAt = DateTime.now();

  @override
  DateTime updatedAt = DateTime.now();

  @override
  bool isDeleted = false;

  @override
  bool isSynced = false;

  @override
  int version = 1;
}
