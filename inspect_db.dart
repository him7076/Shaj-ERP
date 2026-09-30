import 'dart:io';
import 'package:isar/isar.dart';
import 'lib/core/services/database_service.dart';
import 'lib/data/local/collections/invoice_collection.dart';
import 'lib/data/local/collections/invoice_item_collection.dart';
import 'lib/data/local/collections/transaction_collection.dart';
import 'lib/data/local/collections/party_collection.dart';
import 'lib/data/local/collections/item_collection.dart';
import 'lib/data/local/collections/unit_collection.dart';
import 'lib/data/local/collections/order_collection.dart';
import 'lib/data/local/collections/order_item_collection.dart';
import 'lib/data/local/collections/purchase_collection.dart';
import 'lib/data/local/collections/purchase_item_collection.dart';
import 'lib/data/local/collections/expense_collection.dart';
import 'lib/data/local/collections/expense_item_collection.dart';
import 'lib/data/local/collections/category_collection.dart';
import 'lib/data/local/collections/brand_collection.dart';
import 'lib/data/local/collections/settings_collection.dart';
import 'lib/data/local/collections/user_collection.dart';
import 'lib/data/local/collections/sync_queue_collection.dart';
import 'lib/data/local/collections/bank_account_collection.dart';
import 'lib/data/local/collections/credit_note_collection.dart';
import 'lib/data/local/collections/credit_note_item_collection.dart';
import 'lib/data/local/collections/debit_note_collection.dart';
import 'lib/data/local/collections/debit_note_item_collection.dart';
import 'lib/data/local/collections/deleted_voucher_collection.dart';
import 'lib/data/local/collections/stock_adjustment_collection.dart';
import 'lib/data/local/collections/whatsapp_mapping_collection.dart';
import 'lib/data/local/collections/machinery_collection.dart';
import 'lib/data/local/collections/machinery_category_collection.dart';
import 'lib/data/local/collections/task_collection.dart';


void main() async {
  await Isar.initializeIsarCore(download: true);
  final isar = await Isar.open(
          [
            CategorySchema,
            UnitSchema,
            BrandSchema,
            PartySchema,
            ItemSchema,
            OrderItemSchema,
            OrderSchema,
            InvoiceItemSchema,
            InvoiceSchema,
            SettingsSchema,
            UserSchema,
            SyncQueueSchema,
            PurchaseSchema,
            PurchaseItemSchema,
            ExpenseSchema,
            ExpenseItemSchema,
            TransactionSchema,
            BankAccountSchema,
            CreditNoteSchema,
            CreditNoteItemSchema,
            DebitNoteSchema,
            DebitNoteItemSchema,
            DeletedVoucherSchema,
            StockAdjustmentSchema,
            WhatsAppMappingSchema,
            MachinerySchema,
            MachineryCategorySchema,
            TaskSchema,
          ], directory: 'C:/Users/lenovo/Desktop/Shaj ERP');
  
  final invoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
  for (var inv in invoices) {
    if (inv.paymentMode != null && inv.paymentMode!.toLowerCase().contains('cash')) {
      if ((inv.paidAmount ?? 0.0) > 0) {
        print('INV: ${inv.invoiceNumber}, mode: ${inv.paymentMode}, paid: ${inv.paidAmount}, total: ${inv.grandTotal}, uuid: ${inv.uuid}');
      }
    }
  }
  
  final txns = await isar.transactions.filter().isDeletedEqualTo(false).findAll();
  for (var t in txns) {
     if (t.linkedBillUuid != null && t.linkedBillUuid!.isNotEmpty) {
       print('TXN: ${t.transactionNumber}, type: ${t.transactionType}, mode: ${t.paymentMode}, amt: ${t.amount}, linked: ${t.linkedBillUuid}');
     }
  }
  exit(0);
}
