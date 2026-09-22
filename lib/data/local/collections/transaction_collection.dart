import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'party_collection.dart';

part 'transaction_collection.g.dart';

@collection
class Transaction implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? transactionNumber;

  DateTime? transactionDate;

  String? partyUuid;
  String? partyName;

  // 'Sales', 'Purchase', 'Payment' (out), 'Receipt' (in), 'Credit Note', 'Debit Note', 'Expense', 'Transfer', 'Other Income'
  @Index()
  String? transactionType;

  double? amount;

  String? paymentMode; // 'Cash', 'Bank', 'UPI', 'Cheque', 'Credit'
  String? paymentStatus; // 'Paid', 'Partially Paid', 'Unpaid', 'Cancelled'
  String? referenceNumber;
  String? remarks;

  // Linked Invoice or Purchase UUID/Number
  String? linkedBillUuid;
  String? linkedBillNumber;

  // For Transfer type: recipient party info
  String? targetPartyUuid;
  String? targetPartyName;

  // Personal Vault Enhancements
  String? categoryUuid;
  String? categoryName;
  String? subCategoryUuid;
  String? subCategoryName;
  List<String>? tags;
  double? transferFee;

  final party = IsarLink<Party>();

  @Index()
  bool isPersonalVault = false;

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
