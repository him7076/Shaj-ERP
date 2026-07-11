import 'package:isar/isar.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/data/local/collections/settings_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/order_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/sync_queue_collection.dart';
import 'package:business_sahaj_erp/domain/repositories/invoice_repository.dart';
import 'package:business_sahaj_erp/data/repositories/base_isar_repository.dart';
import 'package:business_sahaj_erp/core/services/invoice_number_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class InvoiceRepositoryImpl extends BaseIsarRepository<Invoice> implements InvoiceRepository {
  final InvoiceNumberService _numberService;
  final SharedPreferences _prefs;

  InvoiceRepositoryImpl(Isar isar, this._prefs)
      : _numberService = InvoiceNumberService(isar),
        super(isar, 'Invoice');

  @override
  IsarCollection<Invoice> get collection => isar.collection<Invoice>();

  @override
  Future<List<Invoice>> searchInvoices(String query) async {
    if (query.trim().isEmpty) {
      return await getAll();
    }

    try {
      final cleanQuery = query.trim();
      return await collection
          .filter()
          .isDeletedEqualTo(false)
          .and()
          .group((q) => q
              .invoiceNumberContains(cleanQuery, caseSensitive: false)
              .or()
              .partyNameContains(cleanQuery, caseSensitive: false)
              .or()
              .gstNumberContains(cleanQuery, caseSensitive: false))
          .findAll();
    } catch (e) {
      throw DatabaseException('Failed to search invoices: $e');
    }
  }

  @override
  Future<String> generateNextInvoiceNumber() => _numberService.generateNextInvoiceNumber();

  @override
  Future<void> saveInvoice(Invoice invoice, List<InvoiceItem> items) async {
    try {
      final isNew = invoice.id == Isar.autoIncrement;
      invoice.uuid ??= _generateUuid();
      invoice.createdAt = isNew ? DateTime.now() : invoice.createdAt;
      invoice.updatedAt = DateTime.now();
      invoice.isDeleted = false;
      invoice.isSynced = false;
      invoice.version = isNew ? 1 : invoice.version + 1;

      // Calculate Payment Status
      final grandTotal = invoice.grandTotal ?? 0.0;
      final paid = invoice.paidAmount ?? 0.0;
      final pending = grandTotal - paid;
      invoice.pendingAmount = pending < 0 ? 0.0 : pending;

      if (invoice.paidAmount == 0.0) {
        invoice.paymentStatus = 'Unpaid';
      } else if (invoice.pendingAmount! <= 0.0) {
        invoice.paymentStatus = 'Paid';
      } else {
        invoice.paymentStatus = 'Partially Paid';
      }
      invoice.invoiceStatus = invoice.paymentStatus;

      await isar.writeTxn(() async {
        // 1. Put Invoice
        final invoiceId = await collection.put(invoice);
        invoice.id = invoiceId;

        // Load Party link
        await invoice.party.load();
        final party = invoice.party.value;

        // 2. Adjust Party Outstanding Balance (If credit / unpaid exists)
        if (party != null && isNew) {
          final pendingAmt = invoice.pendingAmount ?? 0.0;
          party.outstandingBalance = (party.outstandingBalance ?? 0.0) + pendingAmt;
          await isar.partys.put(party);
        }

        // 3. Clear old items if editing
        if (!isNew) {
          final oldItems = await isar.invoiceItems
              .filter()
              .invoice((q) => q.idEqualTo(invoiceId))
              .findAll();
          
          for (var oldItem in oldItems) {
            oldItem.isDeleted = true;
            oldItem.isSynced = false;
            oldItem.updatedAt = DateTime.now();
            await isar.invoiceItems.put(oldItem);

            // Restore stock back before applying new ones
            if (oldItem.item.value != null) {
              final dbItem = oldItem.item.value!;
              dbItem.currentStock = (dbItem.currentStock ?? 0.0) + (oldItem.quantity ?? 0.0);
              await isar.items.put(dbItem);
            }
          }
        }

        // 4. Put new InvoiceItems & Deduct Stock
        for (var item in items) {
          item.uuid ??= _generateUuid();
          item.createdAt = isNew ? DateTime.now() : item.createdAt;
          item.updatedAt = DateTime.now();
          item.isDeleted = false;
          item.isSynced = false;
          item.version = isNew ? 1 : item.version + 1;

          await isar.invoiceItems.put(item);
          item.invoice.value = invoice;
          await item.invoice.save();

          // Deduct stock levels directly
          if (item.item.value != null) {
            final dbItem = item.item.value!;
            final double available = dbItem.currentStock ?? 0.0;
            final double requested = item.quantity ?? 0.0;

            if (available < requested) {
              throw StockException('Insufficient stock for item "${dbItem.itemName}". Available: $available, Requested: $requested');
            }

            dbItem.currentStock = available - requested;

            // Log stock movement
            final log = '[${DateTime.now().toIso8601String().substring(0,19)}] SOLD: -$requested | Bal: ${dbItem.currentStock} | Invoice #${invoice.invoiceNumber}';
            dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
            
            await isar.items.put(dbItem);
          }
        }

        // Save backlink items
        await invoice.invoiceItems.save();

        // 5. Add Sync Queue logs for Invoice
        final invoiceQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Invoice'
          ..entityId = invoiceId
          ..entityUuid = invoice.uuid
          ..operation = isNew ? 'Insert' : 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(invoiceQueue);

        // 6. Add Sync Queue logs for InvoiceItems
        for (var item in items) {
          final itemQueue = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = 'InvoiceItem'
            ..entityId = item.id
            ..entityUuid = item.uuid
            ..operation = isNew ? 'Insert' : 'Update'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(itemQueue);
        }
      });

      logger.info('Invoice #${invoice.invoiceNumber} saved successfully.');
    } catch (e) {
      throw DatabaseException('Failed to transaction-save invoice: $e');
    }
  }

  @override
  Future<void> cancelInvoice(String invoiceUuid, String reason, String user) async {
    try {
      final invoice = await collection.filter().uuidEqualTo(invoiceUuid).findFirst();
      if (invoice == null) {
        throw RecordNotFoundException('Invoice not found for cancellation.');
      }

      invoice.invoiceStatus = 'Cancelled';
      invoice.paymentStatus = 'Cancelled';
      invoice.cancelledBy = user;
      invoice.cancelledDate = DateTime.now();
      invoice.cancellationReason = reason;
      invoice.updatedAt = DateTime.now();
      invoice.version += 1;
      invoice.isSynced = false;

      await isar.writeTxn(() async {
        await collection.put(invoice);

        // 1. Rollback Party Outstanding Balance
        await invoice.party.load();
        final party = invoice.party.value;
        if (party != null) {
          final double pendingAmt = invoice.pendingAmount ?? 0.0;
          party.outstandingBalance = (party.outstandingBalance ?? 0.0) - pendingAmt;
          await isar.partys.put(party);
        }

        // 2. Restore Stock Levels
        await invoice.invoiceItems.load();
        for (var item in invoice.invoiceItems) {
          await item.item.load();
          if (item.item.value != null) {
            final dbItem = item.item.value!;
            final double qty = item.quantity ?? 0.0;
            dbItem.currentStock = (dbItem.currentStock ?? 0.0) + qty;

            final log = '[${DateTime.now().toIso8601String().substring(0,19)}] RESTORED: +$qty | Bal: ${dbItem.currentStock} | Cancel Invoice #${invoice.invoiceNumber}';
            dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
            
            await isar.items.put(dbItem);
          }
        }

        // 3. Sync Log
        final queueItem = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Invoice'
          ..entityId = invoice.id
          ..entityUuid = invoice.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(queueItem);
      });

      logger.info('Invoice #${invoice.invoiceNumber} cancelled by $user.');
    } catch (e) {
      throw DatabaseException('Failed to cancel invoice: $e');
    }
  }

  @override
  Future<Invoice> convertOrderToInvoice({
    required String orderUuid,
    required String invoiceType,
    required double paidAmount,
    required DateTime dueDate,
    required String user,
  }) async {
    try {
      final order = await isar.orders.filter().uuidEqualTo(orderUuid).findFirst();
      if (order == null) {
        throw RecordNotFoundException('Order not found for conversion.');
      }

      if (order.status == 'Converted To Sale') {
        throw const OrderConversionException('This order has already been converted to a sales invoice.');
      }

      await order.party.load();
      await order.orderItems.load();

      final prefix = _numberService.getFinancialYearPrefix(DateTime.now());
      final invoiceNum = await generateNextInvoiceNumber();

      final invoice = Invoice()
        ..uuid = _generateUuid()
        ..invoiceNumber = invoiceNum
        ..invoiceDate = DateTime.now()
        ..invoiceType = invoiceType
        ..sourceOrderId = order.id
        ..sourceOrderNumber = order.orderNumber
        ..partyId = order.partyId
        ..partyName = order.partyName
        ..gstNumber = order.gstNumber
        ..address = order.locationAddress
        ..subtotal = order.subtotal
        ..discountAmount = order.discountAmount
        ..taxableAmount = order.subtotal // base taxable
        ..cgstAmount = (order.totalGST ?? 0.0) / 2.0
        ..sgstAmount = (order.totalGST ?? 0.0) / 2.0
        ..igstAmount = 0.0
        ..totalGST = order.totalGST
        ..roundOff = order.roundOff
        ..grandTotal = order.grandTotal
        ..paidAmount = paidAmount
        ..pendingAmount = (order.grandTotal ?? 0.0) - paidAmount
        ..dueDate = dueDate
        ..remarks = 'Converted from Order #${order.orderNumber}. ${order.remarks ?? ""}'
        ..createdBy = user
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..isDeleted = false
        ..isSynced = false
        ..version = 1;

      // Split CGST/SGST/IGST based on state
      final companySettings = await isar.settings.where().findFirst();
      final companyGst = companySettings?.companyGST;
      final cleanCompany = companyGst?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
      final cleanParty = order.gstNumber?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
      final isLocal = cleanCompany.length >= 2 && cleanParty.length >= 2 && cleanCompany.substring(0, 2) == cleanParty.substring(0, 2);

      if (isLocal) {
        invoice.cgstAmount = (order.totalGST ?? 0.0) / 2.0;
        invoice.sgstAmount = (order.totalGST ?? 0.0) / 2.0;
        invoice.igstAmount = 0.0;
      } else {
        invoice.cgstAmount = 0.0;
        invoice.sgstAmount = 0.0;
        invoice.igstAmount = order.totalGST;
      }

      // Calculate Payment Status
      final pending = invoice.pendingAmount ?? 0.0;
      if (paidAmount == 0.0) {
        invoice.paymentStatus = 'Unpaid';
      } else if (pending <= 0.0) {
        invoice.paymentStatus = 'Paid';
        invoice.pendingAmount = 0.0;
      } else {
        invoice.paymentStatus = 'Partially Paid';
      }
      invoice.invoiceStatus = invoice.paymentStatus;

      // Lock Order
      order.status = 'Converted To Sale';
      order.updatedAt = DateTime.now();
      order.version += 1;
      order.isSynced = false;

      final List<InvoiceItem> invoiceItems = [];
      final reserveStockOnOrder = _prefs.getBool('reserve_stock_on_order') ?? false;

      await isar.writeTxn(() async {
        // 1. Put Invoice
        final invoiceId = await isar.invoices.put(invoice);
        invoice.id = invoiceId;

        // Link party
        if (order.party.value != null) {
          invoice.party.value = order.party.value;
          await invoice.party.save();

          // 2. Add Outstanding Balance to Party
          final party = order.party.value!;
          final pendingAmt = invoice.pendingAmount ?? 0.0;
          party.outstandingBalance = (party.outstandingBalance ?? 0.0) + pendingAmt;
          await isar.partys.put(party);
        }

        // 3. Link Order
        invoice.order.value = order;
        await invoice.order.save();

        // 4. Update source Order status
        await isar.orders.put(order);

        // 5. Create InvoiceItems
        for (var orderItem in order.orderItems) {
          await orderItem.item.load();
          
          final invItem = InvoiceItem()
            ..uuid = _generateUuid()
            ..itemId = orderItem.itemId
            ..itemName = orderItem.itemName
            ..hsnCode = orderItem.hsnCode
            ..quantity = orderItem.quantity
            ..freeQuantity = orderItem.freeQuantity
            ..rate = orderItem.rate
            ..discount = orderItem.discountAmount
            ..taxableAmount = orderItem.taxableAmount
            ..gstRate = orderItem.gstPercent
            ..gstAmount = orderItem.gstAmount
            ..totalAmount = orderItem.totalAmount
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now()
            ..isDeleted = false
            ..isSynced = false;

          await isar.invoiceItems.put(invItem);
          invItem.invoice.value = invoice;
          
          if (orderItem.item.value != null) {
            invItem.item.value = orderItem.item.value;
            
            // Deduct stock if stock WAS NOT reserved on order creation.
            // If it was already reserved on order, we do not deduct again!
            if (!reserveStockOnOrder) {
              final dbItem = orderItem.item.value!;
              final double available = dbItem.currentStock ?? 0.0;
              final double requested = orderItem.quantity ?? 0.0;

              if (available < requested) {
                throw StockException('Insufficient stock for item "${dbItem.itemName}". Available: $available, Requested: $requested');
              }

              dbItem.currentStock = available - requested;

              final log = '[${DateTime.now().toIso8601String().substring(0,19)}] SOLD: -$requested | Bal: ${dbItem.currentStock} | Convert Order #${order.orderNumber}';
              dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
              
              await isar.items.put(dbItem);
            }
          }
          await invItem.item.save();
          await invItem.invoice.save();
          invoiceItems.add(invItem);
        }

        // Link items
        await invoice.invoiceItems.save();

        // 6. Sync logs for Invoice
        final invoiceQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Invoice'
          ..entityId = invoiceId
          ..entityUuid = invoice.uuid
          ..operation = 'Insert'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(invoiceQueue);

        // 7. Sync logs for InvoiceItems
        for (var item in invoiceItems) {
          final itemQueue = SyncQueue()
            ..uuid = _generateUuid()
            ..entityType = 'InvoiceItem'
            ..entityId = item.id
            ..entityUuid = item.uuid
            ..operation = 'Insert'
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await isar.syncQueues.put(itemQueue);
        }

        // 8. Sync log for updating Order status
        final orderQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Order'
          ..entityId = order.id
          ..entityUuid = order.uuid
          ..operation = 'Update'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.syncQueues.put(orderQueue);
      });

      logger.info('Converted Order #${order.orderNumber} to Invoice #${invoice.invoiceNumber}.');
      return invoice;
    } catch (e) {
      throw DatabaseException('Failed to convert order to invoice: $e');
    }
  }

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return '${DateTime.now().millisecondsSinceEpoch}-${parts.join("-")}';
  }
}
