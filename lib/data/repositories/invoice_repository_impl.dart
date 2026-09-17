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
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/transaction_collection.dart';
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

      final allItems = await isar.items.where().findAll();
      final targetItemMap = {for (var i in allItems) i.id: i};
      final itemUuidMap = {for (var i in allItems) if (i.uuid != null) i.uuid!: i};
      final modifiedItems = <int, Item>{};

      // --- PRE-FETCH ALL DATA OUTSIDE writeTxn ---
      Invoice? oldInvoice;
      if (!isNew) {
        oldInvoice = await collection.get(invoice.id);
      }
      
      final oldPartyId = oldInvoice?.partyId;
      final oldParty = oldPartyId != null ? await isar.partys.get(oldPartyId) : null;
      final newParty = invoice.partyId != null ? await isar.partys.get(invoice.partyId!) : null;

      List<InvoiceItem> oldByParentId = [];
      List<InvoiceItem> oldByParentUuid = [];
      if (!isNew) {
        oldByParentId = await isar.invoiceItems.filter().parentInvoiceIdEqualTo(invoice.id).findAll();
        if (invoice.uuid != null) {
          oldByParentUuid = await isar.invoiceItems.filter().parentInvoiceUuidEqualTo(invoice.uuid).findAll();
        }
      }

      await isar.writeTxn(() async {
        // 1. Put Invoice
        final invoiceId = await collection.put(invoice);
        invoice.id = invoiceId;

        // Load Party by ID to prevent IsarLink deadlocks in writeTxn
        if (!kIsWeb && newParty != null) {
          invoice.party.value = newParty;
        }

        // 2. Adjust Party Outstanding Balance
        if (oldParty != null) {
          oldParty.outstandingBalance = (oldParty.outstandingBalance ?? 0.0) - (oldInvoice?.pendingAmount ?? 0.0);
          await isar.partys.put(oldParty);
        }

        if (newParty != null) {
          final pendingAmt = invoice.pendingAmount ?? 0.0;
          newParty.outstandingBalance = (newParty.outstandingBalance ?? 0.0) + pendingAmt;
          await isar.partys.put(newParty);
        }

        // 3. Clear old items if editing
        if (!isNew) {
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
            final dbItem = oldItem.itemId != null ? targetItemMap[oldItem.itemId] : null;
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
              final hasChildComponents = oldItems.any((oi) => oi.uuid != null && oi.uuid!.endsWith("_BNDLCOMP"));
              if ((oldItem.isBundle || dbItem.isBundle) && !hasChildComponents) {
                 final uuids = oldItem.bundleComponentUuids ?? dbItem.bundleComponentUuids ?? [];
                 final qts = oldItem.bundleComponentQuantities ?? dbItem.bundleComponentQuantities ?? [];
                 final units = oldItem.bundleComponentUnits ?? dbItem.bundleComponentUnits ?? [];
                 for (int i = 0; i < uuids.length; i++) {
                   final cuuid = uuids[i];
                   final cqty = qts.length > i ? qts[i] : 1.0;
                   final cItem = itemUuidMap[cuuid];
                   if (cItem != null) {
                     cItem.currentStock = (cItem.currentStock ?? 0.0) + (restoredQty * cqty);
                     modifiedItems[cItem.id] = cItem;

                     final adj = StockAdjustment()
                        ..uuid = _generateUuid()
                        ..itemId = cItem.id
                        ..itemUuid = cItem.uuid
                        ..itemName = cItem.itemName
                        ..adjustmentType = 'Add'
                        ..quantity = restoredQty * cqty
                        ..unit = units.length > i ? units[i] : cItem.primaryUnitName ?? 'PCS'
                        ..ratePerUnit = cItem.buyRate ?? 0.0
                        ..adjustmentDate = DateTime.now()
                        ..reason = 'Reversed Bundle Sale #${oldInvoice?.invoiceNumber ?? "Editing"}'
                        ..notes = 'Component of ${dbItem.itemName}';
                     await isar.stockAdjustments.put(adj);
                   }
                 }
              } else {
                dbItem.currentStock = (dbItem.currentStock ?? 0.0) + restoredQty;
                modifiedItems[dbItem.id] = dbItem;
              }
            }
          }
        }

        // 4. Put new InvoiceItems & Deduct Stock in batch
        // We already have targetItemMap and itemUuidMap pre-fetched
        final itemsToSave = <InvoiceItem>[];

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
          
          itemsToSave.add(item);

          final dbItem = targetItemMap[item.itemId ?? 0] ?? (kIsWeb ? null : item.item.value);
          if (dbItem != null) {
            final double available = dbItem.currentStock ?? 0.0;
            double requestedInPrimaryUnit = item.quantity ?? 0.0;

            final convFactor = dbItem.conversionFactor ?? 1.0;
            if (convFactor > 1.0 && dbItem.secondaryUnit != null && dbItem.secondaryUnit!.isNotEmpty) {
              final itemUnit = (item.unit ?? '').trim().toLowerCase();
              final secUnit = dbItem.secondaryUnit!.trim().toLowerCase();
              final pName = (dbItem.primaryUnitName ?? (!kIsWeb ? dbItem.unit.value?.shortName : '') ?? '').trim().toLowerCase();
              if (itemUnit == secUnit && itemUnit != pName) {
                requestedInPrimaryUnit = requestedInPrimaryUnit / convFactor;
              }
            }

            final allowNegativeStock = _prefs.getBool('allow_negative_stock') ?? true;
            
            if (item.isBundle || dbItem.isBundle) {
              final uuids = item.bundleComponentUuids ?? dbItem.bundleComponentUuids ?? [];
              final qts = item.bundleComponentQuantities ?? dbItem.bundleComponentQuantities ?? [];
              final units = item.bundleComponentUnits ?? dbItem.bundleComponentUnits ?? [];
              for (int i = 0; i < uuids.length; i++) {
                final cuuid = uuids[i];
                final cqty = qts.length > i ? qts[i] : 1.0;
                
                Item? cItem = itemUuidMap[cuuid];
                
                if (cItem != null) {
                  final double compAvailable = cItem.currentStock ?? 0.0;
                  final double compRequested = requestedInPrimaryUnit * cqty;
                  
                  if (!allowNegativeStock && compAvailable < compRequested) {
                    throw StockException('Insufficient stock for bundle component "${cItem.itemName}". Available: $compAvailable, Requested: $compRequested');
                  }
                  
                  cItem.currentStock = compAvailable - compRequested;
                  final log = '[${DateTime.now().toIso8601String().substring(0,19)}] BUNDLE SOLD: -$compRequested | Bal: ${cItem.currentStock} | Invoice #${invoice.invoiceNumber}';
                  cItem.notes = cItem.notes == null || cItem.notes!.isEmpty ? log : '$log\n${cItem.notes}';
                  modifiedItems[cItem.id] = cItem;

                  final compItem = InvoiceItem()
                    ..uuid = "${_generateUuid()}_BNDLCOMP"
                    ..itemId = cItem.id
                    ..itemName = cItem.itemName
                    ..parentInvoiceId = invoice.id
                    ..parentInvoiceUuid = invoice.uuid
                    ..quantity = compRequested
                    ..unit = units.length > i ? units[i] : cItem.primaryUnitName ?? 'PCS'
                    ..rate = 0.0
                    ..taxableAmount = 0.0
                    ..gstRate = 0.0
                    ..gstAmount = 0.0
                    ..totalAmount = 0.0
                    ..isBundle = false
                    ..createdAt = DateTime.now()
                    ..updatedAt = DateTime.now();

                  try { compItem.invoice.value = invoice; } catch (_) {}
                  if (!kIsWeb) {
                    try { compItem.item.value = cItem; } catch (_) {}
                  }
                  
                  itemsToSave.add(compItem);
                }
              }
            } else {
              if (!allowNegativeStock && available < requestedInPrimaryUnit) {
                throw StockException('Insufficient stock for item "${dbItem.itemName}". Available: $available, Requested: $requestedInPrimaryUnit');
              }
  
              dbItem.currentStock = available - requestedInPrimaryUnit;
  
              // Log stock movement
              final log = '[${DateTime.now().toIso8601String().substring(0,19)}] SOLD: -$requestedInPrimaryUnit | Bal: ${dbItem.currentStock} | Invoice #${invoice.invoiceNumber}';
              dbItem.notes = dbItem.notes == null || dbItem.notes!.isEmpty ? log : '$log\n${dbItem.notes}';
              modifiedItems[dbItem.id] = dbItem;
            }
          }
        }

        await isar.invoiceItems.putAll(itemsToSave);
        if (modifiedItems.isNotEmpty) {
          await isar.items.putAll(modifiedItems.values.toList());
        }

        // 5. Add Sync Queue logs for Invoice
        final invoiceQueue = SyncQueue()
          ..uuid = _generateUuid()
          ..entityType = 'Invoice'
          ..entityId = invoiceId
          ..entityUuid = invoice.uuid
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

  @override
  Future<List<Invoice>> getAll() async {
    try {
      final items = await collection.filter().isDeletedEqualTo(false).findAll();
      return items;
    } catch (e) {
      throw DatabaseException('Failed to retrieve all active Invoice: $e');
    }
  }

  @override
  Future<Invoice?> getByUuid(String uuid) async {
    try {
      final allItems = await getAll();
      final entity = allItems.where((e) => e.uuid == uuid).firstOrNull;
      if (entity == null || entity.isDeleted) return null;
      return entity;
    } catch (e) {
      throw DatabaseException('Failed to retrieve Invoice by uuid: $e');
    }
  }
}
