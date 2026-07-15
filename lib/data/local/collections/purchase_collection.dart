import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'party_collection.dart';
import 'purchase_item_collection.dart';

part 'purchase_collection.g.dart';

@collection
class Purchase implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? purchaseNumber;

  DateTime? purchaseDate;

  // Party Details (snapshot copy of the Supplier)
  int? partyId;
  String? partyName;
  String? gstNumber;
  String? address;

  // Financial Information
  double? subtotal;
  double? discountAmount;
  double? taxableAmount;
  double? cgstAmount;
  double? sgstAmount;
  double? igstAmount;
  double? totalGST;
  double? roundOff;
  double? grandTotal;

  // Payment Tracking
  @Index()
  String? paymentStatus; // Unpaid, Partially Paid, Paid
  double? paidAmount;
  double? pendingAmount;

  // Notes
  String? remarks;

  // Isar Links
  final party = IsarLink<Party>();

  @Backlink(to: 'purchase')
  final purchaseItems = IsarLinks<PurchaseItem>();

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
