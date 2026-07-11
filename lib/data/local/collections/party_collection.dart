import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'party_collection.g.dart';

@collection
class Party implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? partyCode; // Auto Generated: CUS0001, RET0001, etc.

  @Index()
  String? partyName;

  String? partyType; // Customer, Retailer, Wholesaler, Distributor, Supplier, or Custom

  // Contact details
  @Index()
  String? mobileNumber;
  String? whatsappNumber;
  String? email;

  // GST details
  @Index()
  String? gstNumber;
  String? panNumber;
  String? gstType; // Registered, Unregistered, Composition

  // Address
  String? addressLine1;
  String? addressLine2;
  String? city;
  String? state;
  String? pincode;

  // Geolocation
  double? latitude;
  double? longitude;
  String? locationAddress; // Reverse geocoded address
  String? googleMapUrl;

  // Accounting Details
  double? openingBalance;
  String? balanceType; // Dr / Cr
  double? creditLimit;
  double? outstandingBalance;
  String? paymentTerms; // Net 15, Net 30, Cash, etc.
  int? dueDays;

  // Business Details
  String? contactPerson;
  String? businessCategory;
  String? notes;

  // Multiple shop/party photos
  List<String>? shopPhotos;     // Local file paths
  List<String>? shopPhotoUrls;  // Remote Firebase Storage URLs

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
