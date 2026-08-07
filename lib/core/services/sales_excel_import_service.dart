import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/services/purchase_excel_import_service.dart'; // Reuse DuplicateBillAction enum
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';

class ImportSalesResult {
  final int totalInvoicesImported;
  final int totalItemsImported;
  final int skippedInvoices;
  final List<String> errors;

  ImportSalesResult({
    required this.totalInvoicesImported,
    required this.totalItemsImported,
    this.skippedInvoices = 0,
    required this.errors,
  });
}

class SalesExcelImportService {
  static const Uuid _uuidGen = Uuid();

  /// Checks Excel (bytes or pre-decoded object) for invoice numbers that already exist in database
  static Future<List<String>> checkForDuplicateInvoices(
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
      final colS1InvoiceNo = _findCol(s1ColMap, ['invoice number', 'sales invoice number', 'sales invoice no', 'invoice no', 'invoice #', 'bill number', 'bill no', 'bill #', 'voucher number', 'voucher no', 'voucher #', 'ref no', 'ref number', 'no.', 'invoice', 'bill', 'voucher'], 5);

      final existingInvoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
      final existingNumbers = existingInvoices.map((inv) => _normalizeKey(inv.invoiceNumber ?? '')).toSet();

      for (int r = 1; r < headerSheet.rows.length; r++) {
        final row = headerSheet.rows[r];
        if (row.isEmpty) continue;
        final invNo = _getCellValue(row, colS1InvoiceNo).trim();
        if (invNo.isEmpty) continue;

        final norm = _normalizeKey(invNo);
        if (norm.isNotEmpty && existingNumbers.contains(norm)) {
          if (!duplicates.contains(invNo)) {
            duplicates.add(invNo);
          }
        }
      }
    } catch (e) {
      logger.error('Error checking duplicate invoices in excel', e);
    }
    return duplicates;
  }

  /// Generates sample Excel template (.xlsx) with 2 sheets for Sales Invoices Import
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();

    // Sheet 1: Sales Invoices Summary / Header
    final sheet1 = excel['Sheet1'];
    sheet1.appendRow([
      TextCellValue('Date'),
      TextCellValue('Customer Name'),
      TextCellValue('Phone No.'),
      TextCellValue('Customer GST Number'),
      TextCellValue('Sales Order Number'),
      TextCellValue('Invoice Number'),
      TextCellValue('Invoice Type'),
      TextCellValue('Total Amount'),
      TextCellValue('Payment Type'),
      TextCellValue('Paid Amount'),
      TextCellValue('Balance Amount'),
      TextCellValue('Description'),
    ]);

    sheet1.appendRow([
      TextCellValue('13/07/2026'),
      TextCellValue('Shree Krishna Traders'),
      TextCellValue('9876543210'),
      TextCellValue('27AAACS1234A1Z5'),
      TextCellValue('SO-01'),
      TextCellValue('INV-01'),
      TextCellValue('Tax Invoice'),
      DoubleCellValue(18500.00),
      TextCellValue('Cash'),
      DoubleCellValue(18500.00),
      DoubleCellValue(0.00),
      TextCellValue('Direct sales invoice generated'),
    ]);

    sheet1.appendRow([
      TextCellValue('14/07/2026'),
      TextCellValue('Apex Wholesale Pvt Ltd'),
      TextCellValue('9123456789'),
      TextCellValue('27AAACA9876B1Z2'),
      TextCellValue('SO-02'),
      TextCellValue('INV-02'),
      TextCellValue('Tax Invoice'),
      DoubleCellValue(42000.00),
      TextCellValue('Credit'),
      DoubleCellValue(10000.00),
      DoubleCellValue(32000.00),
      TextCellValue('Bulk sale on Net 30 terms'),
    ]);

    // Sheet 2: Item Details
    final sheet2 = excel['Sheet2'];
    sheet2.appendRow([
      TextCellValue('Date'),
      TextCellValue('Customer Name'),
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

    sheet2.appendRow([
      TextCellValue('13/07/2026'),
      TextCellValue('Shree Krishna Traders'),
      TextCellValue('INV-01'),
      TextCellValue('Men Cotton Casual Shirt (Blue)'),
      TextCellValue('KB010526'),
      TextCellValue('11/2026'),
      TextCellValue('05/2026'),
      TextCellValue('ITM-001'),
      TextCellValue('6105'),
      DoubleCellValue(20.0),
      TextCellValue('PCS'),
      DoubleCellValue(850.00),
      TextCellValue('0.00'),
      TextCellValue('5%'),
      DoubleCellValue(17850.00),
    ]);

    sheet2.appendRow([
      TextCellValue('14/07/2026'),
      TextCellValue('Apex Wholesale Pvt Ltd'),
      TextCellValue('INV-02'),
      TextCellValue('Women Designer Kurti'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('ITM-002'),
      TextCellValue('6204'),
      DoubleCellValue(30.0),
      TextCellValue('PCS'),
      DoubleCellValue(1200.00),
      TextCellValue('0.00'),
      TextCellValue('12%'),
      DoubleCellValue(40320.00),
    ]);

    return excel.encode();
  }

  /// Imports Sales Invoices and Line Items from Excel (bytes or pre-decoded Excel object)
  static Future<ImportSalesResult> importSalesInvoicesFromBytes(
    dynamic bytesOrExcel,
    DatabaseService dbService, {
    DuplicateBillAction duplicateAction = DuplicateBillAction.overwrite,
    ImportProgressCallback? onProgress,
  }) async {
    final List<String> errors = [];
    int totalInvoicesImported = 0;
    int totalItemsImported = 0;
    int skippedInvoices = 0;

    try {
      final Excel excel = bytesOrExcel is Excel
          ? bytesOrExcel
          : Excel.decodeBytes(bytesOrExcel as Uint8List);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) {
        return ImportSalesResult(
          totalInvoicesImported: 0,
          totalItemsImported: 0,
          skippedInvoices: 0,
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
        return ImportSalesResult(
          totalInvoicesImported: 0,
          totalItemsImported: 0,
          skippedInvoices: 0,
          errors: ['Could not find Sales Invoice Header worksheet.'],
        );
      }

      final totalHeaderRows = headerSheet.rows.length - 1;

      // Column mapping for Sheet 1
      final s1ColMap = headerSheet.rows.isNotEmpty ? _buildColumnMap(headerSheet.rows[0]) : <String, int>{};

      final colS1Date = _findCol(s1ColMap, ['date', 'invoice date', 'bill date'], 0);
      final colS1Party = _findCol(s1ColMap, ['customer name', 'party name', 'customer', 'party'], 1);
      final colS1Phone = _findCol(s1ColMap, ['phone', 'mobile', 'contact'], 2);
      final colS1Gst = _findCol(s1ColMap, ['customer gst', 'gst number', 'gstin', 'gst'], 3);
      final colS1OrderNo = _findCol(s1ColMap, ['sales order number', 'order number', 'so number'], 4);
      final colS1InvoiceNo = _findCol(s1ColMap, ['invoice number', 'sales invoice number', 'sales invoice no', 'invoice no', 'invoice #', 'bill number', 'bill no', 'bill #', 'voucher number', 'voucher no', 'voucher #', 'ref no', 'ref number', 'no.', 'invoice', 'bill', 'voucher'], 5);
      final colS1InvType = _findCol(s1ColMap, ['invoice type', 'type'], 6);
      final colS1TotalAmt = _findCol(s1ColMap, ['total amount', 'grand total', 'total', 'amount'], 7);
      final colS1PayType = _findCol(s1ColMap, ['payment type', 'payment mode', 'pay mode', 'mode'], 8);
      final colS1PaidAmt = _findCol(s1ColMap, ['paid amount', 'paid'], 9);
      final colS1BalAmt = _findCol(s1ColMap, ['balance amount', 'due amount', 'balance', 'pending'], 10);
      final colS1Desc = _findCol(s1ColMap, ['description', 'remarks', 'notes'], 11);

      // Column mapping for Sheet 2
      final s2ColMap = (itemSheet != null && itemSheet.rows.isNotEmpty) ? _buildColumnMap(itemSheet.rows[0]) : <String, int>{};

      final colS2Date = _findCol(s2ColMap, ['date', 'invoice date', 'bill date'], 0);
      final colS2Party = _findCol(s2ColMap, ['customer name', 'party name', 'customer', 'party'], 1);
      final colS2InvoiceNo = _findCol(s2ColMap, ['invoice number', 'sales invoice number', 'sales invoice no', 'invoice no', 'invoice #', 'bill number', 'bill no', 'bill #', 'voucher number', 'voucher no', 'voucher #', 'ref no', 'ref number', 'no.', 'invoice', 'bill', 'voucher'], 2);
      final colS2ItemName = _findCol(s2ColMap, ['item name', 'product name', 'item', 'product', 'description'], 3);
      final colS2BatchNo = _findCol(s2ColMap, ['batch number', 'batch no', 'batch'], 4);
      final colS2ExpDate = _findCol(s2ColMap, ['expire date', 'exp date', 'expiry'], 5);
      final colS2MfgDate = _findCol(s2ColMap, ['mfg date', 'manufacturing date'], 6);
      final colS2ItemCode = _findCol(s2ColMap, ['item code', 'code', 'barcode'], 7);
      final colS2Hsn = _findCol(s2ColMap, ['hsn/sac', 'hsn', 'sac'], 8);
      final colS2Qty = _findCol(s2ColMap, ['qty', 'quantity', 'count'], 9);
      final colS2Unit = _findCol(s2ColMap, ['unit', 'uom', 'pack'], 10);
      final colS2Rate = _findCol(s2ColMap, ['price per unit', 'selling price', 'sale price', 'rate', 'price'], 11);
      final colS2Disc = _findCol(s2ColMap, ['discount', 'disc'], 12);
      final colS2Gst = _findCol(s2ColMap, ['gst', 'tax rate', 'tax %', 'tax'], 13);
      final colS2Amount = _findCol(s2ColMap, ['amount', 'total', 'line total'], 14);

      // 1. Index Sheet 2 Items strictly by Normalized Invoice Number & Digits
      final Map<String, List<Map<String, dynamic>>> itemsByInvNo = {};
      final Map<String, List<Map<String, dynamic>>> itemsByDigits = {};

      if (itemSheet != null && itemSheet.rows.length > 1) {
        onProgress?.call(0, totalHeaderRows > 0 ? totalHeaderRows : 1, 'Indexing Sheet 2 item line details...');

        String lastSeenInvNo = '';

        for (int r = 1; r < itemSheet.rows.length; r++) {
          final row = itemSheet.rows[r];
          if (row.isEmpty) continue;

          String invNo = _getCellValue(row, colS2InvoiceNo).trim();
          final itemName = _getCellValue(row, colS2ItemName).trim();
          final partyName = _getCellValue(row, colS2Party).trim();
          final dateStr = _getCellValue(row, colS2Date).trim();

          if (itemName.isEmpty) continue;

          // Continuation row inheritance
          if (invNo.isNotEmpty) {
            lastSeenInvNo = invNo;
          } else if (lastSeenInvNo.isNotEmpty) {
            invNo = lastSeenInvNo;
          }

          final itemData = {
            'date': dateStr,
            'partyName': partyName,
            'invNo': invNo,
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

          final normInvNo = _normalizeKey(invNo);
          final digitsInvNo = _extractDigits(invNo);

          if (normInvNo.isNotEmpty) {
            itemsByInvNo.putIfAbsent(normInvNo, () => []).add(itemData);
          }
          if (digitsInvNo.isNotEmpty && digitsInvNo != normInvNo) {
            itemsByDigits.putIfAbsent(digitsInvNo, () => []).add(itemData);
          }
        }
      }

      final allParties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
      final allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();

      // 2. Iterate Sheet 1 Headers & Create / Overwrite Sales Invoices
      for (int r = 1; r < headerSheet.rows.length; r++) {
        final row = headerSheet.rows[r];
        if (row.isEmpty) continue;

        final partyName = _getCellValue(row, colS1Party).trim();
        final invNo = _getCellValue(row, colS1InvoiceNo).trim();

        if (partyName.isEmpty && invNo.isEmpty) continue;

        final effectiveInvNo = invNo.isNotEmpty
            ? invNo
            : 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$r';

        // Notify progress and yield main event loop to prevent browser Not Responding freeze
        onProgress?.call(r, totalHeaderRows, 'Processing invoice "$effectiveInvNo" ($r/$totalHeaderRows)...');
        await Future.delayed(Duration.zero);

        final dateStr = _getCellValue(row, colS1Date);
        final phone = _getCellValue(row, colS1Phone);
        final gstNo = _getCellValue(row, colS1Gst);
        final orderNo = _getCellValue(row, colS1OrderNo);
        final invType = _getCellValue(row, colS1InvType).isNotEmpty ? _getCellValue(row, colS1InvType) : 'Tax Invoice';
        final totalAmount = _parseDouble(_getCellValue(row, colS1TotalAmt));
        final paidAmount = _parseDouble(_getCellValue(row, colS1PaidAmt));
        final balanceAmount = _parseDouble(_getCellValue(row, colS1BalAmt));
        final description = _getCellValue(row, colS1Desc);

        try {
          final normEffInvNoCheck = _normalizeKey(effectiveInvNo);

          // Check if invoice number already exists
          List<Invoice> matchingInvoices = await isar.invoices.filter().invoiceNumberEqualTo(effectiveInvNo).findAll();
          if (matchingInvoices.isEmpty && normEffInvNoCheck.isNotEmpty) {
            final allExisting = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
            matchingInvoices = allExisting.where((inv) => _normalizeKey(inv.invoiceNumber ?? '') == normEffInvNoCheck).toList();
          }

          if (matchingInvoices.isNotEmpty) {
            if (duplicateAction == DuplicateBillAction.skip) {
              skippedInvoices++;
              errors.add('Invoice "$effectiveInvNo" already exists in database (Skipped).');
              continue;
            }

            // DuplicateAction.overwrite: Clean old line items, restore item stock, and purge old invoice
            for (var oldInv in matchingInvoices) {
              final allInvItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
              final oldItems = allInvItems.where((oi) => 
                oi.parentInvoiceId == oldInv.id || 
                (oldInv.uuid != null && oldInv.uuid!.isNotEmpty && oi.parentInvoiceUuid == oldInv.uuid) ||
                oi.invoice.value?.id == oldInv.id
              ).toList();

              await isar.writeTxn(() async {
                for (var oi in oldItems) {
                  if (oi.itemId != null) {
                    final targetItem = await isar.items.get(oi.itemId!);
                    if (targetItem != null) {
                      targetItem.currentStock = (targetItem.currentStock ?? 0.0) + (oi.quantity ?? 0.0);
                      await isar.items.put(targetItem);
                    }
                  }
                  await isar.invoiceItems.delete(oi.id);
                }
                await isar.invoices.delete(oldInv.id);
              });
            }
          }

          // Find or create Customer Party
          Party? party;
          if (partyName.isNotEmpty) {
            party = allParties.where((p) => p.partyName?.trim().toLowerCase() == partyName.toLowerCase()).firstOrNull;
            if (party == null) {
              party = Party()
                ..uuid = _uuidGen.v4()
                ..partyName = partyName
                ..partyCode = 'P-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                ..partyType = 'Customer'
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

          final invoiceUuid = _uuidGen.v4();

          // Create Invoice Record
          final invoice = Invoice()
            ..uuid = invoiceUuid
            ..invoiceNumber = effectiveInvNo
            ..invoiceDate = _parseDate(dateStr)
            ..invoiceType = invType
            ..sourceOrderNumber = orderNo
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
            ..invoiceStatus = paidAmount >= totalAmount && totalAmount > 0 ? 'Paid' : 'Unpaid'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          if (party != null) {
            invoice.party.value = party;
          }

          // Retrieve items matching THIS SPECIFIC INVOICE NUMBER (with fuzzy and single-invoice fallback)
          final normInvNo = _normalizeKey(invNo);
          final digitsInvNo = _extractDigits(invNo);
          final digitsEffCheck = _extractDigits(effectiveInvNo);

          List<Map<String, dynamic>> rawItems = [];
          if (normInvNo.isNotEmpty && itemsByInvNo.containsKey(normInvNo)) {
            rawItems = itemsByInvNo.remove(normInvNo)!;
          } else if (normEffInvNoCheck.isNotEmpty && itemsByInvNo.containsKey(normEffInvNoCheck)) {
            rawItems = itemsByInvNo.remove(normEffInvNoCheck)!;
          } else if (digitsInvNo.isNotEmpty && itemsByDigits.containsKey(digitsInvNo)) {
            rawItems = itemsByDigits.remove(digitsInvNo)!;
          } else if (digitsEffCheck.isNotEmpty && itemsByDigits.containsKey(digitsEffCheck)) {
            rawItems = itemsByDigits.remove(digitsEffCheck)!;
          } else {
            final partyNorm = _normalizeKey(partyName);
            String? matchedKey;
            for (var k in itemsByInvNo.keys) {
              if (itemsByInvNo[k]!.any((i) => (partyNorm.isNotEmpty && _normalizeKey(i['partyName'] as String) == partyNorm) || _normalizeKey(i['invNo'] as String).contains(normInvNo) || (normInvNo.isNotEmpty && _normalizeKey(i['invNo'] as String).contains(normInvNo)))) {
                matchedKey = k;
                break;
              }
            }
            if (matchedKey != null) {
              rawItems = itemsByInvNo.remove(matchedKey)!;
            } else if (totalHeaderRows == 1 && itemsByInvNo.isNotEmpty) {
              rawItems = itemsByInvNo.values.expand((list) => list).toList();
              itemsByInvNo.clear();
            }
          }

          final List<InvoiceItem> createdItems = [];
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
                  ..sellRate = rate
                  ..buyRate = rate > 0 ? (rate * 0.7) : 0.0
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

              // Deduct sales quantity from item current stock (converting secondary unit if applicable)
              double qtyInPrimaryUnit = qty;
              final convFactor = catalogItem.conversionFactor ?? 1.0;
              if (convFactor > 1.0 && catalogItem.secondaryUnit != null && catalogItem.secondaryUnit!.isNotEmpty) {
                final uName = unit.trim().toLowerCase();
                final sName = catalogItem.secondaryUnit!.trim().toLowerCase();
                if (uName == sName) {
                  qtyInPrimaryUnit = qty / convFactor;
                }
              }

              catalogItem.currentStock = (catalogItem.currentStock ?? 0.0) - qtyInPrimaryUnit;
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

            final invItem = InvoiceItem()
              ..uuid = _uuidGen.v4()
              ..parentInvoiceId = null
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
              invItem.item.value = catalogItem;
            }

            createdItems.add(invItem);
            totalItemsImported++;
          }

          invoice.subtotal = calcSubtotal > 0 ? calcSubtotal : totalAmount;
          invoice.totalGST = calcTotalGST;
          if (invoice.grandTotal == 0.0 && calcSubtotal > 0) {
            invoice.grandTotal = calcSubtotal + calcTotalGST;
          }

          // Save Invoice & InvoiceItems
          await isar.writeTxn(() async {
            invoice.id = await isar.invoices.put(invoice);

            for (var invItem in createdItems) {
              invItem.parentInvoiceId = invoice.id;
              invItem.parentInvoiceUuid = invoice.uuid;
              invItem.invoice.value = invoice;
              invItem.id = await isar.invoiceItems.put(invItem);
              try { await invItem.invoice.save(); } catch (_) {}
              invoice.invoiceItems.add(invItem);
            }
            try { await invoice.invoiceItems.save(); } catch (_) {}
          });

          // Enqueue for Sync (Header + All Line Items)
          await isar.writeTxn(() async {
            await isar.syncQueues.put(SyncQueue()
              ..uuid = _uuidGen.v4()
              ..entityType = 'Invoice'
              ..entityId = invoice.id
              ..entityUuid = invoice.uuid
              ..operation = 'Create'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now());

            for (var item in createdItems) {
              await isar.syncQueues.put(SyncQueue()
                ..uuid = _uuidGen.v4()
                ..entityType = 'InvoiceItem'
                ..entityId = item.id
                ..entityUuid = item.uuid
                ..operation = 'Create'
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now());
            }
          });

          totalInvoicesImported++;
        } catch (rowErr) {
          logger.error('Error importing invoice row $r', rowErr);
          errors.add('Row $r ($partyName): ${rowErr.toString()}');
        }
      }
    } catch (e, stackTrace) {
      logger.error('Failed to parse sales invoice excel file', e, stackTrace);
      errors.add('Failed to parse Excel file: $e');
    }

    return ImportSalesResult(
      totalInvoicesImported: totalInvoicesImported,
      totalItemsImported: totalItemsImported,
      skippedInvoices: skippedInvoices,
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
