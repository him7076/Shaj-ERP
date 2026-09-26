const fs = require('fs');
const path = require('path');

// 1. Modify item_excel_import_service.dart
const servicePath = path.join(__dirname, 'lib/core/services/item_excel_import_service.dart');
let serviceContent = fs.readFileSync(servicePath, 'utf8');

const validationResultClass = `class ImportValidationResult {
  final Set<String> missingCategories;
  final Set<String> missingBrands;
  final Set<String> missingUnits;
  final List<String> errors;

  ImportValidationResult({
    required this.missingCategories,
    required this.missingBrands,
    required this.missingUnits,
    required this.errors,
  });

  bool get hasMissingEntities => missingCategories.isNotEmpty || missingBrands.isNotEmpty || missingUnits.isNotEmpty;
}

class ImportItemResult {`;

serviceContent = serviceContent.replace('class ImportItemResult {', validationResultClass);

const validateMethod = `  static Future<ImportValidationResult> validateImport(
    Uint8List bytes,
    DatabaseService dbService,
  ) async {
    final Set<String> missingCategories = {};
    final Set<String> missingBrands = {};
    final Set<String> missingUnits = {};
    final List<String> errors = [];

    try {
      final excel = Excel.decodeBytes(bytes);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) return ImportValidationResult(missingCategories: {}, missingBrands: {}, missingUnits: {}, errors: ['No worksheets']);

      final Sheet? sheet = excel.tables['Sheet1'] ?? excel.tables[sheetKeys.first];
      if (sheet == null || sheet.rows.length <= 1) return ImportValidationResult(missingCategories: {}, missingBrands: {}, missingUnits: {}, errors: ['No data rows']);

      final colMap = _buildColumnMap(sheet.rows[0]);
      final colCategory = _findCol(colMap, ['category', 'item category', 'group'], 3);
      final colBrand = _findCol(colMap, ['brand', 'manufacturer', 'company'], 4);
      final colUnit = _findCol(colMap, ['primary unit', 'unit', 'uom', 'pack'], 6);
      final colSecUnit = _findCol(colMap, ['secondary unit', 'sec unit', 'sub unit'], 7);
      final colTerUnit = _findCol(colMap, ['3rd unit', 'tertiary unit', 'ter unit'], 9);

      final allCategories = await isar.categorys.filter().isDeletedEqualTo(false).findAll();
      final allBrands = await isar.brands.filter().isDeletedEqualTo(false).findAll();
      final allUnits = await isar.units.filter().isDeletedEqualTo(false).findAll();

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        final categoryStr = _getCellValue(row, colCategory).trim();
        final brandStr = _getCellValue(row, colBrand).trim();
        final primaryUnitStr = _getCellValue(row, colUnit).trim();
        final secUnitStr = _getCellValue(row, colSecUnit).trim();
        final terUnitStr = _getCellValue(row, colTerUnit).trim();

        if (categoryStr.isNotEmpty && !allCategories.any((c) => c.categoryName?.trim().toLowerCase() == categoryStr.toLowerCase())) {
          missingCategories.add(categoryStr);
        }
        if (brandStr.isNotEmpty && !allBrands.any((b) => b.brandName?.trim().toLowerCase() == brandStr.toLowerCase())) {
          missingBrands.add(brandStr);
        }
        
        final unitName = primaryUnitStr.isNotEmpty ? primaryUnitStr : 'PCS';
        if (!allUnits.any((u) => u.unitName?.trim().toLowerCase() == unitName.toLowerCase() || u.shortName?.trim().toLowerCase() == unitName.toLowerCase())) {
          missingUnits.add(unitName);
        }
        if (secUnitStr.isNotEmpty && !allUnits.any((u) => u.unitName?.trim().toLowerCase() == secUnitStr.toLowerCase() || u.shortName?.trim().toLowerCase() == secUnitStr.toLowerCase())) {
          missingUnits.add(secUnitStr);
        }
        if (terUnitStr.isNotEmpty && !allUnits.any((u) => u.unitName?.trim().toLowerCase() == terUnitStr.toLowerCase() || u.shortName?.trim().toLowerCase() == terUnitStr.toLowerCase())) {
          missingUnits.add(terUnitStr);
        }
      }
    } catch (e) {
      errors.add(e.toString());
    }

    return ImportValidationResult(
      missingCategories: missingCategories,
      missingBrands: missingBrands,
      missingUnits: missingUnits,
      errors: errors,
    );
  }

  /// Imports Products & Stock details`;

