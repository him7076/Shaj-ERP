import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/core/services/database_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService();
  await dbService.init();
  final isar = dbService.isar;

  final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
  int count = 0;
  for (var inv in invoices) {
    if (inv.paidAmount != null && inv.paidAmount! > 0) {
       print('Invoice ${inv.invoiceNumber}: Mode="${inv.paymentMode}", Status="${inv.paymentStatus}", Remarks="${inv.remarks}"');
       count++;
       if (count > 20) break;
    }
  }
}
