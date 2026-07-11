import 'package:isar/isar.dart';
import 'isar_model.dart';
import 'category_collection.dart';
import 'unit_collection.dart';
import 'brand_collection.dart';

part 'item_collection.g.dart';

@collection
class Item implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  @Index(unique: true)
  String? itemCode;

  @Index()
  String? itemName;

  String? shortName;
  String? description;

  @Index()
  String? hsnCode;

  bool gstApplicable = true;
  double? gstRate;
  double? cessRate;

  double? buyRate;
  double? mrp;
  double? sellRate; // Standard selling rate
  double? wholesaleRate;
  double? minimumSellingPrice;

  double? openingStock;
  double? currentStock;
  double? reorderLevel;
  double? minimumStock;

  String? secondaryUnit;
  double? conversionFactor; // E.g. 1 BOX = 10 PCS

  @Index()
  String? barcode;

  @Index()
  String? sku;

  @Index()
  String? skuCode;

  List<String>? imagePaths; // Local image paths
  List<String>? firebaseImageUrls; // Firebase storage URLs
  String? thumbnailImage; // Local thumbnail path or small base64/url

  double? weight;
  String? dimensions;
  String? notes;

  // Isar Links
  final category = IsarLink<Category>();
  final unit = IsarLink<Unit>();
  final brand = IsarLink<Brand>();

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
