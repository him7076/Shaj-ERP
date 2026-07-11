import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/item_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class StockService {
  final ItemRepository itemRepository;

  StockService(this.itemRepository);

  /// Adjusts stock for a given item. Positive quantity represents Stock In (Purchases, Returns),
  /// negative represents Stock Out (Sales, Damage).
  Future<void> adjustStock(
    Item item,
    double quantity,
    String reason, {
    bool isSyncDownload = false,
  }) async {
    try {
      final double current = item.currentStock ?? 0.0;
      final double newStock = current + quantity;

      if (newStock < 0) {
        throw StockException(
          'Insufficient stock for item "${item.itemName}". Available: $current, Requested reduction: ${quantity.abs()}',
        );
      }

      item.currentStock = newStock;

      // Add a history line inside item.notes
      final timestamp = DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' ');
      final type = quantity >= 0 ? 'STOCK_IN' : 'STOCK_OUT';
      final changeStr = quantity >= 0 ? '+$quantity' : '$quantity';
      final logEntry = '[$timestamp] $type: $changeStr | Bal: $newStock | Reason: $reason';
      
      final currentNotes = item.notes ?? '';
      item.notes = currentNotes.isEmpty ? logEntry : '$logEntry\n$currentNotes';

      // Save/update in database
      await itemRepository.update(item, isSyncDownload: isSyncDownload);
      logger.info('Stock adjusted for item "${item.itemName}": $changeStr. New stock: $newStock');
    } on StockException {
      rethrow;
    } catch (e) {
      throw StockException('Failed to adjust stock for item "${item.itemName}": $e');
    }
  }

  /// Verifies if an item is running low on stock
  bool isLowStock(Item item) {
    final current = item.currentStock ?? 0.0;
    final reorder = item.reorderLevel ?? 0.0;
    
    // An item is low stock if it's active and its stock falls to or below reorder level.
    // Default threshold is 0 if reorder level isn't specified.
    return current <= reorder;
  }

  /// Verifies if stock is completely out
  bool isOutOfStock(Item item) {
    final current = item.currentStock ?? 0.0;
    return current <= 0;
  }

  /// Filter out low-stock items from a list
  List<Item> getLowStockItems(List<Item> allItems) {
    return allItems.where((item) => isLowStock(item) && !isOutOfStock(item)).toList();
  }

  /// Filter out out-of-stock items from a list
  List<Item> getOutOfStockItems(List<Item> allItems) {
    return allItems.where((item) => isOutOfStock(item)).toList();
  }

  /// Parse the stock history log from the notes field
  List<String> getStockHistory(Item item) {
    final notes = item.notes ?? '';
    if (notes.trim().isEmpty) return [];
    return notes.split('\n').where((line) => line.contains('| Bal:')).toList();
  }
}
