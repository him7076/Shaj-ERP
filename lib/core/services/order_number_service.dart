import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class OrderNumberService {
  final Isar isar;

  OrderNumberService(this.isar);

  /// Generates the next sequential unique Order Number prefixed by SO (e.g. SO-01, SO-02)
  Future<String> generateNextOrderNumber() async {
    try {
      final allOrders = await isar.orders.where().findAll();
      int maxNum = 0;
      for (var order in allOrders) {
        if (order.orderNumber != null && order.orderNumber!.startsWith('SO-')) {
          final match = RegExp(r'\d+').firstMatch(order.orderNumber!);
          if (match != null) {
            final parsed = int.tryParse(match.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final numStr = (maxNum + 1).toString().padLeft(2, '0');
      final nextCode = 'SO-$numStr';
      logger.debug('Generated next order number: $nextCode');
      return nextCode;
    } catch (e) {
      throw OrderException('Failed to generate next order number: $e');
    }
  }
}
