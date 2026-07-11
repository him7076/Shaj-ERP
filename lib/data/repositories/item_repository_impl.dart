import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/item_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class ItemRepositoryImpl extends BaseIsarRepository<Item> implements ItemRepository {
  ItemRepositoryImpl(Isar isar) : super(isar, 'Item');

  @override
  IsarCollection<Item> get collection => isar.collection<Item>();

  @override
  Future<List<Item>> searchItems(String query) async {
    if (query.trim().isEmpty) {
      return await getAll();
    }

    try {
      final cleanQuery = query.trim();
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .itemNameContains(cleanQuery, caseSensitive: false)
              .or()
              .itemCodeContains(cleanQuery, caseSensitive: false)
              .or()
              .hsnCodeContains(cleanQuery, caseSensitive: false)
              .or()
              .barcodeContains(cleanQuery, caseSensitive: false)
              .or()
              .skuContains(cleanQuery, caseSensitive: false)
              .or()
              .skuCodeContains(cleanQuery, caseSensitive: false))
          .findAll();
    } catch (e) {
      throw DatabaseException('Failed to search items: $e');
    }
  }

  @override
  Future<String> generateNextItemCode() async {
    try {
      // Find the active or inactive item with the highest ID or highest code.
      // Fetching all to find highest is safe for reasonable inventory size,
      // but a query sorted by itemCode descending is much better.
      final lastItem = await collection
          .filter()
          .itemCodeIsNotNull()
          .sortByItemCodeDesc()
          .findFirst();

      if (lastItem == null || lastItem.itemCode == null) {
        return 'ITM00001';
      }

      final code = lastItem.itemCode!;
      if (!code.startsWith('ITM')) {
        return 'ITM00001';
      }

      final numStr = code.substring(3);
      final currentNum = int.tryParse(numStr) ?? 0;
      final nextNum = currentNum + 1;
      
      final nextCode = 'ITM${nextNum.toString().padLeft(5, '0')}';
      logger.debug('Generated next item code: $nextCode (previous: $code)');
      return nextCode;
    } catch (e) {
      throw DatabaseException('Failed to generate next item code: $e');
    }
  }
}
