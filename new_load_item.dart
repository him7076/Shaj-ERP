  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final isar = ref.read(databaseServiceProvider).isar;
      final fetchedItem = await repo.getByUuid(widget.itemUuid);

      if (fetchedItem != null) {
        try { await fetchedItem.category.load(); } catch (_) {}
        try { await fetchedItem.brand.load(); } catch (_) {}
        try { await fetchedItem.unit.load(); } catch (_) {}

        final List<_ItemTransaction> txs = [];
        final itemName = fetchedItem.itemName?.trim().toLowerCase() ?? '';
        final itemUuid = fetchedItem.uuid;

        // 1. Sales Invoices
        final allInvItems = await isar.invoiceItems.filter().isDeletedEqualTo(false).findAll();
        final matchedInvItems = allInvItems.where((ii) {
          if (ii.itemId == fetchedItem.id) return true;
          if (itemName.isNotEmpty && ii.itemId == null && (ii.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        final invIds = matchedInvItems.map((ii) => ii.parentInvoiceId).where((id) => id != null).cast<int>().toSet().toList();
        final invoicesBatch = await isar.invoices.getAll(invIds);
        final invoicesMap = { for (var inv in invoicesBatch) if (inv != null) inv.id: inv };

        final invUuids = matchedInvItems.map((ii) => ii.parentInvoiceUuid).where((u) => u != null && u.isNotEmpty).cast<String>().toSet().toList();
        final allInvoices = invUuids.isNotEmpty ? await isar.invoices.filter().isDeletedEqualTo(false).findAll() : <Invoice>[];
        final invoicesUuidMap = { for (var inv in allInvoices) if (inv.uuid != null && invUuids.contains(inv.uuid)) inv.uuid!: inv };

        for (var ii in matchedInvItems) {
          Invoice? inv;
          if (ii.parentInvoiceId != null) inv = invoicesMap[ii.parentInvoiceId];
          if (inv == null && ii.parentInvoiceUuid != null) inv = invoicesUuidMap[ii.parentInvoiceUuid];
          
          if (inv == null) {
            try { 
              await ii.invoice.load();
              inv = ii.invoice.value; 
            } catch (_) {}
          }

          if (inv != null && !inv.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Sale',
              date: inv.invoiceDate ?? inv.createdAt,
              title: 'Sales Invoice #${inv.invoiceNumber}',
              partyName: inv.partyName ?? 'Customer',
              quantity: ii.quantity ?? 1.0,
              unit: (ii.unit != null && ii.unit!.isNotEmpty && ii.unit != 'PCS')
                  ? ii.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? ii.unit ?? 'PCS'),
              rate: ii.rate ?? 0.0,
              totalAmount: ii.taxableAmount ?? (ii.quantity ?? 1.0) * (ii.rate ?? 0.0) - (ii.discount ?? 0.0),
              targetUuid: inv.uuid ?? inv.id.toString(),
            ));
          }
        }

        // 2. Purchase Bills
        final allPurItems = await isar.purchaseItems.filter().isDeletedEqualTo(false).findAll();
        final matchedPurItems = allPurItems.where((pi) {
          if (pi.itemId == fetchedItem.id) return true;
          if (itemName.isNotEmpty && pi.itemId == null && (pi.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        final purIds = matchedPurItems.map((pi) => pi.purchaseId).where((id) => id != null).cast<int>().toSet().toList();
        final purchasesBatch = await isar.collection<Purchase>().getAll(purIds);
        final purchasesMap = { for (var pur in purchasesBatch) if (pur != null) pur.id: pur };

        final purUuids = matchedPurItems.map((pi) => pi.purchaseUuid).where((u) => u != null && u.isNotEmpty).cast<String>().toSet().toList();
        final allPurchases = purUuids.isNotEmpty ? await isar.collection<Purchase>().filter().isDeletedEqualTo(false).findAll() : <Purchase>[];
        final purchasesUuidMap = { for (var pur in allPurchases) if (pur.uuid != null && purUuids.contains(pur.uuid)) pur.uuid!: pur };

        for (var pi in matchedPurItems) {
          Purchase? pur;
          if (pi.purchaseId != null) pur = purchasesMap[pi.purchaseId];
          if (pur == null && pi.purchaseUuid != null) pur = purchasesUuidMap[pi.purchaseUuid];

          if (pur == null) {
            try {
              await pi.purchase.load();
              pur = pi.purchase.value;
            } catch (_) {}
          }

          if (pur != null && !pur.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Purchase',
              date: pur.purchaseDate ?? pur.createdAt,
              title: 'Purchase Bill #${pur.purchaseNumber}${pur.supplierInvoiceNumber != null && pur.supplierInvoiceNumber!.isNotEmpty ? " (Supp: ${pur.supplierInvoiceNumber})" : ""}',
              partyName: pur.partyName ?? 'Supplier',
              quantity: pi.quantity ?? 1.0,
              unit: (pi.unit != null && pi.unit!.isNotEmpty && pi.unit != 'PCS')
                  ? pi.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? pi.unit ?? 'PCS'),
              rate: pi.rate ?? 0.0,
              totalAmount: pi.taxableAmount ?? (pi.quantity ?? 1.0) * (pi.rate ?? 0.0) - (pi.discount ?? 0.0),
              targetUuid: pur.uuid ?? pur.id.toString(),
            ));
          }
        }

        // 3. Orders
        final allOrdItems = await isar.orderItems.filter().isDeletedEqualTo(false).findAll();
        final matchedOrdItems = allOrdItems.where((oi) {
          if (oi.itemId == fetchedItem.id) return true;
          if (itemName.isNotEmpty && oi.itemId == null && (oi.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        final ordIds = matchedOrdItems.map((oi) => oi.orderId).where((id) => id != null).cast<int>().toSet().toList();
        final ordersBatch = await isar.orders.getAll(ordIds);
        final ordersMap = { for (var ord in ordersBatch) if (ord != null) ord.id: ord };

        for (var oi in matchedOrdItems) {
          Order? ord = oi.orderId != null ? ordersMap[oi.orderId] : null;
          if (ord == null && oi.order.value != null) ord = oi.order.value;

          if (ord != null && !ord.isDeleted) {
            txs.add(_ItemTransaction(
              type: 'Order',
              date: ord.orderDate ?? ord.createdAt,
              title: 'Sales Order #${ord.orderNumber}',
              partyName: ord.partyName ?? 'Customer',
              quantity: oi.quantity ?? 1.0,
              unit: (oi.unit != null && oi.unit!.isNotEmpty && oi.unit != 'PCS')
                  ? oi.unit!
                  : (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? oi.unit ?? 'PCS'),
              rate: oi.rate ?? 0.0,
              totalAmount: oi.taxableAmount ?? (oi.quantity ?? 1.0) * (oi.rate ?? 0.0) - (oi.discountAmount ?? 0.0),
              targetUuid: ord.uuid ?? ord.id.toString(),
            ));
          }
        }

        // 4. Stock Adjustments
        final allAdjustments = await isar.collection<StockAdjustment>().filter().isDeletedEqualTo(false).findAll();
        final adjustments = allAdjustments.where((adj) {
          if (adj.itemId == fetchedItem.id) return true;
          if (itemUuid != null && itemUuid.isNotEmpty && adj.itemUuid == itemUuid) return true;
          if (itemName.isNotEmpty && adj.itemId == null && (adj.itemName?.trim().toLowerCase() ?? '') == itemName) return true;
          return false;
        }).toList();

        for (var adj in adjustments) {
          final isAdd = adj.adjustmentType == 'Add' || adj.adjustmentType == 'Stock In';
          final adjRate = adj.ratePerUnit ?? fetchedItem.buyRate ?? 0.0;
          final adjQty = adj.quantity ?? 0.0;
          final adjTotalVal = adj.totalValue ?? (adjQty * adjRate);
          txs.add(_ItemTransaction(
            type: 'Adjustment',
            date: adj.adjustmentDate ?? adj.createdAt,
            title: 'Stock Adjustment (${isAdd ? "Stock In +" : "Stock Out -"})',
            partyName: adj.reason ?? (isAdd ? 'Stock Added' : 'Stock Reduced'),
            quantity: adjQty,
            unit: adj.unit ?? (fetchedItem.primaryUnitName ?? fetchedItem.unit.value?.shortName ?? 'PCS'),
            rate: adjRate,
            totalAmount: adjTotalVal,
            targetUuid: adj.uuid ?? adj.id.toString(),
            rawAdjustment: adj,
          ));
        }

        // Sort descending by date
        txs.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
           _item = fetchedItem;
           _itemTransactions = txs;
        });
      }
    } catch (e) {
      logger.error('Failed to load item detail', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
