const fs = require('fs');
const path = require('path');

const filePath = path.join('lib', 'core', 'services', 'database_service.dart');
let content = fs.readFileSync(filePath, 'utf8');

const oldRepairFn = `  Future<Map<String, int>> repairLegacyData() async {
    try {
      logger.info('Starting legacy data repair...');

      // ===== WEB DEEP REPAIR: Re-parse all raw Maps to typed entities =====
      Map<String, int> deepRepairStats = {};
      if (kIsWeb && _isar is WebMockIsar) {
        deepRepairStats = await (_isar as WebMockIsar).deepRepairAllEntities();
        logger.info('Web Deep Repair completed: $deepRepairStats');
      }

      // ===== COMMON REPAIR: Fix missing itemId links =====
      // Step 1: READ all data OUTSIDE the write transaction
      final allItems = await isar.items.where().findAll();
      final invItems = await isar.invoiceItems.where().findAll();
      final ordItems = await isar.orderItems.where().findAll();
      final purItems = await isar.purchaseItems.where().findAll();
      final allInvoices = await isar.invoices.where().findAll();

      // Build a name-to-item map for fast lookup
      final Map<String, Item> itemByName = {
        for (var i in allItems) if (i.itemName != null) i.itemName!: i,
      };

      // Build invoice lookup maps
      final Map<int, Invoice> invoiceById = {
        for (var inv in allInvoices) inv.id: inv,
      };
      final Map<String, Invoice> invoiceByUuid = {
        for (var inv in allInvoices) if (inv.uuid != null) inv.uuid!: inv,
      };

      // Step 2: Identify what needs to change (outside transaction)
      final List<InvoiceItem> invToUpdate = [];
      for (var ii in invItems) {
        bool changed = false;
        // Fix missing itemId
        if ((ii.itemId == null || ii.itemId == 0) && ii.itemName != null) {
          final match = itemByName[ii.itemName!];
          if (match != null) {
            ii.itemId = match.id;
            changed = true;
          }
        }
        // Fix missing parentInvoiceId/Uuid — try to find matching invoice
        if (ii.parentInvoiceId == null || ii.parentInvoiceId == 0) {
          if (ii.parentInvoiceUuid != null && invoiceByUuid.containsKey(ii.parentInvoiceUuid)) {
            ii.parentInvoiceId = invoiceByUuid[ii.parentInvoiceUuid!]!.id;
            changed = true;
          }
        }
        if ((ii.parentInvoiceUuid == null || ii.parentInvoiceUuid!.isEmpty) && ii.parentInvoiceId != null) {
          if (invoiceById.containsKey(ii.parentInvoiceId)) {
            ii.parentInvoiceUuid = invoiceById[ii.parentInvoiceId!]!.uuid;
            changed = true;
          }
        }
        if (changed) invToUpdate.add(ii);
      }

      final List<OrderItem> ordToUpdate = [];
      for (var oi in ordItems) {
        bool changed = false;
        if ((oi.itemId == null || oi.itemId == 0) && oi.itemName != null) {
          final match = itemByName[oi.itemName!];
          if (match != null) {
            oi.itemId = match.id;
            changed = true;
          }
        }
        if (changed) ordToUpdate.add(oi);
      }

      final List<PurchaseItem> purToUpdate = [];
      for (var pi in purItems) {
        bool changed = false;
        if ((pi.itemId == null || pi.itemId == 0) && pi.itemName != null) {
          final match = itemByName[pi.itemName!];
          if (match != null) {
            pi.itemId = match.id;
            changed = true;
          }
        }
        if (changed) purToUpdate.add(pi);
      }

      logger.info('Repair: \${invToUpdate.length} invoice items, \${ordToUpdate.length} order items, \${purToUpdate.length} purchase items to fix.');

      // Step 3: WRITE in a single batch transaction
      if (invToUpdate.isNotEmpty || ordToUpdate.isNotEmpty || purToUpdate.isNotEmpty) {
        await isar.writeTxn(() async {
          if (invToUpdate.isNotEmpty) await isar.invoiceItems.putAll(invToUpdate);
          if (ordToUpdate.isNotEmpty) await isar.orderItems.putAll(ordToUpdate);
          if (purToUpdate.isNotEmpty) await isar.purchaseItems.putAll(purToUpdate);
        });
      }

      // Step 4: Save repaired data on Web
      if (kIsWeb && _isar is WebMockIsar && _prefs != null) {
        await (_isar as WebMockIsar).saveToPrefs(_prefs!);
      }

      final totalFixed = invToUpdate.length + ordToUpdate.length + purToUpdate.length;
      logger.info('Legacy data repair completed. Fixed $totalFixed link records. Deep repair: $deepRepairStats');
      
      return deepRepairStats;
    } catch (e) {
      logger.error('Failed to repair legacy data', e);
      rethrow;
    }
  }`;

