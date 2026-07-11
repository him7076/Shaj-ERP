import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'base_repository.dart';

abstract class CategoryRepository implements BaseRepository<Category> {
  /// Fetches only top-level parent categories
  Future<List<Category>> getParentCategories();

  /// Fetches subcategories belonging to a given parent category ID
  Future<List<Category>> getSubCategories(int parentId);
}
