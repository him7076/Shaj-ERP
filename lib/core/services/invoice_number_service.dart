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
  Future<String> generateNextInvoiceNumber({bool isFixedAsset = false}) async {
    try {
      final prefix = isFixedAsset ? 'FA-INV-' : 'INV-';
      final allInvoices = await isar.invoices.where().findAll();
      int maxNum = 0;
      final reg = isFixedAsset 
          ? RegExp(r'^FA-INV-(\d+)$', caseSensitive: false)
          : RegExp(r'^INV-(\d+)$', caseSensitive: false);

      for (var inv in allInvoices) {
        if (inv.isDeleted == true) continue;
        final numStr = inv.invoiceNumber?.trim() ?? '';
        if (numStr.isNotEmpty) {
          if (!isFixedAsset && numStr.toUpperCase().startsWith('FA-')) continue;
          final match = reg.firstMatch(numStr);
          if (match != null) {
            final parsed = int.tryParse(match.group(1)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }
        }
      }
      var nextNum = maxNum + 1;
      var candidate = '$prefix${nextNum.toString().padLeft(2, '0')}';
      final existingNumbers = allInvoices.where((e) => e.isDeleted != true).map((e) => e.invoiceNumber).toSet();
      while (existingNumbers.contains(candidate)) {
        nextNum++;
        candidate = '$prefix${nextNum.toString().padLeft(2, '0')}';
      }
      logger.debug('Generated next invoice number: $candidate');
      return candidate;
    } catch (e) {
      throw InvoiceException('Failed to generate next invoice number: $e');
    }
  }
}
