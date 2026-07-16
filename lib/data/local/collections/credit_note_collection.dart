import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'party_collection.dart';
import 'credit_note_item_collection.dart';

part 'credit_note_collection.g.dart';

@collection
class CreditNote implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? creditNoteNumber;

  DateTime? creditNoteDate;

  // Invoice / Bill reference being returned
  String? originalInvoiceNumber;
  String? originalInvoiceUuid;

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

  @Backlink(to: 'creditNote')
  final creditNoteItems = IsarLinks<CreditNoteItem>();

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
