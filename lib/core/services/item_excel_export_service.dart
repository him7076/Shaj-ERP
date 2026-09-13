import 'package:excel/excel.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';

class ItemExcelExportService {
  static List<int>? exportItemsToExcel(List<Item> items) {
    final excel = Excel.createExcel();
    final sheet = excel['Items_Export'];
    excel.setDefaultSheet('Items_Export');
    
    // Create Header Row
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
      TextCellValue('3rd Unit'),
      TextCellValue('2nd to 3rd Unit Factor'),
      TextCellValue('Sale Price'),
      TextCellValue('Wholesale Price'),
      TextCellValue('MRP'),
      TextCellValue('Purchase Price'),
      TextCellValue('Minimum Selling Price'),
      TextCellValue('GST Rate (%)'),
      TextCellValue('CESS Rate (%)'),
      TextCellValue('Opening Stock'),
      TextCellValue('Current Stock'),
      TextCellValue('Minimum Stock / Reorder Level'),
      TextCellValue('Barcode'),
      TextCellValue('SKU Code'),
      TextCellValue('Default Batch Number'),
      TextCellValue('Weight (kg)'),
      TextCellValue('Dimensions'),
      TextCellValue('Notes / Description'),
    ]);

    for (var item in items) {
      sheet.appendRow([
        TextCellValue(item.itemCode ?? ''),
        TextCellValue(item.itemName ?? ''),
        TextCellValue(item.shortName ?? ''),
        TextCellValue(item.category.value?.categoryName ?? ''),
        TextCellValue(item.brand.value?.brandName ?? ''),
        TextCellValue(item.hsnCode ?? ''),
        TextCellValue(item.primaryUnitName ?? item.unit.value?.shortName ?? ''),
        TextCellValue(item.secondaryUnit ?? ''),
        DoubleCellValue(item.conversionFactor ?? 1.0),
        TextCellValue(item.tertiaryUnit ?? ''),
        DoubleCellValue(item.secondaryToTertiaryConversion ?? 1.0),
        DoubleCellValue(item.sellRate ?? 0.0),
        DoubleCellValue(item.wholesaleRate ?? 0.0),
        DoubleCellValue(item.mrp ?? 0.0),
        DoubleCellValue(item.buyRate ?? 0.0),
        DoubleCellValue(item.minimumSellingPrice ?? 0.0),
        DoubleCellValue(item.gstRate ?? 0.0),
        DoubleCellValue(item.cessRate ?? 0.0),
        DoubleCellValue(item.openingStock ?? 0.0),
        DoubleCellValue(item.currentStock ?? 0.0),
        DoubleCellValue(item.reorderLevel ?? item.minimumStock ?? 0.0),
        TextCellValue(item.barcode ?? ''),
        TextCellValue(item.skuCode ?? item.sku ?? ''),
        TextCellValue(item.defaultBatchNumber ?? ''),
        DoubleCellValue(item.weight ?? 0.0),
        TextCellValue(item.dimensions ?? ''),
        TextCellValue(item.notes ?? ''),
      ]);
    }
    
    return excel.encode();
  }
}
