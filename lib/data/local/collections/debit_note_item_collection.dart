import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'item_collection.dart';
import 'debit_note_collection.dart';

part 'debit_note_item_collection.g.dart';

@collection
class DebitNoteItem implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  int? itemId;
  String? itemName;
  String? hsnCode;

  // Helper field to track parent for Web mock queries
  int? parentDebitNoteId;

  double? quantity;
  double? freeQuantity;
  double? rate;
  double? discount; // discount amount

  double? taxableAmount;
  double? gstRate;
  double? gstAmount;
  double? totalAmount;

  final debitNote = IsarLink<DebitNote>();
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
