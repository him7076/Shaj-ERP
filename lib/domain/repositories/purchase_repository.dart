import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'base_repository.dart';

abstract class PurchaseRepository implements BaseRepository<Purchase> {
  /// Searches purchases by purchase number or supplier party name
  Future<List<Purchase>> searchPurchases(String query);

  /// Generates the next sequential Purchase Number
  Future<String> generateNextPurchaseNumber();

  /// Saves a purchase bill along with its items transactionally,
  /// updating stock levels of items.
  Future<void> savePurchase(Purchase purchase, List<PurchaseItem> items);
}
