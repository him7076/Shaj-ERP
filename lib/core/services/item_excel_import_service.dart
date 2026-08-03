import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';

class ImportItemResult {
  final int totalItemsImported;
  final int totalItemsUpdated;
  final List<String> errors;

  ImportItemResult({
    required this.totalItemsImported,
    required this.totalItemsUpdated,
    required this.errors,
  });
}

class ItemExcelImportService {
  /// Generates the sample Excel template (.xlsx) for Items Import as specified
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header row
    sheet.appendRow([
      TextCellValue('Item code'),
      TextCellValue('item name'),
      TextCellValue('HSN'),
      TextCellValue('Sale Price'),
      TextCellValue('purchse price'),
      TextCellValue('discount type'),
      TextCellValue('sale Discount'),
      TextCellValue('current Stock QTY'),
      TextCellValue('Minimum stock qty'),
      TextCellValue('item Location'),
      TextCellValue('Tax rate'),
      TextCellValue('Tax inclusiv'),
    ]);

    // Sample Row 1
    sheet.appendRow([
      TextCellValue('ITM-001'),
      TextCellValue('Men Cotton Casual Shirt (Blue)'),
      TextCellValue('6105'),
      DoubleCellValue(850.00),
      DoubleCellValue(500.00),
      TextCellValue('discount %'),
      TextCellValue('10%'),
      DoubleCellValue(100.0),
      DoubleCellValue(10.0),
      TextCellValue('Warehouse A - Shelf 2'),
      TextCellValue('5%'),
      TextCellValue('no'),
    ]);

    // Sample Row 2
    sheet.appendRow([
      TextCellValue('ITM-002'),
      TextCellValue('Women Designer Kurti'),
      TextCellValue('6204'),
      DoubleCellValue(1200.00),
      DoubleCellValue(750.00),
      TextCellValue('Discount Amount'),
      DoubleCellValue(100.00),
      DoubleCellValue(50.0),
      DoubleCellValue(5.0),
      TextCellValue('Main Store - Display 1'),
      TextCellValue('12%'),
      TextCellValue('yes'),
    ]);

