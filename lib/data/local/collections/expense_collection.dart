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
  String? voucherNo; // Expense Voucher No (EXP-001)

  @Index()
  String? category; // Rent, Salaries, Office Expense, Utilities, Tea & Snacks, Other

  String? partyName; // Vendor / Payee Name

  double? amount; // Grand Total Amount

  double? subtotal; // Subtotal before round off

  double? roundOff; // Round off amount

  DateTime? expenseDate;

  String? paymentMode; // Cash, Bank Transfer, Card, UPI

  String? remarks;

  String? itemsJson; // JSON array of repeatable line items: [{name: 'Tea', qty: 10, rate: 10, amount: 100}]

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
