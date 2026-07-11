import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class InvoiceNumberService {
  final Isar isar;

  InvoiceNumberService(this.isar);

  /// Returns financial year prefix based on Indian FY calendar (April 1 - March 31)
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

  /// Generates the next sequential unique Invoice Number (e.g. 2026-27/INV000001)
  Future<String> generateNextInvoiceNumber() async {
    try {
      final prefix = getFinancialYearPrefix(DateTime.now());
      final queryPrefix = '$prefix/INV';

      // Find last invoice generated in this financial year
      final lastInvoice = await isar.invoices
          .filter()
          .invoiceNumberStartsWith(queryPrefix)
          .sortByInvoiceNumberDesc()
          .findFirst();

      if (lastInvoice == null || lastInvoice.invoiceNumber == null) {
        return '$queryPrefix${1.toString().padLeft(6, '0')}';
      }

      final lastCode = lastInvoice.invoiceNumber!;
      final parts = lastCode.split('/INV');
      if (parts.length < 2) {
        return '$queryPrefix${1.toString().padLeft(6, '0')}';
      }

      final numStr = parts[1];
      final currentNum = int.tryParse(numStr) ?? 0;
      final nextNum = currentNum + 1;

      final nextCode = '$queryPrefix${nextNum.toString().padLeft(6, '0')}';
      logger.debug('Generated next invoice number: $nextCode (previous: $lastCode)');
      return nextCode;
    } catch (e) {
      throw InvoiceException('Failed to generate next invoice number: $e');
    }
  }
}