const newRepairFn = `  Future<Map<String, int>> repairLegacyData() async {
    try {
      logger.info('Starting deep legacy data repair...');

      Map<String, int> deepRepairStats = {};
      if (kIsWeb && _isar is WebMockIsar) {
        deepRepairStats = await (_isar as WebMockIsar).deepRepairAllEntities();
        logger.info('Web Deep Repair completed: $deepRepairStats');
      }

      final allItems = await isar.items.where().findAll();
      final invItems = await isar.invoiceItems.where().findAll();
      final ordItems = await isar.orderItems.where().findAll();
      final purItems = await isar.purchaseItems.where().findAll();
      
      final allInvoices = await isar.invoices.where().findAll();
      final allOrders = await isar.orders.where().findAll();
      final allPurchases = await isar.purchases.where().findAll();
      final allTransactions = await isar.transactions.where().findAll();

      final Map<String, Item> itemByName = {
        for (var i in allItems) if (i.itemName != null) i.itemName!: i,
      };

      final Map<int, Invoice> invoiceById = { for (var inv in allInvoices) inv.id: inv };
      final Map<String, Invoice> invoiceByUuid = { for (var inv in allInvoices) if (inv.uuid != null) inv.uuid!: inv };

      final Map<int, Order> orderById = { for (var ord in allOrders) ord.id: ord };
      final Map<String, Order> orderByUuid = { for (var ord in allOrders) if (ord.uuid != null) ord.uuid!: ord };

      final Map<int, Purchase> purchaseById = { for (var pur in allPurchases) pur.id: pur };
      final Map<String, Purchase> purchaseByUuid = { for (var pur in allPurchases) if (pur.uuid != null) pur.uuid!: pur };

      final List<InvoiceItem> invToUpdate = [];
      for (var ii in invItems) {
        bool changed = false;
        if ((ii.itemId == null || ii.itemId == 0) && ii.itemName != null) {
          final match = itemByName[ii.itemName!];
          if (match != null) { ii.itemId = match.id; changed = true; }
        }
        if (ii.parentInvoiceId == null || ii.parentInvoiceId == 0) {
          if (ii.parentInvoiceUuid != null && invoiceByUuid.containsKey(ii.parentInvoiceUuid)) {
            ii.parentInvoiceId = invoiceByUuid[ii.parentInvoiceUuid!]!.id;
            changed = true;
          }
        }
        if ((ii.parentInvoiceUuid == null || ii.parentInvoiceUuid!.isEmpty) && ii.parentInvoiceId != null) {
          if (invoiceById.containsKey(ii.parentInvoiceId)) {
            ii.parentInvoiceUuid = invoiceById[ii.parentInvoiceId!]!.uuid;
            changed = true;
          }
        }
        if (changed) invToUpdate.add(ii);
      }

      final List<OrderItem> ordToUpdate = [];
      for (var oi in ordItems) {
        bool changed = false;
        if ((oi.itemId == null || oi.itemId == 0) && oi.itemName != null) {
          final match = itemByName[oi.itemName!];
          if (match != null) { oi.itemId = match.id; changed = true; }
        }
        if (oi.parentOrderId == null || oi.parentOrderId == 0) {
          if (oi.parentOrderUuid != null && orderByUuid.containsKey(oi.parentOrderUuid)) {
            oi.parentOrderId = orderByUuid[oi.parentOrderUuid!]!.id;
            changed = true;
          }
        }
        if ((oi.parentOrderUuid == null || oi.parentOrderUuid!.isEmpty) && oi.parentOrderId != null) {
          if (orderById.containsKey(oi.parentOrderId)) {
            oi.parentOrderUuid = orderById[oi.parentOrderId!]!.uuid;
            changed = true;
          }
        }
        if (changed) ordToUpdate.add(oi);
      }

      final List<PurchaseItem> purToUpdate = [];
      for (var pi in purItems) {
        bool changed = false;
        if ((pi.itemId == null || pi.itemId == 0) && pi.itemName != null) {
          final match = itemByName[pi.itemName!];
          if (match != null) { pi.itemId = match.id; changed = true; }
        }
        if (pi.parentPurchaseId == null || pi.parentPurchaseId == 0) {
          if (pi.parentPurchaseUuid != null && purchaseByUuid.containsKey(pi.parentPurchaseUuid)) {
            pi.parentPurchaseId = purchaseByUuid[pi.parentPurchaseUuid!]!.id;
            changed = true;
          }
        }
        if ((pi.parentPurchaseUuid == null || pi.parentPurchaseUuid!.isEmpty) && pi.parentPurchaseId != null) {
          if (purchaseById.containsKey(pi.parentPurchaseId)) {
            pi.parentPurchaseUuid = purchaseById[pi.parentPurchaseId!]!.uuid;
            changed = true;
          }
        }
        if (changed) purToUpdate.add(pi);
      }

      final List<Transaction> txnToUpdate = [];
      for (var txn in allTransactions) {
        bool changed = false;
        if (txn.transactionDate == null) {
          txn.transactionDate = txn.createdAt;
          changed = true;
        }
        if (txn.transactionType != null) {
          final type = txn.transactionType!;
          if (type == 'receipt') { txn.transactionType = 'Receipt'; changed = true; }
          else if (type == 'payment') { txn.transactionType = 'Payment'; changed = true; }
          else if (type == 'expense') { txn.transactionType = 'Expense'; changed = true; }
          else if (type == 'transfer') { txn.transactionType = 'Transfer'; changed = true; }
          else if (type == 'sales') { txn.transactionType = 'Sales'; changed = true; }
          else if (type == 'purchase') { txn.transactionType = 'Purchase'; changed = true; }
          else if (type == 'other income') { txn.transactionType = 'Other Income'; changed = true; }
          else if (type == 'bank transfer') { txn.transactionType = 'Bank Transfer'; changed = true; }
          else if (type == 'cash adjustment') { txn.transactionType = 'Cash Adjustment'; changed = true; }
        }
        if (changed) txnToUpdate.add(txn);
      }

      final List<Invoice> invDateUpdates = [];
      for (var inv in allInvoices) {
        if (inv.invoiceDate == null) {
          inv.invoiceDate = inv.createdAt;
          invDateUpdates.add(inv);
        }
      }

      final List<Purchase> purDateUpdates = [];
      for (var pur in allPurchases) {
        if (pur.purchaseDate == null) {
          pur.purchaseDate = pur.createdAt;
          purDateUpdates.add(pur);
        }
      }

      final List<Order> ordDateUpdates = [];
      for (var ord in allOrders) {
        if (ord.orderDate == null) {
          ord.orderDate = ord.createdAt;
          ordDateUpdates.add(ord);
        }
      }

      logger.info('Repair: \${invToUpdate.length} invoice items, \${ordToUpdate.length} order items, \${purToUpdate.length} purchase items to fix links.');
      logger.info('Repair: \${txnToUpdate.length} txns, \${invDateUpdates.length} invoices, \${purDateUpdates.length} purchases, \${ordDateUpdates.length} orders to fix dates/types.');

      await isar.writeTxn(() async {
        if (invToUpdate.isNotEmpty) await isar.invoiceItems.putAll(invToUpdate);
        if (ordToUpdate.isNotEmpty) await isar.orderItems.putAll(ordToUpdate);
        if (purToUpdate.isNotEmpty) await isar.purchaseItems.putAll(purToUpdate);
        
        if (txnToUpdate.isNotEmpty) await isar.transactions.putAll(txnToUpdate);
        if (invDateUpdates.isNotEmpty) await isar.invoices.putAll(invDateUpdates);
        if (purDateUpdates.isNotEmpty) await isar.purchases.putAll(purDateUpdates);
        if (ordDateUpdates.isNotEmpty) await isar.orders.putAll(ordDateUpdates);
      });

      if (kIsWeb && _isar is WebMockIsar && _prefs != null) {
        await (_isar as WebMockIsar).saveToPrefs(_prefs!);
      }

      final totalFixed = invToUpdate.length + ordToUpdate.length + purToUpdate.length + txnToUpdate.length + invDateUpdates.length + purDateUpdates.length + ordDateUpdates.length;
      logger.info('Deep legacy data repair completed. Fixed $totalFixed records. Deep repair: $deepRepairStats');
      
      return deepRepairStats;
    } catch (e) {
      logger.error('Failed to repair legacy data', e);
      rethrow;
    }
  }`;

if (content.includes("Fix missing itemId links")) {
    content = content.replace(oldRepairFn, newRepairFn);
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Successfully replaced repairLegacyData function.');
} else {
    console.error('Could not find target function.');
}
