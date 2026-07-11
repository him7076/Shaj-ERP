import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class OrderNumberService {
  final Isar isar;

  OrderNumberService(this.isar);

  /// Generates the next sequential unique Order Number prefixed by ORD (e.g. ORD000001)
  Future<String> generateNextOrderNumber() async {
    try {
      final lastOrder = await isar.orders
          .filter()
          .orderNumberIsNotNull()
          .sortByOrderNumberDesc()
          .findFirst();

      if (lastOrder == null || lastOrder.orderNumber == null) {
        return 'ORD000001';
      }

      final code = lastOrder.orderNumber!;
      if (!code.startsWith('ORD')) {
        return 'ORD000001';
      }

      final numStr = code.substring(3);
      final currentNum = int.tryParse(numStr) ?? 0;
      final nextNum = currentNum + 1;
      
      final nextCode = 'ORD${nextNum.toString().padLeft(6, '0')}';
      logger.debug('Generated next order number: $nextCode (previous: $code)');
      return nextCode;
    } catch (e) {
      throw OrderException('Failed to generate next order number: $e');
    }
  }
}
