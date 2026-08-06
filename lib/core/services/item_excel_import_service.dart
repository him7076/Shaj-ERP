import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/category_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/brand_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
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
  /// Generates sample Excel template (.xlsx) containing ALL Sahaj ERP product form fields including Price Tax Types
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Comprehensive Header Row with Tax Selectors for Prices
    sheet.appendRow([
      TextCellValue('Item Code'),
      TextCellValue('Item Name'),
      TextCellValue('Short Name'),
      TextCellValue('Category'),
      TextCellValue('Brand'),
      TextCellValue('HSN Code'),
      TextCellValue('Primary Unit'),
      TextCellValue('Secondary Unit'),
      TextCellValue('Conversion Factor'),
      TextCellValue('Sale Price'),
      TextCellValue('Sale Price Tax Type'), // With Tax / Without Tax
      TextCellValue('Wholesale Price'),
      TextCellValue('Wholesale Price Tax Type'), // With Tax / Without Tax
      TextCellValue('MRP'),
      TextCellValue('Purchase Price'),
      TextCellValue('Purchase Price Tax Type'), // Without Tax / With Tax
      TextCellValue('Minimum Selling Price'),
      TextCellValue('GST Rate (%)'),
      TextCellValue('CESS Rate (%)'),
      TextCellValue('Tax Inclusive'), // Yes/No
      TextCellValue('Opening Stock'),
      TextCellValue('Current Stock'),
      TextCellValue('Minimum Stock / Reorder Level'),
      TextCellValue('Barcode'),
      TextCellValue('SKU Code'),
      TextCellValue('Item Location'),
      TextCellValue('Default Batch Number'),
      TextCellValue('Weight (kg)'),
      TextCellValue('Dimensions'),
      TextCellValue('Notes / Description'),
    ]);

    // Sample Row 1
    sheet.appendRow([
      TextCellValue('ITM-001'),
      TextCellValue('Men Cotton Casual Shirt (Blue)'),
      TextCellValue('Shirt Blue'),
      TextCellValue('Apparel'),
      TextCellValue('Sahaj Fashion'),
      TextCellValue('6105'),
      TextCellValue('PCS'),
      TextCellValue('BOX'),
      DoubleCellValue(10.0),
      DoubleCellValue(850.00),
      TextCellValue('With Tax'),
      DoubleCellValue(780.00),
      TextCellValue('With Tax'),
      DoubleCellValue(999.00),
      DoubleCellValue(500.00),
      TextCellValue('Without Tax'),
      DoubleCellValue(750.00),
      TextCellValue('5%'),
      DoubleCellValue(0.0),
      TextCellValue('No'),
      DoubleCellValue(100.0),
      DoubleCellValue(100.0),
      DoubleCellValue(10.0),
      TextCellValue('8901234567890'),
      TextCellValue('SKU-SHIRT-01'),
      TextCellValue('Warehouse A - Shelf 2'),
      TextCellValue('BATCH-2026-A'),
      DoubleCellValue(0.35),
      TextCellValue('30x20x5 cm'),
      TextCellValue('100% pure combed cotton casual shirt'),
    ]);

    // Sample Row 2
    sheet.appendRow([
      TextCellValue('ITM-002'),
      TextCellValue('Women Designer Kurti'),
      TextCellValue('Kurti Des'),
      TextCellValue('Ethnic Wear'),
      TextCellValue('Sahaj Ethnic'),
      TextCellValue('6204'),
      TextCellValue('PCS'),
      TextCellValue('PACK'),
      DoubleCellValue(5.0),
      DoubleCellValue(1200.00),
      TextCellValue('With Tax'),
      DoubleCellValue(1100.00),
      TextCellValue('With Tax'),
      DoubleCellValue(1499.00),
      DoubleCellValue(750.00),
      TextCellValue('Without Tax'),
      DoubleCellValue(1050.00),
      TextCellValue('12%'),
      DoubleCellValue(0.0),
      TextCellValue('Yes'),
      DoubleCellValue(50.0),
      DoubleCellValue(50.0),
      DoubleCellValue(5.0),
      TextCellValue('8901234567891'),
      TextCellValue('SKU-KURTI-02'),
      TextCellValue('Main Store - Display 1'),
      TextCellValue('BATCH-2026-B'),
      DoubleCellValue(0.40),
      TextCellValue('35x25x4 cm'),
      TextCellValue('Rayon embroidery designer kurti'),
    ]);

    return excel.encode();
  }

  /// Imports Products & Stock details supporting flexible column headers and Price Tax Mode calculation
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

      final colMap = _buildColumnMap(sheet.rows[0]);

      final colCode = _findCol(colMap, ['item code', 'code', 'product code', 'sku code'], 0);
      final colName = _findCol(colMap, ['item name', 'name', 'product name', 'title'], 1);
      final colShortName = _findCol(colMap, ['short name', 'alias'], 2);
      final colCategory = _findCol(colMap, ['category', 'item category', 'group'], 3);
      final colBrand = _findCol(colMap, ['brand', 'manufacturer', 'company'], 4);
      final colHsn = _findCol(colMap, ['hsn code', 'hsn/sac', 'hsn', 'sac'], 5);
      final colUnit = _findCol(colMap, ['primary unit', 'unit', 'uom', 'pack'], 6);
      final colSecUnit = _findCol(colMap, ['secondary unit', 'sec unit', 'sub unit'], 7);
      final colConvFactor = _findCol(colMap, ['conversion factor', 'conversion', 'factor'], 8);
      
      final colSalePrice = _findCol(colMap, ['sale price', 'selling price', 'sell rate', 'rate'], 9);
      final colSaleTaxType = _findCol(colMap, ['sale price tax type', 'sale tax type', 'sell tax mode'], 10);
      
      final colWholesalePrice = _findCol(colMap, ['wholesale price', 'wholesale rate'], 11);
      final colWholesaleTaxType = _findCol(colMap, ['wholesale price tax type', 'wholesale tax type'], 12);
      
      final colMrp = _findCol(colMap, ['mrp', 'max retail price'], 13);
      
      final colPurchasePrice = _findCol(colMap, ['purchase price', 'buy rate', 'buy price', 'cost'], 14);
      final colBuyTaxType = _findCol(colMap, ['purchase price tax type', 'purchase tax type', 'buy tax mode'], 15);
      
      final colMinSellingPrice = _findCol(colMap, ['minimum selling price', 'min sale price', 'min sell rate'], 16);
      final colGstRate = _findCol(colMap, ['gst rate (%)', 'tax rate', 'gst %', 'gst', 'tax %'], 17);
      final colCessRate = _findCol(colMap, ['cess rate (%)', 'cess %', 'cess'], 18);
      final colTaxInclusive = _findCol(colMap, ['tax inclusive', 'inclusive tax', 'tax inclusiv'], 19);
      final colOpeningStock = _findCol(colMap, ['opening stock', 'opening qty'], 20);
      final colCurrentStock = _findCol(colMap, ['current stock qty', 'current stock', 'stock qty', 'qty', 'stock'], 21);
      final colMinStock = _findCol(colMap, ['minimum stock qty', 'minimum stock', 'reorder level', 'reorder qty'], 22);
      final colBarcode = _findCol(colMap, ['barcode', 'upc', 'ean'], 23);
      final colSku = _findCol(colMap, ['sku code', 'sku', 'product sku'], 24);
      final colLocation = _findCol(colMap, ['item location', 'location', 'shelf', 'warehouse'], 25);
      final colBatchNo = _findCol(colMap, ['default batch number', 'batch number', 'batch no', 'batch'], 26);
      final colWeight = _findCol(colMap, ['weight (kg)', 'weight', 'wt'], 27);
      final colDimensions = _findCol(colMap, ['dimensions', 'size'], 28);
      final colNotes = _findCol(colMap, ['notes / description', 'notes', 'description', 'remarks'], 29);

      final allCategories = await isar.categorys.filter().isDeletedEqualTo(false).findAll();
      final allBrands = await isar.brands.filter().isDeletedEqualTo(false).findAll();
      final allUnits = await isar.units.filter().isDeletedEqualTo(false).findAll();
      final allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        final itemCode = _getCellValue(row, colCode).trim();
        final itemName = _getCellValue(row, colName).trim();

        if (itemName.isEmpty && itemCode.isEmpty) continue;

        final shortName = _getCellValue(row, colShortName).trim();
        final categoryStr = _getCellValue(row, colCategory).trim();
        final brandStr = _getCellValue(row, colBrand).trim();
        final hsn = _getCellValue(row, colHsn).trim();
        final primaryUnitStr = _getCellValue(row, colUnit).trim();
        final secUnitStr = _getCellValue(row, colSecUnit).trim();
        final convFactor = _parseDouble(_getCellValue(row, colConvFactor));
        
        final rawSalePrice = _parseDouble(_getCellValue(row, colSalePrice));
        final saleTaxType = _getCellValue(row, colSaleTaxType).trim();
        
        final rawWholesalePrice = _parseDouble(_getCellValue(row, colWholesalePrice));
        final wholesaleTaxType = _getCellValue(row, colWholesaleTaxType).trim();

        final mrp = _parseDouble(_getCellValue(row, colMrp));

        final rawPurchasePrice = _parseDouble(_getCellValue(row, colPurchasePrice));
        final buyTaxType = _getCellValue(row, colBuyTaxType).trim();

        final minSellingPrice = _parseDouble(_getCellValue(row, colMinSellingPrice));
        final gstRateStr = _getCellValue(row, colGstRate).trim();
        final cessRate = _parseDouble(_getCellValue(row, colCessRate));
        final taxInclusiveStr = _getCellValue(row, colTaxInclusive).trim().toLowerCase();
        final openingStock = _parseDouble(_getCellValue(row, colOpeningStock));
        final currentStock = _parseDouble(_getCellValue(row, colCurrentStock));
        final minStock = _parseDouble(_getCellValue(row, colMinStock));
        final barcode = _getCellValue(row, colBarcode).trim();
        final sku = _getCellValue(row, colSku).trim();
        final location = _getCellValue(row, colLocation).trim();
        final defaultBatchNo = _getCellValue(row, colBatchNo).trim();
        final weight = _parseDouble(_getCellValue(row, colWeight));
        final dimensions = _getCellValue(row, colDimensions).trim();
        final notes = _getCellValue(row, colNotes).trim();

        final gstRate = _parseGstPercent(gstRateStr);

        // Calculate final effective rates considering Tax Modes
        double sellPrice = rawSalePrice;
        if (rawSalePrice > 0 && gstRate > 0) {
          if (saleTaxType.toLowerCase().contains('without')) {
            // Entered price is without tax; convert to tax inclusive selling rate for standard Sahaj ERP invoices
            sellPrice = rawSalePrice * (1 + (gstRate / 100));
          }
        }

        double wholesalePrice = rawWholesalePrice;
        if (rawWholesalePrice > 0 && gstRate > 0) {
          if (wholesaleTaxType.toLowerCase().contains('without')) {
            wholesalePrice = rawWholesalePrice * (1 + (gstRate / 100));
          }
        }

        double purchasePrice = rawPurchasePrice;
        if (rawPurchasePrice > 0 && gstRate > 0) {
          if (buyTaxType.toLowerCase().contains('with') && !buyTaxType.toLowerCase().contains('without')) {
            // Entered purchase rate is inclusive of tax; convert to base purchase rate without tax
            purchasePrice = rawPurchasePrice / (1 + (gstRate / 100));
          }
        }

        final effectiveCode = itemCode.isNotEmpty
            ? itemCode
            : 'ITM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$r';
        final effectiveName = itemName.isNotEmpty ? itemName : 'Item $effectiveCode';

        final effectiveCurrentStock = currentStock > 0 ? currentStock : openingStock;

        // Notes construction
        final taxNotes = [
          if (saleTaxType.isNotEmpty) 'Sale Tax: $saleTaxType',
          if (buyTaxType.isNotEmpty) 'Purchase Tax: $buyTaxType',
          if (wholesaleTaxType.isNotEmpty) 'Wholesale Tax: $wholesaleTaxType',
          if (location.isNotEmpty) 'Location: $location',
          if (notes.isNotEmpty) notes,
        ].join(' | ');

        // Find or create Category Link
        Category? catObj;
        if (categoryStr.isNotEmpty) {
          catObj = allCategories.where((c) => c.categoryName?.trim().toLowerCase() == categoryStr.toLowerCase()).firstOrNull;
          if (catObj == null) {
            catObj = Category()
              ..uuid = const Uuid().v4()
              ..categoryName = categoryStr
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();
            await isar.writeTxn(() async {
              catObj!.id = await isar.categorys.put(catObj!);
            });
            allCategories.add(catObj!);
          }
        }

        // Find or create Brand Link
        Brand? brandObj;
        if (brandStr.isNotEmpty) {
          brandObj = allBrands.where((b) => b.brandName?.trim().toLowerCase() == brandStr.toLowerCase()).firstOrNull;
          if (brandObj == null) {
            brandObj = Brand()
              ..uuid = const Uuid().v4()
              ..brandName = brandStr
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();
            await isar.writeTxn(() async {
              brandObj!.id = await isar.brands.put(brandObj!);
            });
            allBrands.add(brandObj!);
          }
        }

        // Find or create Unit Link
        Unit? unitObj;
        final unitName = primaryUnitStr.isNotEmpty ? primaryUnitStr : 'PCS';
        unitObj = allUnits.where((u) => u.unitName?.trim().toLowerCase() == unitName.toLowerCase() || u.shortName?.trim().toLowerCase() == unitName.toLowerCase()).firstOrNull;
        if (unitObj == null) {
          unitObj = Unit()
            ..uuid = const Uuid().v4()
            ..unitName = unitName
            ..shortName = unitName
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.writeTxn(() async {
            unitObj!.id = await isar.units.put(unitObj!);
          });
          allUnits.add(unitObj!);
        }

        try {
          Item? existingItem;
          if (itemCode.isNotEmpty) {
            existingItem = allItems.where((i) => i.itemCode?.trim() == itemCode).firstOrNull;
          }
          if (existingItem == null && barcode.isNotEmpty) {
            existingItem = allItems.where((i) => i.barcode?.trim() == barcode).firstOrNull;
          }
          existingItem ??= allItems.where((i) => i.itemName?.trim().toLowerCase() == effectiveName.toLowerCase()).firstOrNull;

          if (existingItem != null) {
            // Update existing Item
            existingItem.itemName = effectiveName;
            existingItem.shortName = shortName.isNotEmpty ? shortName : existingItem.shortName;
            existingItem.hsnCode = hsn.isNotEmpty ? hsn : existingItem.hsnCode;
            existingItem.sellRate = sellPrice > 0 ? sellPrice : existingItem.sellRate;
            existingItem.wholesaleRate = wholesalePrice > 0 ? wholesalePrice : existingItem.wholesaleRate;
            existingItem.mrp = mrp > 0 ? mrp : existingItem.mrp;
            existingItem.buyRate = purchasePrice > 0 ? purchasePrice : existingItem.buyRate;
            existingItem.minimumSellingPrice = minSellingPrice > 0 ? minSellingPrice : existingItem.minimumSellingPrice;
            existingItem.currentStock = (existingItem.currentStock ?? 0.0) + effectiveCurrentStock;
            existingItem.minimumStock = minStock > 0 ? minStock : existingItem.minimumStock;
            existingItem.reorderLevel = minStock > 0 ? minStock : existingItem.reorderLevel;
            existingItem.gstApplicable = true;
            existingItem.gstRate = gstRate > 0 ? gstRate : existingItem.gstRate;
            existingItem.cessRate = cessRate > 0 ? cessRate : existingItem.cessRate;
            existingItem.secondaryUnit = secUnitStr.isNotEmpty ? secUnitStr : existingItem.secondaryUnit;
            existingItem.conversionFactor = convFactor > 0 ? convFactor : existingItem.conversionFactor;
            existingItem.barcode = barcode.isNotEmpty ? barcode : existingItem.barcode;
            existingItem.sku = sku.isNotEmpty ? sku : existingItem.sku;
            existingItem.skuCode = sku.isNotEmpty ? sku : existingItem.skuCode;
            existingItem.defaultBatchNumber = defaultBatchNo.isNotEmpty ? defaultBatchNo : existingItem.defaultBatchNumber;
            existingItem.weight = weight > 0 ? weight : existingItem.weight;
            existingItem.dimensions = dimensions.isNotEmpty ? dimensions : existingItem.dimensions;
            existingItem.notes = taxNotes.isNotEmpty ? taxNotes : existingItem.notes;
            existingItem.updatedAt = DateTime.now();

            if (catObj != null) existingItem.category.value = catObj;
            if (brandObj != null) existingItem.brand.value = brandObj;
            if (unitObj != null) existingItem.unit.value = unitObj;

            await isar.writeTxn(() async {
              await isar.items.put(existingItem!);
              try { await existingItem.category.save(); } catch (_) {}
              try { await existingItem.brand.save(); } catch (_) {}
              try { await existingItem.unit.save(); } catch (_) {}
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
              ..shortName = shortName
              ..hsnCode = hsn
              ..sellRate = sellPrice
              ..wholesaleRate = wholesalePrice
              ..mrp = mrp > 0 ? mrp : sellPrice
              ..buyRate = purchasePrice
              ..minimumSellingPrice = minSellingPrice
              ..openingStock = openingStock > 0 ? openingStock : effectiveCurrentStock
              ..currentStock = effectiveCurrentStock
              ..minimumStock = minStock
              ..reorderLevel = minStock
              ..gstApplicable = true
              ..gstRate = gstRate
              ..cessRate = cessRate
              ..secondaryUnit = secUnitStr
              ..conversionFactor = convFactor > 0 ? convFactor : 1.0
              ..barcode = barcode
              ..sku = sku
              ..skuCode = sku
              ..defaultBatchNumber = defaultBatchNo
              ..weight = weight
              ..dimensions = dimensions
              ..notes = taxNotes
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

            if (catObj != null) newItem.category.value = catObj;
            if (brandObj != null) newItem.brand.value = brandObj;
            if (unitObj != null) newItem.unit.value = unitObj;

            await isar.writeTxn(() async {
              newItem.id = await isar.items.put(newItem);
              try { await newItem.category.save(); } catch (_) {}
              try { await newItem.brand.save(); } catch (_) {}
              try { await newItem.unit.save(); } catch (_) {}
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

  static Map<String, int> _buildColumnMap(List<Data?> headerRow) {
    final Map<String, int> map = {};
    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell != null && cell.value != null) {
        final val = cell.value.toString().trim().toLowerCase();
        if (val.isNotEmpty) {
          map[val] = i;
        }
      }
    }
    return map;
  }

  static int _findCol(Map<String, int> colMap, List<String> candidates, int defaultIndex) {
    for (var cand in candidates) {
      if (colMap.containsKey(cand)) {
        return colMap[cand]!;
      }
    }
    for (var entry in colMap.entries) {
      for (var cand in candidates) {
        if (entry.key.contains(cand)) {
          return entry.value;
        }
      }
    }
    return defaultIndex;
  }

  static String _getCellValue(List<Data?> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length || row[colIndex] == null) return '';
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
