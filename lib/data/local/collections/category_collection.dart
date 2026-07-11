import 'package:isar/isar.dart';
import 'isar_model.dart';

part 'category_collection.g.dart';

@collection
class Category implements IsarModel {
  @override
  Id id = Isar.autoIncrement;

  @override
  @Index(unique: true)
  String? uuid;

  String? categoryName;
  String? description;

  // Self-referencing link for subcategories
  final parentCategory = IsarLink<Category>();

  @Backlink(to: 'parentCategory')
  final subCategories = IsarLinks<Category>();

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
