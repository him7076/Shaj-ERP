import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';
import 'package:business_sahaj_erp/core/services/sync_manager.dart';

class ImportReceiptResult {
  final int totalReceiptsImported;
  final List<String> errors;

  ImportReceiptResult({
    required this.totalReceiptsImported,
    required this.errors,
  });
}

class ReceiptExcelImportService {
  /// Generates sample Excel template (.xlsx) for Receipts (Payment In) import
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header Row
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Party Name'),
      TextCellValue('Amount (₹)'),
      TextCellValue('Payment Mode'),
      TextCellValue('Reference / Cheque No'),
      TextCellValue('Remarks / Notes'),
    ]);

    // Sample Rows
    sheet.appendRow([
      TextCellValue('22-08-2026'),
      TextCellValue('Shri Krishna Traders'),
      DoubleCellValue(12500.00),
      TextCellValue('UPI'),
      TextCellValue('UPI-99201'),
      TextCellValue('Advance payment received for invoice #INV-102'),
    ]);

    sheet.appendRow([
      TextCellValue('22-08-2026'),
      TextCellValue('Radhe Shyam Enterprises'),
      DoubleCellValue(4800.00),
      TextCellValue('Cash'),
      TextCellValue('CASH-001'),
      TextCellValue('Cleared pending balance'),
    ]);

    return excel.encode();
  }

  /// Imports Receipts (Payment In) supporting flexible Excel column headers
  static Future<ImportReceiptResult> importReceiptsFromBytes(
    Uint8List bytes,
    DatabaseService dbService, {
    ImportProgressCallback? onProgress,
  }) async {
    final List<String> errors = [];
    int totalReceiptsImported = 0;

    try {
      final excel = Excel.decodeBytes(bytes);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) {
        return ImportReceiptResult(
          totalReceiptsImported: 0,
          errors: ['The selected Excel file contains no worksheets.'],
        );
      }

      final Sheet? sheet = excel.tables['Sheet1'] ?? excel.tables[sheetKeys.first];
      if (sheet == null || sheet.rows.length <= 1) {
        return ImportReceiptResult(
          totalReceiptsImported: 0,
          errors: ['The Excel worksheet contains no data rows.'],
        );
      }

      final totalRows = sheet.rows.length - 1;
      final colMap = _buildColumnMap(sheet.rows[0]);

      final colDate = _findCol(colMap, ['date', 'receipt date', 'voucher date'], 0);
      final colParty = _findCol(colMap, ['party name', 'customer', 'party', 'received from'], 1);
      final colAmount = _findCol(colMap, ['amount (₹)', 'amount', 'total amount', 'received amount', 'inflow'], 2);
      final colMode = _findCol(colMap, ['payment mode', 'mode', 'payment type'], 3);
      final colRef = _findCol(colMap, ['reference / cheque no', 'reference no', 'ref no', 'cheque no', 'upi id'], 4);
      final colRemarks = _findCol(colMap, ['remarks / notes', 'remarks', 'notes', 'description'], 5);

      final allParties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
      final Map<String, Party> partyLookup = {
        for (var p in allParties)
          if (p.partyName != null) p.partyName!.trim().toLowerCase(): p
      };

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        final partyNameStr = _getCellValue(row, colParty).trim();
        final rawAmount = _parseDouble(_getCellValue(row, colAmount));

        if (partyNameStr.isEmpty && rawAmount <= 0) continue;

        onProgress?.call(r, totalRows, 'Processing receipt row $r/$totalRows...');
        await Future.delayed(Duration.zero);

        final dateStr = _getCellValue(row, colDate).trim();
        final modeStr = _getCellValue(row, colMode).trim();
        final refNo = _getCellValue(row, colRef).trim();
        final notesStr = _getCellValue(row, colRemarks).trim();

        DateTime receiptDate = DateTime.now();
        if (dateStr.isNotEmpty) {
          try {
            final parsed = DateTime.tryParse(dateStr);
            if (parsed != null) {
              receiptDate = parsed;
            } else {
              final parts = dateStr.split(RegExp(r'[-/]'));
              if (parts.length == 3) {
                final day = int.tryParse(parts[0]) ?? 1;
                final month = int.tryParse(parts[1]) ?? 1;
                final year = int.tryParse(parts[2]) ?? DateTime.now().year;
                receiptDate = DateTime(year, month, day);
              }
            }
          } catch (_) {}
        }

        final effectivePartyName = partyNameStr.isNotEmpty ? partyNameStr : 'General Customer';
        final effectiveMode = modeStr.isNotEmpty ? modeStr : 'Cash';

        // Check if matching party exists
        Party? matchedParty = partyLookup[effectivePartyName.toLowerCase()];
        if (matchedParty == null) {
          // Auto-create customer party
          matchedParty = Party()
            ..uuid = const Uuid().v4()
            ..partyName = effectivePartyName
            ..partyType = 'Customer'
            ..outstandingBalance = 0.0
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.writeTxn(() async {
            matchedParty!.id = await isar.partys.put(matchedParty!);
          });
          partyLookup[effectivePartyName.toLowerCase()] = matchedParty;
        }

        // Generate receipt transaction number REC-YYYYMMDD-XXX
        final timestampStr = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        final txnNum = 'REC-$timestampStr-$r';

        final txn = Transaction()
          ..uuid = const Uuid().v4()
          ..transactionNumber = txnNum
          ..transactionDate = receiptDate
          ..partyName = effectivePartyName
          ..partyUuid = matchedParty.uuid
          ..transactionType = 'Receipt'
          ..amount = rawAmount
          ..paymentMode = effectiveMode
          ..paymentStatus = 'Paid'
          ..referenceNumber = refNo.isNotEmpty ? refNo : null
          ..remarks = notesStr.isNotEmpty ? notesStr : null
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isDeleted = false
          ..isSynced = false;

        try {
          await isar.writeTxn(() async {
            txn.id = await isar.transactions.put(txn);

            // Reduce Party Outstanding Balance for receipt payment received
            matchedParty!.outstandingBalance = (matchedParty.outstandingBalance ?? 0.0) - rawAmount;
            matchedParty.updatedAt = DateTime.now();
            await isar.partys.put(matchedParty);

            final queueItem = SyncQueue()
              ..uuid = const Uuid().v4()
              ..entityType = 'Transaction'
              ..entityId = txn.id
              ..entityUuid = txn.uuid
              ..operation = 'Create'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();
            await isar.syncQueues.put(queueItem);
          });

          totalReceiptsImported++;
        } catch (expErr) {
          logger.error('Error importing receipt row $r', expErr);
          errors.add('Row $r: ${expErr.toString()}');
        }
      }
      SyncManager.triggerUpload();
    } catch (e, stackTrace) {
      logger.error('Failed to parse receipt excel file', e, stackTrace);
      errors.add('Failed to parse Excel file: $e');
    }

    return ImportReceiptResult(
      totalReceiptsImported: totalReceiptsImported,
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
}
