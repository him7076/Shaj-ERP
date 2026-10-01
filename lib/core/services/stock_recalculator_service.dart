import 'package:isar/isar.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/purchase_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/stock_adjustment_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/credit_note_item_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/debit_note_item_collection.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class StockRecalculatorResult {
  final int totalItemsProcessed;
  final int totalItemsFixed;
  final List<String> details;

  StockRecalculatorResult({
    required this.totalItemsProcessed,
    required this.totalItemsFixed,
    required this.details,
  });
}

class StockRecalculatorService {
  /// Recalculates currentStock for ALL active non-deleted items based on actual active transactions:
  /// currentStock = openingStock + (Active Purchases) - (Active Sales) + (Stock In Adjustments) - (Stock Out Adjustments) + (Active Credit Notes) - (Active Debit Notes)
  static Future<StockRecalculatorResult> recalculateAllItemStocks(Isar isar) async {
    int totalItemsProcessed = 0;
    int totalItemsFixed = 0;
    final List<String> details = [];

    try {
      final allItems = await isar.items.filter().isDeletedEqualTo(false).findAll();

      // Fetch all active transactions in bulk for fast performance
      final activePurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
      final activePurchaseIds = activePurchases.map((p) => p.id).toSet();
      final activePurchaseUuids = activePurchases.map((p) => p.uuid).whereType<String>().toSet();
      final allPurchaseItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();

      final activeInvoices = await isar.invoices.filter().isDeletedEqualTo(false).and().not().invoiceStatusEqualTo('Cancelled').findAll();
      final activeInvoiceIds = activeInvoices.map((i) => i.id).toSet();
      final activeInvoiceUuids = activeInvoices.map((i) => i.uuid).whereType<String>().toSet();
      final allInvoiceItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();

      final activeStockAdjustments = await isar.stockAdjustments.filter().isDeletedEqualTo(false).findAll();

      final activeCreditNotes = await isar.creditNotes.filter().isDeletedEqualTo(false).findAll();
      final activeCNIds = activeCreditNotes.map((c) => c.id).toSet();
      final activeCNUuids = activeCreditNotes.map((c) => c.uuid).whereType<String>().toSet();
      final allCreditNoteItems = await isar.creditNoteItems.filter().isDeletedEqualTo(false).findAll();

      final activeDebitNotes = await isar.debitNotes.filter().isDeletedEqualTo(false).findAll();
      final activeDNIds = activeDebitNotes.map((d) => d.id).toSet();
      final activeDNUuids = activeDebitNotes.map((d) => d.uuid).whereType<String>().toSet();
      final allDebitNoteItems = await isar.debitNoteItems.filter().isDeletedEqualTo(false).findAll();

      final Map<int, double> newStockMap = {};

      for (var item in allItems) {
        totalItemsProcessed++;
        final itemId = item.id;
        final itemUuid = item.uuid;
        final itemNameNorm = (item.itemName ?? '').trim().toLowerCase();

        double stock = item.openingStock ?? 0.0;

        final convFactor = item.conversionFactor ?? 1.0;
        final secUnitNorm = (item.secondaryUnit ?? '').trim().toLowerCase();
        final primUnitNorm = (item.primaryUnitName ?? item.unit.value?.shortName ?? '').trim().toLowerCase();

        double toPrimary(double qty, String? unit) {
          if (unit == null || unit.trim().isEmpty) return qty;
          final uNorm = unit.trim().toLowerCase();
          if (convFactor > 1.0 && secUnitNorm.isNotEmpty && uNorm == secUnitNorm && uNorm != primUnitNorm) {
            return qty / convFactor;
          }
          return qty;
        }

        // 1. Add active Purchases
        for (var pi in allPurchaseItems) {
          final matchesItem = (pi.itemId == itemId) ||
              (itemUuid != null && itemUuid.isNotEmpty && pi.item.value?.uuid == itemUuid) ||
              (pi.itemName != null && pi.itemName!.trim().toLowerCase() == itemNameNorm && itemNameNorm.isNotEmpty);
          if (!matchesItem) continue;

          final parentActive = (pi.purchaseId != null && activePurchaseIds.contains(pi.purchaseId)) ||
              (pi.purchaseUuid != null && activePurchaseUuids.contains(pi.purchaseUuid)) ||
              (pi.purchase.value != null && activePurchaseIds.contains(pi.purchase.value!.id));

          if (parentActive) {
            stock += toPrimary(pi.quantity ?? 0.0, pi.unit);
          }
        }

        // 2. Subtract active Invoices (Sales)
        for (var ii in allInvoiceItems) {
          final matchesItem = (ii.itemId == itemId) ||
              (itemUuid != null && itemUuid.isNotEmpty && ii.item.value?.uuid == itemUuid) ||
              (ii.itemName != null && ii.itemName!.trim().toLowerCase() == itemNameNorm && itemNameNorm.isNotEmpty);
          if (!matchesItem) continue;

          final parentActive = (ii.parentInvoiceId != null && activeInvoiceIds.contains(ii.parentInvoiceId)) ||
              (ii.parentInvoiceUuid != null && activeInvoiceUuids.contains(ii.parentInvoiceUuid)) ||
              (ii.invoice.value != null && activeInvoiceIds.contains(ii.invoice.value!.id));

          if (parentActive) {
            stock -= toPrimary(ii.quantity ?? 0.0, ii.unit);
          }
        }

        // 3. Stock Adjustments
        for (var sa in activeStockAdjustments) {
          final matchesItem = (sa.itemId == itemId) ||
              (itemUuid != null && itemUuid.isNotEmpty && sa.itemUuid == itemUuid) ||
              (sa.itemName != null && sa.itemName!.trim().toLowerCase() == itemNameNorm && itemNameNorm.isNotEmpty);
          if (!matchesItem) continue;

          final qty = toPrimary(sa.quantity ?? 0.0, sa.unit);
          if (sa.adjustmentType == 'Add' || sa.adjustmentType == 'Stock In') {
            stock += qty;
          } else if (sa.adjustmentType == 'Reduce' || sa.adjustmentType == 'Stock Out') {
            stock -= qty;
          }
        }

        // 4. Add Credit Notes (Sales Return)
        for (var cni in allCreditNoteItems) {
          final matchesItem = (cni.itemId == itemId) ||
              (itemUuid != null && itemUuid.isNotEmpty && cni.item.value?.uuid == itemUuid) ||
              (cni.itemName != null && cni.itemName!.trim().toLowerCase() == itemNameNorm && itemNameNorm.isNotEmpty);
          if (!matchesItem) continue;

          final parentActive = (cni.parentCreditNoteId != null && activeCNIds.contains(cni.parentCreditNoteId)) ||
              (cni.creditNote.value != null && activeCNIds.contains(cni.creditNote.value!.id));

          if (parentActive) {
            stock += toPrimary(cni.quantity ?? 0.0, cni.unit);
          }
        }

        // 5. Subtract Debit Notes (Purchase Return)
        for (var dni in allDebitNoteItems) {
          final matchesItem = (dni.itemId == itemId) ||
              (itemUuid != null && itemUuid.isNotEmpty && dni.item.value?.uuid == itemUuid) ||
              (dni.debitNote.value != null && activeDNIds.contains(dni.debitNote.value!.id));
          if (!matchesItem) continue;

          final parentActive = (dni.parentDebitNoteId != null && activeDNIds.contains(dni.parentDebitNoteId)) ||
              (dni.debitNote.value != null && activeDNIds.contains(dni.debitNote.value!.id));

          if (parentActive) {
            stock -= toPrimary(dni.quantity ?? 0.0, dni.unit);
          }
        }

        final oldStock = item.currentStock ?? 0.0;
        if ((oldStock - stock).abs() > 0.001) {
          totalItemsFixed++;
          details.add('${item.itemName}: Stock corrected from $oldStock to $stock');
          newStockMap[itemId] = stock;
        }
      }

      if (newStockMap.isNotEmpty) {
        await isar.writeTxn(() async {
          for (var item in allItems) {
            if (newStockMap.containsKey(item.id)) {
              item.currentStock = newStockMap[item.id]!;
              item.updatedAt = DateTime.now();
              await isar.items.put(item);
            }
          }
        });
      }
      logger.info('StockRecalculator: processed $totalItemsProcessed items, fixed $totalItemsFixed items.');
    } catch (e, stack) {
      logger.error('Error running StockRecalculatorService', e, stack);
    }

    return StockRecalculatorResult(
      totalItemsProcessed: totalItemsProcessed,
      totalItemsFixed: totalItemsFixed,
      details: details,
    );
  }
}
