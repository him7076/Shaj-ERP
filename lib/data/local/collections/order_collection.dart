import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'party_collection.dart';
import 'order_item_collection.dart';

part 'order_collection.g.dart';

@collection
class Order implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? orderNumber;

  DateTime? orderDate;
  
  // Status: Draft, Pending, Confirmed, Cancelled, Converted To Sale
  @Index()
  String? status;

  // Party Information (snapshot copy for historical audit)
  int? partyId;
  String? partyName;
  String? mobileNumber;
  String? gstNumber;

  // GPS Location Tracking
  double? latitude;
  double? longitude;
  String? locationAddress;

  // Financial Summary Fields
  double? subtotal;
  double? discountAmount;
  double? discountPercent;
  double? totalGST;
  double? roundOff;
  double? grandTotal; // Maps to totalAmount if backward compatibility is needed
  
  // Notes
  String? remarks;
  String? internalNotes; // Stores modification logs, createdBy, etc.

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

  @Backlink(to: 'order')
  final orderItems = IsarLinks<OrderItem>();

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
