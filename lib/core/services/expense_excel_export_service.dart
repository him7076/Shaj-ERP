import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:intl/intl.dart';

class ExpenseExcelExportService {
  static List<int>? exportExpensesToExcel(List<Expense> expenses) {
    final excel = Excel.createExcel();
    final sheet1 = excel['Expenses'];
    excel.setDefaultSheet('Expenses');
    
    // Create Header Row for Sheet 1
    sheet1.appendRow([
      TextCellValue('Date'),
      TextCellValue('Expense Category'),
      TextCellValue('Payee / Party Name'),
      TextCellValue('Amount (₹)'),
      TextCellValue('Payment Mode'),
      TextCellValue('Paid Through / Account'),
      TextCellValue('Reference No'),
      TextCellValue('Remarks / Notes'),
    ]);

    // Create Sheet 2 for Expense Items
    final sheet2 = excel['Expense_Items'];
    sheet2.appendRow([
      TextCellValue('Reference No'),
      TextCellValue('Item Name'),
      TextCellValue('QTY'),
      TextCellValue('Rate'),
      TextCellValue('Tax %'),
      TextCellValue('Amount'),
    ]);

    final dateFormat = DateFormat('dd-MM-yyyy');

    for (var expense in expenses) {
      // Determine the reference number, which we will use to link to Sheet 2
      final refNo = expense.voucherNo ?? _extractRefNoFromRemarks(expense.remarks) ?? 'EXP-${expense.id}';

      sheet1.appendRow([
        TextCellValue(expense.expenseDate != null ? dateFormat.format(expense.expenseDate!) : ''),
        TextCellValue(expense.category ?? ''),
        TextCellValue(expense.partyName ?? ''),
        DoubleCellValue(expense.amount ?? 0.0),
        TextCellValue(expense.paymentMode ?? ''),
        TextCellValue(_extractPaidThroughFromRemarks(expense.remarks) ?? ''),
        TextCellValue(refNo),
        TextCellValue(expense.remarks ?? ''),
      ]);

      // If the expense has items, add them to Sheet 2
      if (expense.itemsJson != null && expense.itemsJson!.isNotEmpty) {
        try {
          final List<dynamic> items = jsonDecode(expense.itemsJson!);
          for (var item in items) {
            sheet2.appendRow([
              TextCellValue(refNo),
              TextCellValue(item['name']?.toString() ?? ''),
              DoubleCellValue(double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0),
              DoubleCellValue(double.tryParse(item['rate']?.toString() ?? '0') ?? 0.0),
              DoubleCellValue(double.tryParse(item['taxPercent']?.toString() ?? '0') ?? 0.0),
              DoubleCellValue(double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0),
            ]);
          }
        } catch (e) {
          // Skip invalid JSON
        }
      }
    }
    
    return excel.encode();
  }

  static String? _extractRefNoFromRemarks(String? remarks) {
    if (remarks == null || remarks.isEmpty) return null;
    final parts = remarks.split('|');
    for (var part in parts) {
      final p = part.trim();
      if (p.startsWith('Ref:')) {
        return p.substring(4).trim();
      }
    }
    return null;
  }

  static String? _extractPaidThroughFromRemarks(String? remarks) {
    if (remarks == null || remarks.isEmpty) return null;
    final parts = remarks.split('|');
    for (var part in parts) {
      final p = part.trim();
      if (p.startsWith('Paid Via:')) {
        return p.substring(9).trim();
      }
    }
    return null;
  }
}
