import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'party_collection.dart';
import 'debit_note_item_collection.dart';

part 'debit_note_collection.g.dart';

@collection
class DebitNote implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? debitNoteNumber;

  DateTime? debitNoteDate;

  // Purchase Bill reference being returned
  String? originalPurchaseNumber;
  String? originalPurchaseUuid;

  int? partyId;
  String? partyName;
  String? gstNumber;
  String? address;

  double? subtotal;
  double? discountAmount;
  double? taxableAmount;
  double? cgstAmount;
  double? sgstAmount;
  double? igstAmount;
  double? totalGST;
  double? roundOff;
  double? grandTotal;

  String? remarks;
  String? createdBy;

  final party = IsarLink<Party>();

  @Backlink(to: 'debitNote')
  final debitNoteItems = IsarLinks<DebitNoteItem>();

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
