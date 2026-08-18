import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'whatsapp_mapping_collection.g.dart';

@collection
class WhatsAppMapping implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  // 'Party' or 'Item'
  @Index()
  String? mappingType;

  // rawShopName or rawItemLine
  @Index()
  String? rawKey;

  // partyUuid or itemUuid
  String? targetUuid;

  double? pcsPerBundle;
  double? pcsPerCarton;
  double? customRate;

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
