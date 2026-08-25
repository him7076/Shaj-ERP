import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:business_sahaj_erp/core/services/sync_manager.dart';

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
      invoice.invoiceStatus = 'Active';

      await isar.writeTxn(() async {
        // Fetch old invoice before putting (if editing)
        Invoice? oldInvoice;
        if (!isNew) {
          oldInvoice = await collection.get(invoice.id);
        }

        // 1. Put Invoice
        final invoiceId = await collection.put(invoice);
        invoice.id = invoiceId;

        // Load Party by ID to prevent IsarLink deadlocks in writeTxn
        final party = invoice.partyId != null ? await isar.partys.get(invoice.partyId!) : null;
        if (!kIsWeb && party != null) {
          invoice.party.value = party;
        }

        // 2. Adjust Party Outstanding Balance
        if (oldInvoice != null) {
          final oldPartyId = oldInvoice.partyId;
          final oldParty = oldPartyId != null ? await isar.partys.get(oldPartyId) : null;
          if (oldParty != null) {
            oldParty.outstandingBalance = (oldParty.outstandingBalance ?? 0.0) - (oldInvoice.pendingAmount ?? 0.0);
            await isar.partys.put(oldParty);
          }
        }

        if (party != null) {
          final pendingAmt = invoice.pendingAmount ?? 0.0;
          party.outstandingBalance = (party.outstandingBalance ?? 0.0) + pendingAmt;
          await isar.partys.put(party);
        }

        // 3. Clear old items if editing
        if (!isNew) {
          // Use only direct field filters - avoid IsarLink filters inside write txn (causes deadlock on legacy data)
          final oldByParentId = await isar.invoiceItems
              .filter()
              .parentInvoiceIdEqualTo(invoiceId)
              .findAll();
          final oldByParentUuid = invoice.uuid != null
              ? await isar.invoiceItems
                  .filter()
                  .parentInvoiceUuidEqualTo(invoice.uuid)
                  .findAll()
              : <InvoiceItem>[];
          // Merge, dedup by id
          final allOldIds = <int>{};
          final oldItems = <InvoiceItem>[];
          for (var oi in [...oldByParentId, ...oldByParentUuid]) {
            if (allOldIds.add(oi.id)) oldItems.add(oi);
          }

          for (var oldItem in oldItems) {
            oldItem.isDeleted = true;
            oldItem.isSynced = false;
            oldItem.updatedAt = DateTime.now();
            await isar.invoiceItems.put(oldItem);

            // Restore stock back before applying new ones (converting secondary unit if applicable)
            final dbItem = kIsWeb
                ? (oldItem.itemId != null ? await isar.items.get(oldItem.itemId!) : null)
                : (oldItem.itemId != null ? await isar.items.get(oldItem.itemId!) : null);
            if (dbItem != null) {
              double restoredQty = oldItem.quantity ?? 0.0;
              final convFactor = dbItem.conversionFactor ?? 1.0;
              if (convFactor > 1.0 && dbItem.secondaryUnit != null && dbItem.secondaryUnit!.isNotEmpty) {
                final uName = (oldItem.unit ?? '').trim().toLowerCase();
                final sName = dbItem.secondaryUnit!.trim().toLowerCase();
                final pName = (dbItem.primaryUnitName ?? '').trim().toLowerCase();
                if (uName == sName && uName != pName) {
                  restoredQty = restoredQty / convFactor;
                }
              }
              dbItem.currentStock = (dbItem.currentStock ?? 0.0) + restoredQty;
              await isar.items.put(dbItem);
            }
          }
        }

        // 4. Put new InvoiceItems & Deduct Stock in batch
        final itemIds = items.map((i) => i.itemId ?? 0).where((id) => id > 0).toSet();
        final fetchedItems = await isar.items.getAll(itemIds.toList());
        final Map<int, Item> targetItemMap = {
          for (var item in fetchedItems)
            if (item != null) item.id: item
        };

        for (var item in items) {
          item.uuid ??= _generateUuid();
          item.createdAt = isNew ? DateTime.now() : item.createdAt;
          item.updatedAt = DateTime.now();
          item.isDeleted = false;
          item.isSynced = false;
          item.version = isNew ? 1 : item.version + 1;

          item.parentInvoiceId = invoice.id;
          item.parentInvoiceUuid = invoice.uuid;
          try {
            item.invoice.value = invoice;
          } catch (_) {}

          final dbItem = targetItemMap[item.itemId ?? 0] ?? (kIsWeb ? null : item.item.value);
          if (dbItem != null) {
            final double available = dbItem.currentStock ?? 0.0;
            double requestedInPrimaryUnit = item.quantity ?? 0.0;

            final convFactor = dbItem.conversionFactor ?? 1.0;
            if (convFactor > 1.0 && dbItem.secondaryUnit != null && dbItem.secondaryUnit!.isNotEmpty) {
              final itemUnit = (item.unit ?? '').trim().toLowerCase();
              final secUnit = dbItem.secondaryUnit!.trim().toLowerCase();
              final pName = (dbItem.primaryUnitName ?? dbItem.unit.value?.shortName ?? '').trim().toLowerCase();
              if (itemUnit == secUnit && itemUnit != pName) {
                requestedInPrimaryUnit = requestedInPrimaryUnit / convFactor;
              }
            }

            final allowNegativeStock = _prefs.getBool('allow_negative_stock') ?? true;
            if (!allowNegativeStock && available < requestedInPrimaryUnit) {
              throw StockException('Insufficient stock for item "${dbItem.itemName}". Available: $available, Requested: $requestedInPrimaryUnit');
            }

            dbItem.currentStock = available - requestedInPrimaryUnit;

            // Log stock movement
            final log = '[${DateTime.now().toIso8601String().substring(0,19)}] SOLD: -$requestedInPrimaryUnit | Bal: ${dbItem.currentStock} | Invoice #${invoice.invoiceNumber}';
            dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
          }
        }

        await isar.invoiceItems.putAll(items);
        if (targetItemMap.isNotEmpty) {
          await isar.items.putAll(targetItemMap.values.toList());
        }

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
      Future.microtask(() => SyncManager.triggerUpload()); // Non-blocking background upload
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
        final party = invoice.partyId != null ? await isar.partys.get(invoice.partyId!) : null;
        if (party != null) {
          final double pendingAmt = invoice.pendingAmount ?? 0.0;
          party.outstandingBalance = (party.outstandingBalance ?? 0.0) - pendingAmt;
          await isar.partys.put(party);
        }

        // 2. Restore Stock Levels
        final items = await isar.invoiceItems.filter().parentInvoiceIdEqualTo(invoice.id).findAll();
        for (var item in items) {
          final dbItem = item.itemId != null ? await isar.items.get(item.itemId!) : null;
          if (dbItem != null) {
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
      SyncManager.triggerUpload(); // Instant Firebase upload
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

      try { await order.party.load(); } catch (_) {}
      try { await order.orderItems.load(); } catch (_) {}

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
      final companySettings = await isar.settings.filter().idGreaterThan(-1).findFirst();
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
      invoice.invoiceStatus = 'Active';

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

          // 2. Add Outstanding Balance to Party
          final party = order.party.value!;
          final pendingAmt = invoice.pendingAmount ?? 0.0;
          party.outstandingBalance = (party.outstandingBalance ?? 0.0) + pendingAmt;
          await isar.partys.put(party);
        }

        // 3. Link Order
        invoice.order.value = order;

        // 4. Update source Order status
        await isar.orders.put(order);

        // 5. Create InvoiceItems
        List<OrderItem> sourceItems = await isar.orderItems.filter().orderIdEqualTo(order.id).findAll();

        for (var orderItem in sourceItems) {
          
          final invItem = InvoiceItem()
            ..uuid = _generateUuid()
            ..parentInvoiceId = invoiceId
            ..unit = orderItem.unit
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
          if (!kIsWeb) {
            invItem.invoice.value = invoice;
          }
          
          if (orderItem.item.value != null || orderItem.itemId != null) {
            final dbItem = orderItem.item.value ?? (orderItem.itemId != null ? await isar.items.get(orderItem.itemId!) : null);
            if (dbItem != null) {
              if (!kIsWeb) invItem.item.value = dbItem;
              
              if (!reserveStockOnOrder) {
                final double available = dbItem.currentStock ?? 0.0;
                final double requested = orderItem.quantity ?? 0.0;

                final allowNegativeStock = _prefs.getBool('allow_negative_stock') ?? true;
                if (!allowNegativeStock && available < requested) {
                  throw StockException('Insufficient stock for item "${dbItem.itemName}". Available: $available, Requested: $requested');
                }

                dbItem.currentStock = available - requested;

                final log = '[${DateTime.now().toIso8601String().substring(0,19)}] SOLD: -$requested | Bal: ${dbItem.currentStock} | Convert Order #${order.orderNumber}';
                dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
                
                await isar.items.put(dbItem);
              }
            }
          }
          invoiceItems.add(invItem);
        }
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
      Future.microtask(() => SyncManager.triggerUpload()); // Non-blocking background upload
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
