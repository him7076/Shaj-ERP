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

class ImportPurchaseResult {
  final int totalBillsImported;
  final int totalItemsImported;
  final List<String> errors;

  ImportPurchaseResult({
    required this.totalBillsImported,
    required this.totalItemsImported,
    required this.errors,
  });
}

class PurchaseExcelImportService {
  static final Uuid _uuidGen = Uuid();

  /// Generates the sample Excel template (.xlsx) with 2 sheets as specified
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

    // Sample Row 1 for Sheet 1
    sheet1.appendRow([
      TextCellValue('03/08/2026'),
      TextCellValue('Shree Krishna Traders'),
      TextCellValue('9876543210'),
      TextCellValue('27AAACS1234A1Z5'),
      TextCellValue('PO-2026-01'),
      TextCellValue('PUR-2026-101'),
      TextCellValue('Purchase'),
      DoubleCellValue(14595.00),
      TextCellValue('Cash'),
      DoubleCellValue(14595.00),
      DoubleCellValue(0.00),
      TextCellValue('Raw material stock batch purchase'),
    ]);

    // Sample Row 2 for Sheet 1
    sheet1.appendRow([
      TextCellValue('03/08/2026'),
      TextCellValue('Apex Wholesale Pvt Ltd'),
      TextCellValue('9123456789'),
      TextCellValue('27AAACA9876B1Z2'),
      TextCellValue('PO-2026-02'),
      TextCellValue('PUR-2026-102'),
      TextCellValue('Credit Purchase'),
      DoubleCellValue(25200.00),
      TextCellValue('Credit'),
      DoubleCellValue(0.00),
      DoubleCellValue(25200.00),
      TextCellValue('Apparel goods batch inward'),
    ]);

