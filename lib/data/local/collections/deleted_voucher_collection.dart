import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'deleted_voucher_collection.g.dart';

@collection
class DeletedVoucher implements IsarModel {

  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index()
  String? voucherType; // Sales Invoice, Purchase Bill, Payment, Receipt, Order, Credit Note, Debit Note

  @Index()
  String? voucherNumber;

  String? partyName;
  double? amount;
  String? remarks;
  DateTime? deletedAt;

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
