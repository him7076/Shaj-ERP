import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.g.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.g.dart';
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
  static const Uuid _uuidGen = Uuid();

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

      // 1. Parse Sheet 2 Items into a Map grouped by Invoice Number
      final Map<String, List<Map<String, dynamic>>> itemsByBillNo = {};
      if (itemSheet != null && itemSheet.rows.length > 1) {
        for (int r = 1; r < itemSheet.rows.length; r++) {
          final row = itemSheet.rows[r];
          if (row.isEmpty) continue;

          final billNo = _getCellValue(row, 2).trim(); // Column C: Invoice Number
          final itemName = _getCellValue(row, 3).trim(); // Column D: Item Name

          if (billNo.isEmpty || itemName.isEmpty) continue;

          final itemData = {
            'date': _getCellValue(row, 0),
            'partyName': _getCellValue(row, 1),
            'billNo': billNo,
            'itemName': itemName,
            'batchNo': _getCellValue(row, 4),
            'expDate': _getCellValue(row, 5),
            'mfgDate': _getCellValue(row, 6),
            'itemCode': _getCellValue(row, 7),
            'hsnCode': _getCellValue(row, 8),
            'qty': _parseDouble(_getCellValue(row, 9)),
            'unit': _getCellValue(row, 10).isNotEmpty ? _getCellValue(row, 10) : 'PCS',
            'rate': _parseDouble(_getCellValue(row, 11)),
            'discount': _parseDouble(_getCellValue(row, 12)),
            'gstStr': _getCellValue(row, 13),
            'amount': _parseDouble(_getCellValue(row, 14)),
          };

          itemsByBillNo.putIfAbsent(billNo, () => []).add(itemData);
        }
      }

      // 2. Parse Sheet 1 Header Bills and create Purchases
      for (int r = 1; r < headerSheet.rows.length; r++) {
        final row = headerSheet.rows[r];
        if (row.isEmpty) continue;

        final partyName = _getCellValue(row, 1).trim(); // Column B: Party Name
        final billNo = _getCellValue(row, 5).trim(); // Column F: Bill Number

        if (partyName.isEmpty && billNo.isEmpty) continue;

        final effectiveBillNo = billNo.isNotEmpty
            ? billNo
            : 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$r';

        final dateStr = _getCellValue(row, 0); // Column A: Date
        final phone = _getCellValue(row, 2); // Column C: Phone No.
        final gstNo = _getCellValue(row, 3); // Column D: Party GST Number
        final orderNo = _getCellValue(row, 4); // Column E: Order Number
        final txnType = _getCellValue(row, 6); // Column G: Transaction Type
        final totalAmount = _parseDouble(_getCellValue(row, 7)); // Column H: Total Amount
        final paymentType = _getCellValue(row, 8); // Column I: Payment Type
        final paidAmount = _parseDouble(_getCellValue(row, 9)); // Column J: Paid Amount
        final balanceAmount = _parseDouble(_getCellValue(row, 10)); // Column K: Balance Amount
        final description = _getCellValue(row, 11); // Column L: Description

        try {
          // Find or create Party
          Party? party;
          if (partyName.isNotEmpty) {
            party = await isar.partys.filter().partyNameEqualTo(partyName).findFirst();
            if (party == null) {
              party = Party()
                ..uuid = const Uuid().v4()
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

          // Create Purchase Record
          final purchase = Purchase()
            ..uuid = const Uuid().v4()
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

          // Get items linked to this bill from Sheet 2
          final rawItems = itemsByBillNo[effectiveBillNo] ?? [];

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
              catalogItem = await isar.items.filter().itemNameEqualTo(itemName).findFirst();
              if (catalogItem == null) {
                catalogItem = Item()
                  ..uuid = const Uuid().v4()
                  ..itemCode = itemCode.isNotEmpty ? itemCode : 'ITM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                  ..itemName = itemName
                  ..hsnCode = hsn
                  ..buyRate = rate
                  ..sellRate = rate * 1.2
                  ..currentStock = qty
                  ..openingStock = qty
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now();

                await isar.writeTxn(() async {
                  catalogItem!.id = await isar.items.put(catalogItem!);
                });
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
              ..uuid = const Uuid().v4()
              ..itemId = catalogItem?.id
              ..itemName = itemName
              ..hsnCode = hsn
              ..quantity = qty
              ..unit = unit
              ..rate = rate
              ..discount = discount
              ..taxableAmount = taxable
              ..gstRate = gstRatePercent
              ..gstAmount = gstAmount
              ..totalAmount = lineTotal
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
            if (party != null) {
              await purchase.party.save();
            }

            for (var pItem in createdItems) {
              pItem.purchase.value = purchase;
              pItem.id = await isar.purchaseItems.put(pItem);
              await pItem.purchase.save();
              if (pItem.item.value != null) {
                await pItem.item.save();
              }
            }
          });

          // Enqueue for Sync
          final queueItem = SyncQueue()
            ..uuid = const Uuid().v4()
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

  static DateTime _parseDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          return DateTime(y, m, d);
        }
      } else if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
    } catch (_) {}
    return DateTime.now();
  }
}
