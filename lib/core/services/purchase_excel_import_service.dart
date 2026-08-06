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
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/services/sales_excel_import_service.dart'; // Reuse ImportProgressCallback

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
  static final Uuid _uuidGen = const Uuid();

  /// Checks Excel bytes for bill numbers that already exist in database
  static Future<List<String>> checkForDuplicateBills(
    Uint8List bytes,
    DatabaseService dbService,
  ) async {
    final List<String> duplicates = [];
    try {
      final excel = Excel.decodeBytes(bytes);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) return duplicates;

      final Sheet? headerSheet = excel.tables['Sheet1'] ?? excel.tables[sheetKeys.first];
      if (headerSheet == null || headerSheet.rows.length <= 1) return duplicates;

      final s1ColMap = _buildColumnMap(headerSheet.rows[0]);
      final colS1BillNo = _findCol(s1ColMap, ['invoice number', 'bill number', 'purchase bill number', 'purchase bill no', 'bill no', 'invoice no', 'invoice'], 5);

      final existingPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final existingNumbers = existingPurchases.map((p) => _normalizeKey(p.purchaseNumber ?? '')).toSet();

      for (int r = 1; r < headerSheet.rows.length; r++) {
        final row = headerSheet.rows[r];
        if (row.isEmpty) continue;
        final billNo = _getCellValue(row, colS1BillNo).trim();
        if (billNo.isEmpty) continue;

        final norm = _normalizeKey(billNo);
        if (norm.isNotEmpty && existingNumbers.contains(norm)) {
          if (!duplicates.contains(billNo)) {
            duplicates.add(billNo);
          }
        }
      }
    } catch (e) {
      logger.error('Error checking duplicate bills in excel', e);
    }
    return duplicates;
  }

  /// Generates sample Excel template (.xlsx) with 2 sheets
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();

    // Sheet 1: Purchases Summary / Header
    final sheet1 = excel['Sheet1'];
    sheet1.appendRow([
      TextCellValue('Date'),
      TextCellValue('Party Name'),
      TextCellValue('Phone No.'),
      TextCellValue('Party GST Number'),
      TextCellValue('Order Number'),
      TextCellValue('Bill Number/Invoice Number'),
      TextCellValue('Transaction Type'),
      TextCellValue('Total Amount'),
      TextCellValue('Payment Type'),
      TextCellValue('Paid Amount'),
      TextCellValue('Balance Amount'),
      TextCellValue('Description'),
    ]);

    // Sample Rows for Sheet 1
    sheet1.appendRow([
      TextCellValue('13/07/2026'),
      TextCellValue('PROSOURICNG INTERNATIONAL LLP'),
      TextCellValue(''),
      TextCellValue('24ABEFP1587E1ZB'),
      TextCellValue('PU-01'),
      TextCellValue('PU-01'),
      TextCellValue('Purchase'),
      DoubleCellValue(164220.33),
      TextCellValue('Cash'),
      DoubleCellValue(0.00),
      DoubleCellValue(164220.33),
      TextCellValue('Received stock batch'),
    ]);

    sheet1.appendRow([
      TextCellValue('11/07/2026'),
      TextCellValue('PROSOURICNG INTERNATIONAL LLP'),
      TextCellValue(''),
      TextCellValue('24ABEFP1587E1ZB'),
      TextCellValue('PU-02'),
      TextCellValue('PU-02'),
      TextCellValue('Purchase'),
      DoubleCellValue(216623.14),
      TextCellValue('Cash'),
      DoubleCellValue(0.00),
      DoubleCellValue(216623.14),
      TextCellValue('Stock received from halol depo'),
    ]);

    // Sheet 2: Item Details
    final sheet2 = excel['Sheet2'];
    sheet2.appendRow([
      TextCellValue('Date'),
      TextCellValue('Party Name'),
      TextCellValue('Invoice Number'),
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

    // Sample Rows for Sheet 2
    sheet2.appendRow([
      TextCellValue('13/07/2026'),
      TextCellValue('PROSOURICNG INTERNATIONAL LLP'),
      TextCellValue('PU-01'),
      TextCellValue('Item A'),
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
      DoubleCellValue(164220.00),
    ]);

    return excel.encode();
  }

  /// Imports Purchase Bills and Line Items from decoded Excel bytes with Progress Callback
  static Future<ImportPurchaseResult> importPurchaseBillsFromBytes(
    Uint8List bytes,
    DatabaseService dbService, {
    DuplicateBillAction duplicateAction = DuplicateBillAction.overwrite,
    ImportProgressCallback? onProgress,
  }) async {
    final List<String> errors = [];
    int totalBillsImported = 0;
    int totalItemsImported = 0;
    int skippedBills = 0;

    try {
      final excel = Excel.decodeBytes(bytes);
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

      final s1ColMap = headerSheet.rows.isNotEmpty ? _buildColumnMap(headerSheet.rows[0]) : <String, int>{};

      final colS1Date = _findCol(s1ColMap, ['date', 'bill date', 'invoice date'], 0);
      final colS1Party = _findCol(s1ColMap, ['party name', 'supplier name', 'supplier', 'party'], 1);
      final colS1Phone = _findCol(s1ColMap, ['phone', 'mobile', 'contact'], 2);
      final colS1Gst = _findCol(s1ColMap, ['party gst', 'gst number', 'gstin', 'gst'], 3);
      final colS1OrderNo = _findCol(s1ColMap, ['order number', 'po number'], 4);
      final colS1BillNo = _findCol(s1ColMap, ['bill number', 'invoice number', 'purchase bill number', 'bill no', 'invoice no'], 5);
      final colS1TotalAmt = _findCol(s1ColMap, ['total amount', 'grand total', 'total', 'amount'], 7);
      final colS1PaidAmt = _findCol(s1ColMap, ['paid amount', 'paid'], 9);
      final colS1BalAmt = _findCol(s1ColMap, ['balance amount', 'due amount', 'balance', 'pending'], 10);
      final colS1Desc = _findCol(s1ColMap, ['description', 'remarks', 'notes'], 11);

      final s2ColMap = (itemSheet != null && itemSheet.rows.isNotEmpty) ? _buildColumnMap(itemSheet.rows[0]) : <String, int>{};

      final colS2Date = _findCol(s2ColMap, ['date', 'bill date', 'invoice date'], 0);
      final colS2Party = _findCol(s2ColMap, ['party name', 'supplier name', 'party'], 1);
      final colS2BillNo = _findCol(s2ColMap, ['invoice number', 'bill number', 'invoice no', 'bill no'], 2);
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

      // Index Sheet 2 Items by Normalized Bill Number & Combo Key
      final Map<String, List<Map<String, dynamic>>> itemsByBillNo = {};
      final Map<String, List<Map<String, dynamic>>> itemsByComboKey = {};

      if (itemSheet != null && itemSheet.rows.length > 1) {
        onProgress?.call(0, totalHeaderRows > 0 ? totalHeaderRows : 1, 'Indexing Sheet 2 item details...');

        for (int r = 1; r < itemSheet.rows.length; r++) {
          final row = itemSheet.rows[r];
          if (row.isEmpty) continue;

          final billNo = _getCellValue(row, colS2BillNo).trim();
          final itemName = _getCellValue(row, colS2ItemName).trim();
          final partyName = _getCellValue(row, colS2Party).trim();
          final dateStr = _getCellValue(row, colS2Date).trim();

          if (itemName.isEmpty) continue;

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
          final normCombo = (partyName.isNotEmpty && dateStr.isNotEmpty) ? _normalizeKey('${partyName}_$dateStr') : '';

          if (normBillNo.isNotEmpty) {
            itemsByBillNo.putIfAbsent(normBillNo, () => []).add(itemData);
          }
          if (normCombo.isNotEmpty) {
            itemsByComboKey.putIfAbsent(normCombo, () => []).add(itemData);
          }
        }
      }

      final allParties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
      final allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();

      // Iterate Sheet 1 Headers
      for (int r = 1; r < headerSheet.rows.length; r++) {
        final row = headerSheet.rows[r];
        if (row.isEmpty) continue;

        final partyName = _getCellValue(row, colS1Party).trim();
        final billNo = _getCellValue(row, colS1BillNo).trim();

        if (partyName.isEmpty && billNo.isEmpty) continue;

        final effectiveBillNo = billNo.isNotEmpty
            ? billNo
            : 'PU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$r';

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
          final normEffBillNoCheck = _normalizeKey(effectiveBillNo);

          List<Purchase> matchingPurchases = await isar.purchases.filter().purchaseNumberEqualTo(effectiveBillNo).findAll();
          if (matchingPurchases.isEmpty && normEffBillNoCheck.isNotEmpty) {
            final allExisting = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
            matchingPurchases = allExisting.where((p) => _normalizeKey(p.purchaseNumber ?? '') == normEffBillNoCheck).toList();
          }

          if (matchingPurchases.isNotEmpty) {
            if (duplicateAction == DuplicateBillAction.skip) {
              skippedBills++;
              errors.add('Purchase Bill "$effectiveBillNo" already exists in database (Skipped).');
              continue;
            }

            // DuplicateAction.overwrite: Clean old line items and purge old purchase
            for (var oldPur in matchingPurchases) {
              final oldItems = await isar.purchaseItems
                  .filter()
                  .purchaseIdEqualTo(oldPur.id)
                  .findAll();

              await isar.writeTxn(() async {
                for (var pi in oldItems) {
                  if (pi.itemId != null) {
                    final targetItem = await isar.items.get(pi.itemId!);
                    if (targetItem != null) {
                      targetItem.currentStock = (targetItem.currentStock ?? 0.0) - (pi.quantity ?? 0.0);
                      await isar.items.put(targetItem);
                    }
                  }
                  await isar.purchaseItems.delete(pi.id);
                }
                await isar.purchases.delete(oldPur.id);
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

          final purchase = Purchase()
            ..uuid = purchaseUuid
            ..purchaseNumber = effectiveBillNo
            ..purchaseDate = _parseDate(dateStr)
            ..partyId = party?.id
            ..partyName = partyName
            ..gstNumber = gstNo
            ..remarks = description.isNotEmpty ? description : 'Imported via Excel (Order: $orderNo)'
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

          final normBillNo = _normalizeKey(billNo);
          final normCombo = (partyName.isNotEmpty && dateStr.isNotEmpty) ? _normalizeKey('${partyName}_$dateStr') : '';

          List<Map<String, dynamic>> rawItems = [];
          if (normBillNo.isNotEmpty && itemsByBillNo.containsKey(normBillNo)) {
            rawItems = itemsByBillNo[normBillNo]!;
          } else if (normEffBillNoCheck.isNotEmpty && itemsByBillNo.containsKey(normEffBillNoCheck)) {
            rawItems = itemsByBillNo[normEffBillNoCheck]!;
          } else if (normCombo.isNotEmpty && itemsByComboKey.containsKey(normCombo)) {
            rawItems = itemsByComboKey[normCombo]!;
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
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now();

                await isar.writeTxn(() async {
                  catalogItem!.id = await isar.items.put(catalogItem!);
                });
                allItems.add(catalogItem!);
              }

              // Add purchased quantity to current stock
              catalogItem.currentStock = (catalogItem.currentStock ?? 0.0) + qty;
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
              ..unit = unit
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

          // Enqueue for Sync
          final queueItem = SyncQueue()
            ..uuid = _uuidGen.v4()
            ..entityType = 'Purchase'
            ..entityId = purchase.id
            ..entityUuid = purchase.uuid
            ..operation = 'Create'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          await isar.writeTxn(() async {
            await isar.syncQueues.put(queueItem);
          });

          totalBillsImported++;
        } catch (rowErr) {
          logger.error('Error importing purchase bill row $r', rowErr);
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