    // Sheet 2: Item Details
    final sheet2 = excel['Sheet2'];
    sheet2.appendRow([
      TextCellValue('Date'),
      TextCellValue('Party Name'),
      TextCellValue('Invoice Number.'),
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

    // Sample Row 1 for Sheet 2 (Linked to PUR-2026-101)
    sheet2.appendRow([
      TextCellValue('03/08/2026'),
      TextCellValue('Shree Krishna Traders'),
      TextCellValue('PUR-2026-101'),
      TextCellValue('Premium Cotton Fabric'),
      TextCellValue('B-101'),
      TextCellValue('2028-12-31'),
      TextCellValue('2026-01-15'),
      TextCellValue('FAB-001'),
      TextCellValue('5208'),
      DoubleCellValue(20.0),
      TextCellValue('MTR'),
      DoubleCellValue(700.00),
      DoubleCellValue(100.00),
      TextCellValue('5%'),
      DoubleCellValue(14595.00),
    ]);

    // Sample Row 2 for Sheet 2 (Linked to PUR-2026-102)
    sheet2.appendRow([
      TextCellValue('03/08/2026'),
      TextCellValue('Apex Wholesale Pvt Ltd'),
      TextCellValue('PUR-2026-102'),
      TextCellValue('Men Casual Denim Jeans'),
      TextCellValue('B-205'),
      TextCellValue('2030-01-01'),
      TextCellValue('2025-11-20'),
      TextCellValue('JNS-002'),
      TextCellValue('6203'),
      DoubleCellValue(30.0),
      TextCellValue('PCS'),
      DoubleCellValue(800.00),
      DoubleCellValue(0.00),
      TextCellValue('5%'),
      DoubleCellValue(25200.00),
    ]);

    return excel.encode();
  }

  /// Imports Purchase Bills and Purchase Items from decoded Excel bytes
  static Future<ImportPurchaseResult> importPurchasesFromBytes(
    Uint8List bytes,
    DatabaseService dbService,
  ) async {
    final List<String> errors = [];
    int totalBillsImported = 0;
    int totalItemsImported = 0;

    try {
      final excel = Excel.decodeBytes(bytes);
      final isar = dbService.isar;

      // Identify Sheet 1 (Headers) and Sheet 2 (Items)
      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) {
        return ImportPurchaseResult(
          totalBillsImported: 0,
          totalItemsImported: 0,
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
          errors: ['Could not find Purchase Header worksheet.'],
        );
      }

      // Build Header Column Map for Sheet 1
      Map<String, int> s1ColMap = {};
      if (headerSheet.rows.isNotEmpty) {
        s1ColMap = _buildColumnMap(headerSheet.rows[0]);
      }

      final colS1Date = _findCol(s1ColMap, ['date', 'bill date', 'invoice date'], 0);
      final colS1Party = _findCol(s1ColMap, ['party name', 'party', 'supplier name', 'supplier'], 1);
      final colS1Phone = _findCol(s1ColMap, ['phone', 'mobile', 'contact'], 2);
      final colS1Gst = _findCol(s1ColMap, ['party gst', 'gst number', 'gstin', 'gst'], 3);
      final colS1OrderNo = _findCol(s1ColMap, ['order number', 'order no', 'po number'], 4);
      final colS1BillNo = _findCol(s1ColMap, ['invoice number', 'bill number', 'purchase bill number', 'purchase bill no', 'bill no', 'invoice no', 'voucher no', 'invoice #', 'bill #', 'ref no', 'ref', 'reference', 'invoice'], 5);
      final colS1TxnType = _findCol(s1ColMap, ['transaction type', 'txn type', 'type'], 6);
      final colS1TotalAmt = _findCol(s1ColMap, ['total amount', 'grand total', 'total', 'amount'], 7);
      final colS1PayType = _findCol(s1ColMap, ['payment type', 'pay mode', 'mode'], 8);
      final colS1PaidAmt = _findCol(s1ColMap, ['paid amount', 'paid'], 9);
      final colS1BalAmt = _findCol(s1ColMap, ['balance amount', 'balance', 'pending'], 10);
      final colS1Desc = _findCol(s1ColMap, ['description', 'remarks', 'notes'], 11);
      final colS1ItemName = _findCol(s1ColMap, ['item name', 'product name', 'item', 'product'], -1);

      // Build Item Column Map for Sheet 2
      Map<String, int> s2ColMap = {};
      if (itemSheet != null && itemSheet.rows.isNotEmpty) {
        s2ColMap = _buildColumnMap(itemSheet.rows[0]);
      }

      final colS2Date = _findCol(s2ColMap, ['date', 'bill date', 'invoice date'], 0);
      final colS2Party = _findCol(s2ColMap, ['party name', 'party', 'supplier name', 'supplier'], 1);
      final colS2BillNo = _findCol(s2ColMap, ['invoice number', 'bill number', 'purchase bill number', 'purchase bill no', 'bill no', 'invoice no', 'voucher no', 'invoice #', 'bill #', 'ref no', 'ref', 'reference', 'invoice'], 2);
      final colS2ItemName = _findCol(s2ColMap, ['item name', 'product name', 'item', 'product', 'description'], 3);
      final colS2BatchNo = _findCol(s2ColMap, ['batch number', 'batch no', 'batch'], 4);
      final colS2ExpDate = _findCol(s2ColMap, ['expire date', 'exp date', 'expiry'], 5);
      final colS2MfgDate = _findCol(s2ColMap, ['mfg date', 'manufacturing date'], 6);
      final colS2ItemCode = _findCol(s2ColMap, ['item code', 'code', 'barcode'], 7);
      final colS2Hsn = _findCol(s2ColMap, ['hsn/sac', 'hsn', 'sac'], 8);
      final colS2Qty = _findCol(s2ColMap, ['qty', 'quantity', 'count'], 9);
      final colS2Unit = _findCol(s2ColMap, ['unit', 'uom', 'pack'], 10);
      final colS2Rate = _findCol(s2ColMap, ['price per unit', 'purchase price', 'rate', 'unit price', 'price'], 11);
      final colS2Disc = _findCol(s2ColMap, ['discount', 'disc'], 12);
      final colS2Gst = _findCol(s2ColMap, ['gst', 'tax rate', 'tax %', 'tax'], 13);
      final colS2Amount = _findCol(s2ColMap, ['amount', 'total', 'line total'], 14);

      // 1. Parse Sheet 2 Items into Multi-Key Lookup Maps
      final Map<String, List<Map<String, dynamic>>> itemsByBillNo = {};
      final Map<String, List<Map<String, dynamic>>> itemsByComboKey = {};

      if (itemSheet != null && itemSheet.rows.length > 1) {
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
            'discount': _parseDouble(_getCellValue(row, colS2Disc)),
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

      // 2. Parse Sheet 1 Header Bills and create Purchases
      for (int r = 1; r < headerSheet.rows.length; r++) {
        final row = headerSheet.rows[r];
        if (row.isEmpty) continue;

        final partyName = _getCellValue(row, colS1Party).trim();
        final billNo = _getCellValue(row, colS1BillNo).trim();

        if (partyName.isEmpty && billNo.isEmpty) continue;

        final effectiveBillNo = billNo.isNotEmpty
            ? billNo
            : 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$r';

        final dateStr = _getCellValue(row, colS1Date);
        final phone = _getCellValue(row, colS1Phone);
        final gstNo = _getCellValue(row, colS1Gst);
        final orderNo = _getCellValue(row, colS1OrderNo);
        final txnType = _getCellValue(row, colS1TxnType);
        final totalAmount = _parseDouble(_getCellValue(row, colS1TotalAmt));
        final paymentType = _getCellValue(row, colS1PayType);
        final paidAmount = _parseDouble(_getCellValue(row, colS1PaidAmt));
        final balanceAmount = _parseDouble(_getCellValue(row, colS1BalAmt));
        final description = _getCellValue(row, colS1Desc);

        try {
          // Find or create Party
          Party? party;
          if (partyName.isNotEmpty) {
            party = allParties.where((p) => p.partyName?.trim().toLowerCase() == partyName.toLowerCase()).firstOrNull;
            if (party == null) {
              party = Party()
                ..uuid = Uuid().v4()
                ..partyName = partyName
                ..partyCode = 'P-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                ..partyType = 'Supplier'
                ..mobileNumber = phone
                ..gstNumber = gstNo
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now();

              await isar.writeTxn(() async {
                party!.id = await isar.partys.put(party!);
              });
            }
          }

          // Delete existing old purchase bill if re-importing same bill number
          final existingPurchases = await isar.purchases.filter().purchaseNumberEqualTo(effectiveBillNo).findAll();
          for (var oldP in existingPurchases) {
            await isar.writeTxn(() async {
              final oldItems = await isar.purchaseItems
                  .filter()
                  .purchaseUuidEqualTo(oldP.uuid)
                  .or()
                  .purchaseIdEqualTo(oldP.id)
                  .or()
                  .purchase((q) => q.idEqualTo(oldP.id))
                  .findAll();
              for (var oi in oldItems) {
                await isar.purchaseItems.delete(oi.id);
              }
              await isar.purchases.delete(oldP.id);
            });
          }

          // Create Purchase Record
          final purchase = Purchase()
            ..uuid = Uuid().v4()
            ..purchaseNumber = effectiveBillNo
            ..purchaseDate = _parseDate(dateStr)
            ..partyId = party?.id
            ..partyName = partyName
            ..gstNumber = gstNo
            ..remarks = description.isNotEmpty ? '$description (Order: $orderNo, Txn: $txnType)' : 'Imported via Excel'
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

          final List<PurchaseItem> createdItems = [];
          double calcSubtotal = 0.0;
          double calcTotalGST = 0.0;

          // Retrieve items linked to this bill from Sheet 2 using multi-key lookup
          final normBillNo = _normalizeKey(billNo);
          final normEffBillNo = _normalizeKey(effectiveBillNo);
          final normCombo = (partyName.isNotEmpty && dateStr.isNotEmpty) ? _normalizeKey('${partyName}_$dateStr') : '';

          List<Map<String, dynamic>> rawItems = [];
          if (normBillNo.isNotEmpty && itemsByBillNo.containsKey(normBillNo)) {
            rawItems = itemsByBillNo[normBillNo]!;
          } else if (normEffBillNo.isNotEmpty && itemsByBillNo.containsKey(normEffBillNo)) {
            rawItems = itemsByBillNo[normEffBillNo]!;
          } else if (colS2BillNo == -1 && normCombo.isNotEmpty && itemsByComboKey.containsKey(normCombo)) {
            rawItems = itemsByComboKey[normCombo]!;
          }

          // Fallback: If no Sheet 2 items, check if Sheet 1 itself has an Item Name column
          if (rawItems.isEmpty && colS1ItemName != -1) {
            final s1ItemName = _getCellValue(row, colS1ItemName).trim();
            if (s1ItemName.isNotEmpty) {
              rawItems = [{
                'itemName': s1ItemName,
                'itemCode': '',
                'hsnCode': '',
                'qty': 1.0,
                'unit': 'PCS',
                'rate': totalAmount,
                'discount': 0.0,
                'gstStr': '0%',
                'amount': totalAmount,
              }];
            }
          }

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

            // Find or create Item
            Item? catalogItem;
            if (itemName.isNotEmpty) {
              catalogItem = allItems.where((i) => i.itemName?.trim().toLowerCase() == itemName.toLowerCase()).firstOrNull;
              if (catalogItem == null) {
                catalogItem = Item()
                  ..uuid = Uuid().v4()
                  ..itemCode = itemCode.isNotEmpty ? itemCode : 'ITM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                  ..itemName = itemName
                  ..hsnCode = hsn
                  ..buyRate = rate
                  ..sellRate = rate > 0 ? rate * 1.2 : 0.0
                  ..currentStock = qty
                  ..openingStock = qty
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now();

                await isar.writeTxn(() async {
                  catalogItem!.id = await isar.items.put(catalogItem!);
                });
                allItems.add(catalogItem!);
              } else {
                // Update stock level for existing item
                catalogItem.currentStock = (catalogItem.currentStock ?? 0.0) + qty;
                catalogItem.updatedAt = DateTime.now();
                await isar.writeTxn(() async {
                  await isar.items.put(catalogItem!);
                });
              }
            }

            final taxable = (qty * rate) - discount;
            final gstAmount = taxable * (gstRatePercent / 100);
            final lineTotal = itemAmt > 0 ? itemAmt : (taxable + gstAmount);

            calcSubtotal += taxable;
            calcTotalGST += gstAmount;

            final pItem = PurchaseItem()
              ..uuid = Uuid().v4()
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

          // Save Purchase & PurchaseItems in transaction
          await isar.writeTxn(() async {
            purchase.id = await isar.purchases.put(purchase);

            for (var pItem in createdItems) {
              pItem.purchaseId = purchase.id;
              pItem.purchaseUuid = purchase.uuid;
              pItem.purchase.value = purchase;
              pItem.id = await isar.purchaseItems.put(pItem);
              try { await pItem.purchase.save(); } catch (_) {}
              purchase.purchaseItems.add(pItem);
            }
            try { await purchase.purchaseItems.save(); } catch (_) {}
          });

          // Enqueue for Sync
          final queueItem = SyncQueue()
            ..uuid = Uuid().v4()
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
          logger.error('Error importing purchase row $r', rowErr);
          errors.add('Row $r ($partyName): ${rowErr.toString()}');
        }
      }
    } catch (e, stackTrace) {
      logger.error('Failed to parse purchase excel file', e, stackTrace);
      errors.add('Failed to parse Excel file: $e');
    }

    return ImportPurchaseResult(
      totalBillsImported: totalBillsImported,
      totalItemsImported: totalItemsImported,
      errors: errors,
    );
  }

  static String _normalizeKey(String key) {
    if (key.isEmpty) return '';
    var s = key.trim().toLowerCase();
    if (s.endsWith('.0')) {
      s = s.substring(0, s.length - 2);
    }
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static Map<String, int> _buildColumnMap(List<Data?> headerRow) {
    final Map<String, int> colMap = {};
    for (int i = 0; i < headerRow.length; i++) {
      final cellVal = headerRow[i]?.value?.toString().trim().toLowerCase() ?? '';
      if (cellVal.isNotEmpty) {
        colMap[cellVal] = i;
      }
    }
    return colMap;
  }

  static int _findCol(Map<String, int> colMap, List<String> possibleNames, int fallbackIndex) {
    for (var name in possibleNames) {
      final key = name.toLowerCase();
      for (var entry in colMap.entries) {
        if (entry.key == key || entry.key.contains(key)) {
          return entry.value;
        }
      }
    }
    return fallbackIndex;
  }

  static String _getCellValue(List<Data?> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length || row[colIndex] == null) return '';
    final val = row[colIndex]?.value;
    if (val == null) return '';
    String str = val.toString().trim();
    if (str.endsWith('.0')) {
      str = str.substring(0, str.length - 2);
    }
    return str;
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

  static DateTime _parseDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    final clean = dateStr.trim();
    try {
      if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length == 3) {
          int d = int.parse(parts[0]);
          int m = int.parse(parts[1]);
          int y = int.parse(parts[2]);
          if (y < 100) y += 2000;
          return DateTime(y, m, d);
        }
      }
      if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return DateTime.parse(clean);
          } else {
            int d = int.parse(parts[0]);
            int m = int.parse(parts[1]);
            int y = int.parse(parts[2]);
            if (y < 100) y += 2000;
            return DateTime(y, m, d);
          }
        }
      }
      final parsed = DateTime.tryParse(clean);
      if (parsed != null) return parsed;
    } catch (_) {}
    return DateTime.now();
  }
}
