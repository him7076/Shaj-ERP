import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'party_collection.dart';
import 'order_collection.dart';
import 'invoice_item_collection.dart';

part 'invoice_collection.g.dart';

@collection
class Invoice implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? invoiceNumber;

  DateTime? invoiceDate;

  // Invoice type: Tax Invoice, Retail Invoice, Cash Invoice, Credit Invoice
  @Index()
  String? invoiceType;

  // Invoice status: Draft, Unpaid, Partially Paid, Paid, Cancelled
  @Index()
  String? invoiceStatus;

  // Link back to Order
  int? sourceOrderId;
  String? sourceOrderNumber;

  // Party Details (snapshot copy for audit trail)
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
  DateTime? dueDate;

  // Notes
  String? remarks;
  String? termsAndConditions;

  // Cancellation Logs
  String? cancelledBy;
  DateTime? cancelledDate;
  String? cancellationReason;

  // Audit Fields
  String? createdBy;
  String? editedBy;
  DateTime? editTime;

  // Isar Links
  final party = IsarLink<Party>();
  final order = IsarLink<Order>();

  @Backlink(to: 'invoice')
  final invoiceItems = IsarLinks<InvoiceItem>();

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