serviceContent = serviceContent.replace('  /// Imports Products & Stock details', validateMethod);


const secUnitCreation = `        // Find or create Unit Link
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

        if (secUnitStr.isNotEmpty) {
           Unit? secUnitObj = allUnits.where((u) => u.unitName?.trim().toLowerCase() == secUnitStr.toLowerCase() || u.shortName?.trim().toLowerCase() == secUnitStr.toLowerCase()).firstOrNull;
           if (secUnitObj == null) {
              secUnitObj = Unit()
                ..uuid = const Uuid().v4()
                ..unitName = secUnitStr
                ..shortName = secUnitStr
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now();
              await isar.writeTxn(() async { secUnitObj!.id = await isar.units.put(secUnitObj!); });
              allUnits.add(secUnitObj!);
           }
        }
        
        if (terUnitStr.isNotEmpty) {
           Unit? terUnitObj = allUnits.where((u) => u.unitName?.trim().toLowerCase() == terUnitStr.toLowerCase() || u.shortName?.trim().toLowerCase() == terUnitStr.toLowerCase()).firstOrNull;
           if (terUnitObj == null) {
              terUnitObj = Unit()
                ..uuid = const Uuid().v4()
                ..unitName = terUnitStr
                ..shortName = terUnitStr
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now();
              await isar.writeTxn(() async { terUnitObj!.id = await isar.units.put(terUnitObj!); });
              allUnits.add(terUnitObj!);
           }
        }`;

serviceContent = serviceContent.replace(`        // Find or create Unit Link
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
        }`, secUnitCreation);

fs.writeFileSync(servicePath, serviceContent, 'utf8');
console.log('Fixed item_excel_import_service.dart');

// 2. Modify items_screen.dart
const screenPath = path.join(__dirname, 'lib/features/items/presentation/screens/items_screen.dart');
let screenContent = fs.readFileSync(screenPath, 'utf8');

const importLogicTarget = `      final dbService = ref.read(databaseServiceProvider);
      final importResult = await ItemExcelImportService.importItemsFromBytes(`;

const importLogicReplacement = `      final dbService = ref.read(databaseServiceProvider);
      
      final validationResult = await ItemExcelImportService.validateImport(fileBytes, dbService);
      if (validationResult.errors.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Validation Error: \${validationResult.errors.first}')));
        }
        return;
      }
      
      if (validationResult.hasMissingEntities && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Missing Entities Found'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('The following items were found in the Excel file but are missing in your database. They will be auto-created if you proceed:'),
                  if (validationResult.missingCategories.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(validationResult.missingCategories.join(', ')),
                  ],
                  if (validationResult.missingBrands.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text('Brands:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(validationResult.missingBrands.join(', ')),
                  ],
                  if (validationResult.missingUnits.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text('Units:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(validationResult.missingUnits.join(', ')),
                  ],
                  SizedBox(height: 16),
                  Text('Do you want to proceed and auto-create them?'),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Proceed & Auto-Create')),
            ],
          )
        );
        if (proceed != true) return;
      }

      final progressController = StreamController<ImportProgressState>.broadcast();
      BuildContext? progressDialogContext;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            progressDialogContext = ctx;
            return ImportProgressModal(
              title: 'Importing Products & Stock',
              progressStream: progressController.stream,
            );
          },
        );
      }

      final importResult = await ItemExcelImportService.importItemsFromBytes(`;


const removeOldProgressModal = `      final progressController = StreamController<ImportProgressState>.broadcast();
      BuildContext? progressDialogContext;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            progressDialogContext = ctx;
            return ImportProgressModal(
              title: 'Importing Products & Stock',
              progressStream: progressController.stream,
            );
          },
        );
      }

      final dbService = ref.read(databaseServiceProvider);`;

screenContent = screenContent.replace(removeOldProgressModal, `      final dbService = ref.read(databaseServiceProvider);`);
screenContent = screenContent.replace(importLogicTarget, importLogicReplacement);

fs.writeFileSync(screenPath, screenContent, 'utf8');
console.log('Fixed items_screen.dart');
