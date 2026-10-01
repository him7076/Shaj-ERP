import 'dart:io';
import 'package:isar/isar.dart';
import 'lib/data/local/collections/transaction_collection.dart';
import 'lib/data/local/collections/invoice_collection.dart';

void main() async {
  await Isar.initializeIsarCore(download: true);
  final isar = await Isar.open([TransactionSchema, InvoiceSchema]);
  
  final txns = await isar.transactions.filter().linkedBillUuidIsNotEmpty().findAll();
  for(var t in txns) {
    if(t.linkedBillUuid != null) {
      print('Txn: \${t.transactionType}, Amt: \${t.amount}, Linked: \${t.linkedBillUuid}');
    }
  }
  
  final invs = await isar.invoices.where().findAll();
  for(var i in invs) {
    if(i.paidAmount != null && i.paidAmount! > 0) {
      print('Inv: \${i.invoiceNumber}, Paid: \${i.paidAmount}, UUID: \${i.uuid}');
    }
  }
}
