import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'item_collection.dart';
import 'credit_note_collection.dart';

part 'credit_note_item_collection.g.dart';

@collection
class CreditNoteItem implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  int? itemId;
  String? itemName;
  String? hsnCode;

  // Helper field to track parent for Web mock queries
  int? parentCreditNoteId;

  double? quantity;
  double? freeQuantity;
  double? rate;
  double? discount; // discount amount

  double? taxableAmount;
  double? gstRate;
  double? gstAmount;
  double? totalAmount;

  final creditNote = IsarLink<CreditNote>();
  final item = IsarLink<Item>();

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
