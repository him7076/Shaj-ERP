import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/core/widgets/import_progress_modal.dart';
import 'package:business_sahaj_erp/core/services/sync_manager.dart';

class ImportExpenseResult {
  final int totalExpensesImported;
  final List<String> errors;

  ImportExpenseResult({
    required this.totalExpensesImported,
    required this.errors,
  });
}

class ExpenseExcelImportService {
  /// Generates sample Excel template (.xlsx) for Expenses import
  static List<int>? generateSampleTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header Row
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Expense Category'),
      TextCellValue('Amount (₹)'),
      TextCellValue('Payment Mode'),
      TextCellValue('Paid Through / Account'),
      TextCellValue('Reference No'),
      TextCellValue('Remarks / Notes'),
    ]);

    // Sample Rows
    sheet.appendRow([
      TextCellValue('19-08-2026'),
      TextCellValue('Rent'),
      DoubleCellValue(15000.00),
      TextCellValue('Bank Transfer'),
      TextCellValue('HDFC Bank Main'),
      TextCellValue('REF-8801'),
      TextCellValue('Office premises monthly rent payment'),
    ]);

    sheet.appendRow([
      TextCellValue('19-08-2026'),
      TextCellValue('Tea & Snacks'),
      DoubleCellValue(450.00),
      TextCellValue('Cash'),
      TextCellValue('Main Cash'),
      TextCellValue('REF-8802'),
      TextCellValue('Staff daily tea and snacks expense'),
    ]);

    return excel.encode();
  }

  /// Imports Operating Expenses supporting flexible Excel column headers
  static Future<ImportExpenseResult> importExpensesFromBytes(
    Uint8List bytes,
    DatabaseService dbService, {
    ImportProgressCallback? onProgress,
  }) async {
    final List<String> errors = [];
    int totalExpensesImported = 0;

    try {
      final excel = Excel.decodeBytes(bytes);
      final isar = dbService.isar;

      final sheetKeys = excel.tables.keys.toList();
      if (sheetKeys.isEmpty) {
        return ImportExpenseResult(
          totalExpensesImported: 0,
          errors: ['The selected Excel file contains no worksheets.'],
        );
      }

      final Sheet? sheet = excel.tables['Sheet1'] ?? excel.tables[sheetKeys.first];
      if (sheet == null || sheet.rows.length <= 1) {
        return ImportExpenseResult(
          totalExpensesImported: 0,
          errors: ['The Excel worksheet contains no data rows.'],
        );
      }

      final totalRows = sheet.rows.length - 1;
      final colMap = _buildColumnMap(sheet.rows[0]);

      final colDate = _findCol(colMap, ['date', 'expense date', 'voucher date'], 0);
      final colCategory = _findCol(colMap, ['expense category', 'category', 'type', 'head'], 1);
      final colAmount = _findCol(colMap, ['amount (₹)', 'amount', 'total amount', 'outflow'], 2);
      final colMode = _findCol(colMap, ['payment mode', 'mode', 'payment type'], 3);
      final colPaidThrough = _findCol(colMap, ['paid through / account', 'paid through', 'account', 'bank'], 4);
      final colRef = _findCol(colMap, ['reference no', 'ref no', 'voucher no', 'bill no'], 5);
      final colRemarks = _findCol(colMap, ['remarks / notes', 'remarks', 'notes', 'description'], 6);

      for (int r = 1; r < sheet.rows.length; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        final categoryStr = _getCellValue(row, colCategory).trim();
        final rawAmount = _parseDouble(_getCellValue(row, colAmount));

        if (categoryStr.isEmpty && rawAmount <= 0) continue;

        onProgress?.call(r, totalRows, 'Processing expense row $r/$totalRows...');
        await Future.delayed(Duration.zero);

        final dateStr = _getCellValue(row, colDate).trim();
        final modeStr = _getCellValue(row, colMode).trim();
        final paidThrough = _getCellValue(row, colPaidThrough).trim();
        final refNo = _getCellValue(row, colRef).trim();
        final notesStr = _getCellValue(row, colRemarks).trim();

        DateTime expDate = DateTime.now();
        if (dateStr.isNotEmpty) {
          try {
            final parsed = DateTime.tryParse(dateStr);
            if (parsed != null) {
              expDate = parsed;
            } else {
              final parts = dateStr.split(RegExp(r'[-/]'));
              if (parts.length == 3) {
                final day = int.tryParse(parts[0]) ?? 1;
                final month = int.tryParse(parts[1]) ?? 1;
                final year = int.tryParse(parts[2]) ?? DateTime.now().year;
                expDate = DateTime(year, month, day);
              }
            }
          } catch (_) {}
        }

        final effectiveCategory = categoryStr.isNotEmpty ? categoryStr : 'General Expense';
        final effectiveMode = modeStr.isNotEmpty ? modeStr : 'Cash';
        final combinedRemarks = [
          if (refNo.isNotEmpty) 'Ref: $refNo',
          if (paidThrough.isNotEmpty) 'Paid Via: $paidThrough',
          if (notesStr.isNotEmpty) notesStr,
        ].join(' | ');

        final expense = Expense()
          ..uuid = const Uuid().v4()
          ..category = effectiveCategory
          ..amount = rawAmount
          ..expenseDate = expDate
          ..paymentMode = effectiveMode
          ..remarks = combinedRemarks
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isDeleted = false
          ..isSynced = false;

        try {
          await isar.writeTxn(() async {
            expense.id = await isar.expenses.put(expense);

            final queueItem = SyncQueue()
              ..uuid = const Uuid().v4()
              ..entityType = 'Expense'
              ..entityId = expense.id
              ..entityUuid = expense.uuid
              ..operation = 'Create'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();
            await isar.syncQueues.put(queueItem);
          });

          totalExpensesImported++;
        } catch (expErr) {
          logger.error('Error importing expense row $r', expErr);
          errors.add('Row $r: ${expErr.toString()}');
        }
      }
      SyncManager.triggerUpload();
    } catch (e, stackTrace) {
      logger.error('Failed to parse expense excel file', e, stackTrace);
      errors.add('Failed to parse Excel file: $e');
    }

    return ImportExpenseResult(
      totalExpensesImported: totalExpensesImported,
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
