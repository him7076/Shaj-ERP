import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'base_repository.dart';

abstract class InvoiceRepository implements BaseRepository<Invoice> {
  /// Searches invoices by matching invoice number, party name, mobile, or GST
  Future<List<Invoice>> searchInvoices(String query);

  /// Generates the next unique sequential Invoice Number prefixed by Financial Year (e.g. 2026-27/INV000001)
  Future<String> generateNextInvoiceNumber();

  /// Saves or updates a direct sales invoice along with its items transactionally,
  /// updating stock balances and outstanding balances.
  Future<void> saveInvoice(Invoice invoice, List<InvoiceItem> items);

  /// Cancels an invoice, restoring stock and adjusting outstanding balance
  Future<void> cancelInvoice(String invoiceUuid, String reason, String user);

  /// Converts an existing order into a sales invoice transactionally, locking the order
  Future<Invoice> convertOrderToInvoice({
    required String orderUuid,
    required String invoiceType,
    required double paidAmount,
    required DateTime dueDate,
    required String user,
  });
}
