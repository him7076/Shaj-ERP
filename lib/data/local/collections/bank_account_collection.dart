import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'bank_account_collection.g.dart';

@collection
class BankAccount implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index()
  String? accountName; // e.g. "HDFC Current Account"

  String? bankName;    // e.g. "HDFC Bank"
  String? accountNumber;
  String? ifscCode;
  String? branchName;
  double? openingBalance;
  double? currentBalance;

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