    return excel.encode();
  }

  /// Imports Items & Stock details from decoded Excel bytes
  static Future<ImportItemResult> importItemsFromBytes(
    Uint8List bytes,
    DatabaseService dbService,
  ) async {
    final List<String> errors = [];
    int totalItemsImported = 0;
    int totalItemsUpdated = 0;

    try {
      final excel = Excel.decodeBytes(bytes);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) {
        return ImportItemResult(
          totalItemsImported: 0,
          totalItemsUpdated: 0,
          errors: ['The selected Excel file contains no worksheets.'],
        );
      }

      final Sheet? sheet = excel.tables['Sheet1'] ?? excel.tables[sheetKeys.first];
      if (sheet == null || sheet.rows.length <= 1) {
        return ImportItemResult(
          totalItemsImported: 0,
          totalItemsUpdated: 0,
          errors: ['The Excel worksheet contains no data rows.'],
        );
      }

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        final itemCode = _getCellValue(row, 0).trim(); // Col A: Item code
        final itemName = _getCellValue(row, 1).trim(); // Col B: item name

        if (itemName.isEmpty && itemCode.isEmpty) continue;

        final hsn = _getCellValue(row, 2).trim(); // Col C: HSN
        final salePrice = _parseDouble(_getCellValue(row, 3)); // Col D: Sale Price
        final purchasePrice = _parseDouble(_getCellValue(row, 4)); // Col E: purchse price
        final discountType = _getCellValue(row, 5).trim(); // Col F: discount type
        final saleDiscount = _getCellValue(row, 6).trim(); // Col G: sale Discount
        final currentStock = _parseDouble(_getCellValue(row, 7)); // Col H: current Stock QTY
        final minStock = _parseDouble(_getCellValue(row, 8)); // Col I: Minimum stock qty
        final location = _getCellValue(row, 9).trim(); // Col J: item Location
        final taxRateStr = _getCellValue(row, 10).trim(); // Col K: Tax rate
        final taxInclusiveStr = _getCellValue(row, 11).trim().toLowerCase(); // Col L: Tax inclusiv

        final taxRate = _parseGstPercent(taxRateStr);
        final isTaxInclusive = taxInclusiveStr == 'yes' || taxInclusiveStr == 'true' || taxInclusiveStr == '1';

        final effectiveCode = itemCode.isNotEmpty
            ? itemCode
            : 'ITM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$r';

        final effectiveName = itemName.isNotEmpty ? itemName : 'Item $effectiveCode';

        final notesStr = [
          if (location.isNotEmpty) 'Location: $location',
          if (saleDiscount.isNotEmpty) 'Discount: $saleDiscount ($discountType)',
          if (isTaxInclusive) 'Tax Inclusive: Yes',
        ].join(' | ');

        try {
          // Check if item exists by itemCode or itemName
          Item? existingItem;
          if (itemCode.isNotEmpty) {
            existingItem = await isar.items.filter().itemCodeEqualTo(itemCode).findFirst();
          }
          existingItem ??= await isar.items.filter().itemNameEqualTo(effectiveName).findFirst();

          if (existingItem != null) {
            // Update existing Item
            existingItem.itemName = effectiveName;
            existingItem.hsnCode = hsn.isNotEmpty ? hsn : existingItem.hsnCode;
            existingItem.sellRate = salePrice > 0 ? salePrice : existingItem.sellRate;
            existingItem.buyRate = purchasePrice > 0 ? purchasePrice : existingItem.buyRate;
            existingItem.currentStock = (existingItem.currentStock ?? 0.0) + currentStock;
            existingItem.minimumStock = minStock > 0 ? minStock : existingItem.minimumStock;
            existingItem.reorderLevel = minStock > 0 ? minStock : existingItem.reorderLevel;
            existingItem.gstRate = taxRate > 0 ? taxRate : existingItem.gstRate;
            existingItem.notes = notesStr.isNotEmpty ? notesStr : existingItem.notes;
            existingItem.updatedAt = DateTime.now();

            await isar.writeTxn(() async {
              await isar.items.put(existingItem!);
            });

            // Enqueue for Sync
            final queueItem = SyncQueue()
              ..uuid = const Uuid().v4()
              ..entityType = 'Item'
              ..entityId = existingItem.id
              ..entityUuid = existingItem.uuid
              ..operation = 'Update'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

            await isar.writeTxn(() async {
              await isar.syncQueues.put(queueItem);
            });

            totalItemsUpdated++;
          } else {
            // Create New Item
            final newItem = Item()
              ..uuid = const Uuid().v4()
              ..itemCode = effectiveCode
              ..itemName = effectiveName
              ..hsnCode = hsn
              ..sellRate = salePrice
              ..buyRate = purchasePrice
              ..openingStock = currentStock
              ..currentStock = currentStock
              ..minimumStock = minStock
              ..reorderLevel = minStock
              ..gstApplicable = true
              ..gstRate = taxRate
              ..notes = notesStr
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

            await isar.writeTxn(() async {
              newItem.id = await isar.items.put(newItem);
            });

            // Enqueue for Sync
            final queueItem = SyncQueue()
              ..uuid = const Uuid().v4()
              ..entityType = 'Item'
              ..entityId = newItem.id
              ..entityUuid = newItem.uuid
              ..operation = 'Create'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

            await isar.writeTxn(() async {
              await isar.syncQueues.put(queueItem);
            });

            totalItemsImported++;
          }
        } catch (itemErr) {
          logger.error('Error importing item row $r', itemErr);
          errors.add('Row $r ($effectiveName): ${itemErr.toString()}');
        }
      }
    } catch (e, stackTrace) {
      logger.error('Failed to parse item excel file', e, stackTrace);
      errors.add('Failed to parse Excel file: $e');
    }

    return ImportItemResult(
      totalItemsImported: totalItemsImported,
      totalItemsUpdated: totalItemsUpdated,
      errors: errors,
    );
  }

  static String _getCellValue(List<Data?> row, int colIndex) {
    if (colIndex >= row.length || row[colIndex] == null) return '';
    final val = row[colIndex]?.value;
    if (val == null) return '';
    return val.toString().trim();
  }

  static double _parseDouble(String val) {
    if (val.isEmpty) return 0.0;
    final clean = val.replaceAll('₹', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  static double _parseGstPercent(String str) {
    if (str.isEmpty) return 0.0;
    final regExp = RegExp(r'(\d+(?:\.\d+)?)%');
    final match = regExp.firstMatch(str);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return double.tryParse(str.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }
}
