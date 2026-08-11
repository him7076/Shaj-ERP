import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class InvoiceNumberService {
  final Isar isar;

  InvoiceNumberService(this.isar);

  String getFinancialYearPrefix(DateTime date) {
    final year = date.year;
    final month = date.month;
    if (month >= 4) {
      final nextYearShort = (year + 1) % 100;
      return '$year-${nextYearShort.toString().padLeft(2, '0')}';
    } else {
      final prevYear = year - 1;
      final currentYearShort = year % 100;
      return '$prevYear-${currentYearShort.toString().padLeft(2, '0')}';
    }
  }

  /// Generates the next sequential unique Invoice Number (e.g. INV-01, INV-02)
  Future<String> generateNextInvoiceNumber() async {
    try {
      final allInvoices = await isar.invoices.where().findAll();
      int maxNum = 0;
      for (var inv in allInvoices) {
        if (inv.invoiceNumber != null) {
          final match = RegExp(r'\d+').firstMatch(inv.invoiceNumber!);
          if (match != null) {
            final parsed = int.tryParse(match.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      final nextNum = maxNum + 1;
      final numStr = nextNum.toString().padLeft(2, '0');
      final nextCode = 'INV-$numStr';
      logger.debug('Generated next invoice number: $nextCode');
      return nextCode;
    } catch (e) {
      throw InvoiceException('Failed to generate next invoice number: $e');
    }
  }
}
