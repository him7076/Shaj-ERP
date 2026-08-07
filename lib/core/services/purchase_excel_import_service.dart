import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/unit_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';

enum DuplicateBillAction {
  overwrite,
  skip,
}

class ImportPurchaseResult {
  final int totalBillsImported;
  final int totalItemsImported;
  final int skippedBills;
  final List<String> errors;

  ImportPurchaseResult({
    required this.totalBillsImported,
    required this.totalItemsImported,
    this.skippedBills = 0,
    required this.errors,
  });
}

class PurchaseExcelImportService {
  static const Uuid _uuidGen = Uuid();

  /// Checks Excel (bytes or pre-decoded object) for bill numbers / supplier invoice numbers that already exist in database
  static Future<List<String>> checkForDuplicateBills(
    dynamic bytesOrExcel,
    DatabaseService dbService,
  ) async {
    final List<String> duplicates = [];
    try {
      final Excel excel = bytesOrExcel is Excel
          ? bytesOrExcel
          : Excel.decodeBytes(bytesOrExcel as Uint8List);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) return duplicates;

      final Sheet? headerSheet = excel.tables['Sheet1'] ?? excel.tables[sheetKeys.first];
      if (headerSheet == null || headerSheet.rows.length <= 1) return duplicates;

      final s1ColMap = _buildColumnMap(headerSheet.rows[0]);
      final colS1BillNo = _findCol(s1ColMap, ['purchase bill number', 'purchase bill no', 'bill number', 'bill no', 'bill #', 'voucher number', 'voucher no', 'voucher #', 'ref no', 'ref number', 'no.'], 5);
      final colS1SupplierInvNo = _findCol(s1ColMap, ['supplier invoice number', 'supplier invoice no', 'supplier bill number', 'supplier bill no', 'invoice number', 'invoice no', 'invoice #', 'bill number', 'bill no', 'inv no', 'invoice'], 6);

      final existingPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final existingNumbers = <String>{};
      for (var p in existingPurchases) {
        if (p.purchaseNumber != null && p.purchaseNumber!.isNotEmpty) {
          existingNumbers.add(_normalizeKey(p.purchaseNumber!));
          final d = _extractDigits(p.purchaseNumber!);
          if (d.isNotEmpty) existingNumbers.add(d);
        }
        if (p.supplierInvoiceNumber != null && p.supplierInvoiceNumber!.isNotEmpty) {
          existingNumbers.add(_normalizeKey(p.supplierInvoiceNumber!));
          final d = _extractDigits(p.supplierInvoiceNumber!);
          if (d.isNotEmpty) existingNumbers.add(d);
        }
      }

      for (int r = 1; r < headerSheet.rows.length; r++) {
        final row = headerSheet.rows[r];
        if (row.isEmpty) continue;
        final billNo = _getCellValue(row, colS1BillNo).trim();
        final suppInvNo = _getCellValue(row, colS1SupplierInvNo).trim();

        final effectiveCheck = billNo.isNotEmpty ? billNo : suppInvNo;
        if (effectiveCheck.isEmpty) continue;

        final normBill = _normalizeKey(billNo);
        final normSupp = _normalizeKey(suppInvNo);
        final digBill = _extractDigits(billNo);
        final digSupp = _extractDigits(suppInvNo);

        if ((normBill.isNotEmpty && existingNumbers.contains(normBill)) ||
            (normSupp.isNotEmpty && existingNumbers.contains(normSupp)) ||
            (digBill.isNotEmpty && existingNumbers.contains(digBill)) ||
            (digSupp.isNotEmpty && existingNumbers.contains(digSupp))) {
          if (!duplicates.contains(effectiveCheck)) {
            duplicates.add(effectiveCheck);
          }
        }
      }
    } catch (e) {
      logger.error('Error checking duplicate bills in excel', e);
    }
    return duplicates;
  }

  /// Generates sample Excel template (.xlsx) with 2 sheets for Purchase Import
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();

    // Sheet 1: Purchases Summary / Header
    final sheet1 = excel['Sheet1'];
    sheet1.appendRow([
      TextCellValue('Date'),
      TextCellValue('Supplier Party Name'),
      TextCellValue('Phone No.'),
      TextCellValue('Supplier GST Number'),
      TextCellValue('Order Number'),
      TextCellValue('Purchase Bill Number'),
      TextCellValue('Supplier Invoice Number'),
      TextCellValue('Transaction Type'),
      TextCellValue('Total Amount'),
      TextCellValue('Payment Type'),
      TextCellValue('Paid Amount'),
      TextCellValue('Balance Amount'),
      TextCellValue('Description'),
    ]);

    sheet1.appendRow([
      TextCellValue('13/07/2026'),
      TextCellValue('PROSOURCING INTERNATIONAL LLP'),
      TextCellValue('9876543210'),
      TextCellValue('24ABEFP1587E1ZB'),
      TextCellValue('PO-01'),
      TextCellValue('PUR-01'),
      TextCellValue('SUP-8891'),
      TextCellValue('Purchase'),
      DoubleCellValue(164220.33),
      TextCellValue('Cash'),
      DoubleCellValue(0.00),
      DoubleCellValue(164220.33),
      TextCellValue('Stock received from halol depo'),
    ]);

    sheet1.appendRow([
      TextCellValue('14/07/2026'),
      TextCellValue('Global Tech Supplies Pvt Ltd'),
      TextCellValue('9123456789'),
      TextCellValue('27AAACG9876C1Z3'),
      TextCellValue('PO-02'),
      TextCellValue('PUR-02'),
      TextCellValue('INV-9920'),
      TextCellValue('Purchase'),
      DoubleCellValue(55000.00),
      TextCellValue('Credit'),
      DoubleCellValue(20000.00),
      DoubleCellValue(35000.00),
      TextCellValue('Raw material purchase'),
    ]);

    // Sheet 2: Item Details
    final sheet2 = excel['Sheet2'];
    sheet2.appendRow([
      TextCellValue('Date'),
      TextCellValue('Supplier Party Name'),
      TextCellValue('Invoice/Bill Number'),
      TextCellValue('Item Name'),
      TextCellValue('Batch Number'),
      TextCellValue('Expire Date'),
      TextCellValue('MFG Date'),
      TextCellValue('Item Code'),
      TextCellValue('HSN/SAC'),
      TextCellValue('QTY'),
      TextCellValue('Unit'),
      TextCellValue('Price per unit'),
      TextCellValue('Discount'),
      TextCellValue('GST'),
      TextCellValue('Amount'),
    ]);

    sheet2.appendRow([
      TextCellValue('13/07/2026'),
      TextCellValue('PROSOURCING INTERNATIONAL LLP'),
      TextCellValue('SUP-8891'),
      TextCellValue('Cotton Fabric Roll (Blue)'),
      TextCellValue('B-01'),
      TextCellValue('12/2027'),
      TextCellValue('01/2026'),
      TextCellValue('ITM-01'),
      TextCellValue('8471'),
      DoubleCellValue(50.0),
      TextCellValue('PCS'),
      DoubleCellValue(3284.40),
      TextCellValue('0.00'),
      TextCellValue('18%'),
      DoubleCellValue(164220.33),
    ]);

    sheet2.appendRow([
      TextCellValue('14/07/2026'),
      TextCellValue('Global Tech Supplies Pvt Ltd'),
      TextCellValue('INV-9920'),
      TextCellValue('Industrial Zipper 12 inch'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('ITM-02'),
      TextCellValue('9607'),
      DoubleCellValue(500.0),
      TextCellValue('PCS'),
      DoubleCellValue(100.00),
      TextCellValue('0.00'),
      TextCellValue('10%'),
      DoubleCellValue(55000.00),
    ]);

    return excel.encode();
  }

  /// Imports Purchase Bills and Line Items from Excel (bytes or pre-decoded object)
  static Future<ImportPurchaseResult> importPurchaseBillsFromBytes(
    dynamic bytesOrExcel,
    DatabaseService dbService, {
    DuplicateBillAction duplicateAction = DuplicateBillAction.overwrite,
    ImportProgressCallback? onProgress,
  }) async {
    final List<String> errors = [];
    int totalBillsImported = 0;
    int totalItemsImported = 0;
    int skippedBills = 0;

    try {
      final Excel excel = bytesOrExcel is Excel
          ? bytesOrExcel
          : Excel.decodeBytes(bytesOrExcel as Uint8List);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) {
        return ImportPurchaseResult(
          totalBillsImported: 0,
          totalItemsImported: 0,
          skippedBills: 0,
          errors: ['The selected Excel file contains no worksheets.'],
        );
      }

      final Sheet? headerSheet = excel.tables['Sheet1'] ?? excel.tables[sheetKeys.first];
      Sheet? itemSheet;
      if (excel.tables.containsKey('Sheet2')) {
        itemSheet = excel.tables['Sheet2'];
      } else if (sheetKeys.length > 1) {
        itemSheet = excel.tables[sheetKeys[1]];
      }

      if (headerSheet == null) {
        return ImportPurchaseResult(
          totalBillsImported: 0,
          totalItemsImported: 0,
          skippedBills: 0,
          errors: ['Could not find Purchase Bills Header worksheet.'],
        );
      }

      final totalHeaderRows = headerSheet.rows.length - 1;

      // Column mapping for Sheet 1
      final s1ColMap = headerSheet.rows.isNotEmpty ? _buildColumnMap(headerSheet.rows[0]) : <String, int>{};

      final colS1Date = _findCol(s1ColMap, ['date', 'bill date', 'invoice date'], 0);
      final colS1Party = _findCol(s1ColMap, ['supplier party name', 'party name', 'supplier name', 'supplier', 'party'], 1);
      final colS1Phone = _findCol(s1ColMap, ['phone', 'mobile', 'contact'], 2);
      final colS1Gst = _findCol(s1ColMap, ['supplier gst', 'party gst', 'gst number', 'gstin', 'gst'], 3);
      final colS1OrderNo = _findCol(s1ColMap, ['order number', 'po number'], 4);
      final colS1BillNo = _findCol(s1ColMap, ['purchase bill number', 'purchase bill no', 'bill number', 'bill no', 'bill #', 'voucher number', 'voucher no', 'voucher #', 'ref no', 'ref number', 'no.'], 5);
      final colS1SupplierInvNo = _findCol(s1ColMap, ['supplier invoice number', 'supplier invoice no', 'supplier bill number', 'supplier bill no', 'invoice number', 'invoice no', 'invoice #', 'bill number', 'bill no', 'inv no', 'invoice'], 6);
      final colS1TotalAmt = _findCol(s1ColMap, ['total amount', 'grand total', 'total', 'amount'], 8);
      final colS1PaidAmt = _findCol(s1ColMap, ['paid amount', 'paid'], 10);
      final colS1BalAmt = _findCol(s1ColMap, ['balance amount', 'due amount', 'balance', 'pending'], 11);
      final colS1Desc = _findCol(s1ColMap, ['description', 'remarks', 'notes'], 12);

      // Column mapping for Sheet 2
      final s2ColMap = (itemSheet != null && itemSheet.rows.isNotEmpty) ? _buildColumnMap(itemSheet.rows[0]) : <String, int>{};

      final colS2Date = _findCol(s2ColMap, ['date', 'bill date', 'invoice date'], 0);
      final colS2Party = _findCol(s2ColMap, ['supplier party name', 'party name', 'supplier name', 'party'], 1);
      final colS2BillNo = _findCol(s2ColMap, ['invoice/bill number', 'supplier invoice number', 'supplier invoice no', 'invoice number', 'bill number', 'invoice no', 'bill no', 'invoice #', 'bill #', 'voucher number', 'voucher no', 'ref no', 'no.', 'invoice', 'bill'], 2);
      final colS2ItemName = _findCol(s2ColMap, ['item name', 'product name', 'item', 'product', 'description'], 3);
      final colS2BatchNo = _findCol(s2ColMap, ['batch number', 'batch no', 'batch'], 4);
      final colS2ExpDate = _findCol(s2ColMap, ['expire date', 'exp date', 'expiry'], 5);
      final colS2MfgDate = _findCol(s2ColMap, ['mfg date', 'manufacturing date'], 6);
      final colS2ItemCode = _findCol(s2ColMap, ['item code', 'code', 'barcode'], 7);
      final colS2Hsn = _findCol(s2ColMap, ['hsn/sac', 'hsn', 'sac'], 8);
      final colS2Qty = _findCol(s2ColMap, ['qty', 'quantity', 'count'], 9);
      final colS2Unit = _findCol(s2ColMap, ['unit', 'uom', 'pack'], 10);
      final colS2Rate = _findCol(s2ColMap, ['price per unit', 'purchase price', 'buy rate', 'rate', 'price'], 11);
      final colS2Disc = _findCol(s2ColMap, ['discount', 'disc'], 12);
      final colS2Gst = _findCol(s2ColMap, ['gst', 'tax rate', 'tax %', 'tax'], 13);
      final colS2Amount = _findCol(s2ColMap, ['amount', 'total', 'line total'], 14);

      // 1. Index Sheet 2 Items strictly by Normalized Invoice/Bill Number & Digits
      final Map<String, List<Map<String, dynamic>>> itemsByBillNo = {};
      final Map<String, List<Map<String, dynamic>>> itemsByDigits = {};

      if (itemSheet != null && itemSheet.rows.length > 1) {
        onProgress?.call(0, totalHeaderRows > 0 ? totalHeaderRows : 1, 'Indexing Sheet 2 item line details...');

        String lastSeenBillNo = '';

        for (int r = 1; r < itemSheet.rows.length; r++) {
          final row = itemSheet.rows[r];
          if (row.isEmpty) continue;

          String billNo = _getCellValue(row, colS2BillNo).trim();
          final itemName = _getCellValue(row, colS2ItemName).trim();
          final partyName = _getCellValue(row, colS2Party).trim();
          final dateStr = _getCellValue(row, colS2Date).trim();

          if (itemName.isEmpty) continue;

          // Continuation row inheritance
          if (billNo.isNotEmpty) {
            lastSeenBillNo = billNo;
          } else if (lastSeenBillNo.isNotEmpty) {
            billNo = lastSeenBillNo;
          }

          final itemData = {
            'date': dateStr,
            'partyName': partyName,
            'billNo': billNo,
            'itemName': itemName,
            'batchNo': _getCellValue(row, colS2BatchNo),
            'expDate': _getCellValue(row, colS2ExpDate),
            'mfgDate': _getCellValue(row, colS2MfgDate),
            'itemCode': _getCellValue(row, colS2ItemCode),
            'hsnCode': _getCellValue(row, colS2Hsn),
            'qty': _parseDouble(_getCellValue(row, colS2Qty)),
            'unit': _getCellValue(row, colS2Unit).isNotEmpty ? _getCellValue(row, colS2Unit) : 'PCS',
            'rate': _parseDouble(_getCellValue(row, colS2Rate)),
            'discount': _parseDiscountVal(_getCellValue(row, colS2Disc)),
            'gstStr': _getCellValue(row, colS2Gst),
            'amount': _parseDouble(_getCellValue(row, colS2Amount)),
          };

          final normBillNo = _normalizeKey(billNo);
          final digitsBillNo = _extractDigits(billNo);

          if (normBillNo.isNotEmpty) {
            itemsByBillNo.putIfAbsent(normBillNo, () => []).add(itemData);
          }
          if (digitsBillNo.isNotEmpty && digitsBillNo != normBillNo) {
            itemsByDigits.putIfAbsent(digitsBillNo, () => []).add(itemData);
          }
        }
      }

      final allParties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
      final allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();

      // 2. Iterate Sheet 1 Headers & Create / Overwrite Purchase Bills
      for (int r = 1; r < headerSheet.rows.length; r++) {
        final row = headerSheet.rows[r];
        if (row.isEmpty) continue;

        final partyName = _getCellValue(row, colS1Party).trim();
        final billNo = _getCellValue(row, colS1BillNo).trim();
        final suppInvNo = _getCellValue(row, colS1SupplierInvNo).trim();

        if (partyName.isEmpty && billNo.isEmpty && suppInvNo.isEmpty) continue;

        final effectiveBillNo = billNo.isNotEmpty
            ? billNo
            : (suppInvNo.isNotEmpty
                ? suppInvNo
                : 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$r');

        final effectiveSupplierInvNo = suppInvNo.isNotEmpty ? suppInvNo : (billNo.isNotEmpty ? billNo : '');

        // Notify progress and yield main event loop to prevent browser freeze
        onProgress?.call(r, totalHeaderRows, 'Processing purchase bill "$effectiveBillNo" ($r/$totalHeaderRows)...');
        await Future.delayed(Duration.zero);

        final dateStr = _getCellValue(row, colS1Date);
        final phone = _getCellValue(row, colS1Phone);
        final gstNo = _getCellValue(row, colS1Gst);
        final orderNo = _getCellValue(row, colS1OrderNo);
        final totalAmount = _parseDouble(_getCellValue(row, colS1TotalAmt));
        final paidAmount = _parseDouble(_getCellValue(row, colS1PaidAmt));
        final balanceAmount = _parseDouble(_getCellValue(row, colS1BalAmt));
        final description = _getCellValue(row, colS1Desc);

        try {
          final normBillNo = _normalizeKey(effectiveBillNo);
          final normSuppInvNo = _normalizeKey(effectiveSupplierInvNo);

          // Check if purchase bill number or supplier invoice number already exists
          List<Purchase> matchingPurchases = [];
          final allExistingPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();

          matchingPurchases = allExistingPurchases.where((p) {
            final pBill = _normalizeKey(p.purchaseNumber ?? '');
            final pSupp = _normalizeKey(p.supplierInvoiceNumber ?? '');
            return (normBillNo.isNotEmpty && (pBill == normBillNo || pSupp == normBillNo)) ||
                   (normSuppInvNo.isNotEmpty && (pBill == normSuppInvNo || pSupp == normSuppInvNo));
          }).toList();

          if (matchingPurchases.isNotEmpty) {
            if (duplicateAction == DuplicateBillAction.skip) {
              skippedBills++;
              errors.add('Purchase bill "$effectiveBillNo" already exists in database (Skipped).');
              continue;
            }

            // DuplicateAction.overwrite: Clean old line items, reverse item stock, and purge old purchase
            for (var oldP in matchingPurchases) {
              final allPurItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();
              final oldItems = allPurItems.where((oi) => 
                oi.purchaseId == oldP.id || 
                (oldP.uuid != null && oldP.uuid!.isNotEmpty && oi.purchaseUuid == oldP.uuid) ||
                oi.purchase.value?.id == oldP.id
              ).toList();

              await isar.writeTxn(() async {
                for (var oi in oldItems) {
                  if (oi.itemId != null) {
                    final targetItem = await isar.items.get(oi.itemId!);
                    if (targetItem != null) {
                      targetItem.currentStock = (targetItem.currentStock ?? 0.0) - (oi.quantity ?? 0.0);
                      await isar.items.put(targetItem);
                    }
                  }
                  await isar.purchaseItems.delete(oi.id);
                }
                await isar.purchases.delete(oldP.id);
              });
            }
          }

          // Find or create Supplier Party
          Party? party;
          if (partyName.isNotEmpty) {
            party = allParties.where((p) => p.partyName?.trim().toLowerCase() == partyName.toLowerCase()).firstOrNull;
            if (party == null) {
              party = Party()
                ..uuid = _uuidGen.v4()
                ..partyName = partyName
                ..partyCode = 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                ..partyType = 'Supplier'
                ..mobileNumber = phone
                ..gstNumber = gstNo
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now();

              await isar.writeTxn(() async {
                party!.id = await isar.partys.put(party!);
              });
              allParties.add(party!);
            }
          }

          final purchaseUuid = _uuidGen.v4();

          // Create Purchase Record
          final purchase = Purchase()
            ..uuid = purchaseUuid
            ..purchaseNumber = effectiveBillNo
            ..supplierInvoiceNumber = effectiveSupplierInvNo
            ..purchaseDate = _parseDate(dateStr)
            ..partyId = party?.id
            ..partyName = partyName
            ..gstNumber = gstNo
            ..remarks = description.isNotEmpty ? description : 'Imported via Excel'
            ..grandTotal = totalAmount
            ..paidAmount = paidAmount
            ..pendingAmount = balanceAmount > 0 ? balanceAmount : (totalAmount - paidAmount)
            ..paymentStatus = paidAmount >= totalAmount && totalAmount > 0
                ? 'Paid'
                : (paidAmount > 0 ? 'Partially Paid' : 'Unpaid')
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          if (party != null) {
            purchase.party.value = party;
          }

          // Retrieve items matching THIS SPECIFIC PURCHASE BILL (with fuzzy and single-invoice fallback)
          final normEffBill = _normalizeKey(effectiveBillNo);
          final normEffSupp = _normalizeKey(effectiveSupplierInvNo);
          final digitsEffBill = _extractDigits(effectiveBillNo);
          final digitsEffSupp = _extractDigits(effectiveSupplierInvNo);

          List<Map<String, dynamic>> rawItems = [];
          if (normEffBill.isNotEmpty && itemsByBillNo.containsKey(normEffBill)) {
            rawItems = itemsByBillNo.remove(normEffBill)!;
          } else if (normEffSupp.isNotEmpty && itemsByBillNo.containsKey(normEffSupp)) {
            rawItems = itemsByBillNo.remove(normEffSupp)!;
          } else if (digitsEffBill.isNotEmpty && itemsByDigits.containsKey(digitsEffBill)) {
            rawItems = itemsByDigits.remove(digitsEffBill)!;
          } else if (digitsEffSupp.isNotEmpty && itemsByDigits.containsKey(digitsEffSupp)) {
            rawItems = itemsByDigits.remove(digitsEffSupp)!;
          } else {
            final partyNorm = _normalizeKey(partyName);
            String? matchedKey;
            for (var k in itemsByBillNo.keys) {
              if (itemsByBillNo[k]!.any((i) => (partyNorm.isNotEmpty && _normalizeKey(i['partyName'] as String) == partyNorm) || _normalizeKey(i['billNo'] as String).contains(normEffBill) || (normEffBill.isNotEmpty && _normalizeKey(i['billNo'] as String).contains(normEffBill)))) {
                matchedKey = k;
                break;
              }
            }
            if (matchedKey != null) {
              rawItems = itemsByBillNo.remove(matchedKey)!;
            } else if (totalHeaderRows == 1 && itemsByBillNo.isNotEmpty) {
              rawItems = itemsByBillNo.values.expand((list) => list).toList();
              itemsByBillNo.clear();
            }
          }

          final List<PurchaseItem> createdItems = [];
          double calcSubtotal = 0.0;
          double calcTotalGST = 0.0;

          for (var itemMap in rawItems) {
            final itemName = itemMap['itemName'] as String;
            final itemCode = itemMap['itemCode'] as String;
            final hsn = itemMap['hsnCode'] as String;
            final qty = itemMap['qty'] as double;
            final unit = itemMap['unit'] as String;
            final rate = itemMap['rate'] as double;
            final discount = itemMap['discount'] as double;
            final gstStr = itemMap['gstStr'] as String;
            final itemAmt = itemMap['amount'] as double;

            final gstRatePercent = _parseGstPercent(gstStr);

            // Find or create Catalog Item
            Item? catalogItem;
            if (itemName.isNotEmpty) {
              catalogItem = allItems.where((i) => i.itemName?.trim().toLowerCase() == itemName.toLowerCase()).firstOrNull;
              if (catalogItem == null) {
                catalogItem = Item()
                  ..uuid = _uuidGen.v4()
                  ..itemCode = itemCode.isNotEmpty ? itemCode : 'ITM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                  ..itemName = itemName
                  ..hsnCode = hsn
                  ..buyRate = rate
                  ..sellRate = rate > 0 ? (rate * 1.25) : 0.0
                  ..currentStock = 0.0
                  ..openingStock = 0.0
                  ..primaryUnitName = unit.isNotEmpty ? unit : 'PCS'
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now();

                await isar.writeTxn(() async {
                  catalogItem!.id = await isar.items.put(catalogItem!);
                });
                allItems.add(catalogItem!);
              }

              // Bind exact Unit collection entity to catalog item
              if (unit.isNotEmpty) {
                final allUnits = await isar.units.filter().isDeletedEqualTo(false).findAll();
                Unit? matchedUnit = allUnits.where((u) => u.shortName?.trim().toLowerCase() == unit.trim().toLowerCase() || u.unitName?.trim().toLowerCase() == unit.trim().toLowerCase()).firstOrNull;
                if (matchedUnit == null) {
                  matchedUnit = Unit()
                    ..uuid = _uuidGen.v4()
                    ..unitName = unit
                    ..shortName = unit.toUpperCase()
                    ..createdAt = DateTime.now()
                    ..updatedAt = DateTime.now();
                  await isar.writeTxn(() async {
                    matchedUnit!.id = await isar.units.put(matchedUnit!);
                  });
                }
                catalogItem.unit.value = matchedUnit;
                catalogItem.primaryUnitName = matchedUnit.shortName ?? unit;
                await isar.writeTxn(() async {
                  await isar.items.put(catalogItem!);
                  try { await catalogItem!.unit.save(); } catch (_) {}
                });
              }

              // Add purchase quantity to item current stock (converting secondary unit if applicable)
              double qtyInPrimaryUnit = qty;
              final convFactor = catalogItem.conversionFactor ?? 1.0;
              if (convFactor > 1.0 && catalogItem.secondaryUnit != null && catalogItem.secondaryUnit!.isNotEmpty) {
                final uName = unit.trim().toLowerCase();
                final sName = catalogItem.secondaryUnit!.trim().toLowerCase();
                if (uName == sName) {
                  qtyInPrimaryUnit = qty / convFactor;
                }
              }

              catalogItem.currentStock = (catalogItem.currentStock ?? 0.0) + qtyInPrimaryUnit;
              catalogItem.updatedAt = DateTime.now();
              await isar.writeTxn(() async {
                await isar.items.put(catalogItem!);
              });
            }

            final taxable = (qty * rate) - discount;
            final gstAmount = taxable * (gstRatePercent / 100);
            final lineTotal = itemAmt > 0 ? itemAmt : (taxable + gstAmount);

            calcSubtotal += taxable;
            calcTotalGST += gstAmount;

            final pItem = PurchaseItem()
              ..uuid = _uuidGen.v4()
              ..purchaseId = null
              ..purchaseUuid = purchaseUuid
              ..itemId = catalogItem?.id
              ..itemName = itemName
              ..hsnCode = hsn
              ..quantity = qty > 0 ? qty : 1.0
              ..unit = unit.isNotEmpty ? unit : (catalogItem?.primaryUnitName ?? catalogItem?.unit.value?.shortName ?? 'PCS')
              ..rate = rate
              ..discount = discount
              ..taxableAmount = taxable > 0 ? taxable : lineTotal
              ..gstRate = gstRatePercent
              ..gstAmount = gstAmount
              ..totalAmount = lineTotal > 0 ? lineTotal : totalAmount
              ..batchNumber = itemMap['batchNo'] as String?
              ..expiryDate = itemMap['expDate'] as String?
              ..mfgDate = itemMap['mfgDate'] as String?
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

            if (catalogItem != null) {
              pItem.item.value = catalogItem;
            }

            createdItems.add(pItem);
            totalItemsImported++;
          }

          purchase.subtotal = calcSubtotal > 0 ? calcSubtotal : totalAmount;
          purchase.totalGST = calcTotalGST;
          if (purchase.grandTotal == 0.0 && calcSubtotal > 0) {
            purchase.grandTotal = calcSubtotal + calcTotalGST;
          }

          // Save Purchase & PurchaseItems
          await isar.writeTxn(() async {
            purchase.id = await isar.purchases.put(purchase);

            for (var pItem in createdItems) {
              pItem.purchaseId = purchase.id;
              pItem.purchase.value = purchase;
              pItem.id = await isar.purchaseItems.put(pItem);
              try { await pItem.purchase.save(); } catch (_) {}
              purchase.purchaseItems.add(pItem);
            }
            try { await purchase.purchaseItems.save(); } catch (_) {}
          });

          // Enqueue for Sync (Header + All Line Items)
          await isar.writeTxn(() async {
            await isar.syncQueues.put(SyncQueue()
              ..uuid = _uuidGen.v4()
              ..entityType = 'Purchase'
              ..entityId = purchase.id
              ..entityUuid = purchase.uuid
              ..operation = 'Create'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now());

            for (var item in createdItems) {
              await isar.syncQueues.put(SyncQueue()
                ..uuid = _uuidGen.v4()
                ..entityType = 'PurchaseItem'
                ..entityId = item.id
                ..entityUuid = item.uuid
                ..operation = 'Create'
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now());
            }
          });

          totalBillsImported++;
        } catch (rowErr) {
          logger.error('Error importing purchase row $r', rowErr);
          errors.add('Row $r ($partyName): ${rowErr.toString()}');
        }
      }
    } catch (e, stackTrace) {
      logger.error('Failed to parse purchase bills excel file', e, stackTrace);
      errors.add('Failed to parse Excel file: $e');
    }

    return ImportPurchaseResult(
      totalBillsImported: totalBillsImported,
      totalItemsImported: totalItemsImported,
      skippedBills: skippedBills,
      errors: errors,
    );
  }

  // --- Helper Methods ---

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
    if (colIndex < 0 || colIndex >= row.length) return '';
    final cell = row[colIndex];
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  static String _normalizeKey(String raw) {
    if (raw.trim().isEmpty) return '';
    String cleaned = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    cleaned = cleaned.replaceAllMapped(RegExp(r'(^|[a-z])0+([1-9][0-9]*)'), (m) => '${m[1]}${m[2]}');
    return cleaned;
  }

  static String _extractDigits(String raw) {
    if (raw.trim().isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return digits.replaceFirst(RegExp(r'^0+'), '');
  }

  static double _parseDouble(String valStr) {
    if (valStr.isEmpty) return 0.0;
    final cleaned = valStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double _parseDiscountVal(String discStr) {
    if (discStr.isEmpty) return 0.0;
    final match = RegExp(r'^([0-9.]+)\s*\(').firstMatch(discStr);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    final cleaned = discStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static double _parseGstPercent(String gstStr) {
    if (gstStr.isEmpty) return 0.0;
    final cleaned = gstStr.replaceAll(RegExp(r'[^0-9.]'), '');
    final val = double.tryParse(cleaned) ?? 0.0;
    return val > 0 ? val : 0.0;
  }

  static DateTime _parseDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    try {
      final parts = dateStr.split(RegExp(r'[/.-]'));
      if (parts.length == 3) {
        int day, month, year;
        if (parts[0].length == 4) {
          year = int.parse(parts[0]);
          month = int.parse(parts[1]);
          day = int.parse(parts[2]);
        } else {
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
          year = int.parse(parts[2]);
          if (year < 100) year += 2000;
        }
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}
