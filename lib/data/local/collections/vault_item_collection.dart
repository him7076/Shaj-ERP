import 'package:isar/isar.dart';

part 'vault_item_collection.g.dart';

@collection
class VaultItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? uuid;

  String? title;
  
  String? content;

  DateTime? createdAt;
  
  DateTime? updatedAt;
}
