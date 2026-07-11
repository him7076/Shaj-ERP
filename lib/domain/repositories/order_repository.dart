import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'base_repository.dart';

abstract class OrderRepository implements BaseRepository<Order> {
  /// Searches orders by matching order number, party name, or phone number
  Future<List<Order>> searchOrders(String query);

  /// Generates the next sequential unique Order Number
  Future<String> generateNextOrderNumber();

  /// Saves or updates an order along with its items transactionally
  Future<void> saveOrder(Order order, List<OrderItem> items);

  /// Cancels an order, recording user audits and reasons
  Future<void> cancelOrder(String orderUuid, String reason, String user);
}
