import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'base_repository.dart';

abstract class ItemRepository implements BaseRepository<Item> {
  /// Searches items by matching name, HSN code, or barcode
  Future<List<Item>> searchItems(String query);

  /// Generates the next unique auto-incrementing item code prefixed by ITM (e.g. ITM00001)
  Future<String> generateNextItemCode();
}
