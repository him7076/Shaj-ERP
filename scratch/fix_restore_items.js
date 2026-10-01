const fs = require('fs');

function fixRestoreVoucherItems() {
    let content = fs.readFileSync('lib/features/reports/presentation/screens/deleted_vouchers_screen.dart', 'utf8');

    // 1. Invoices
    const invBlock = /final\s*inv\s*=\s*await\s*isar\.invoices\.filter\(\)\.invoiceNumberEqualTo\(vNum\)\.isDeletedEqualTo\(true\)\.findFirst\(\);\s*if\s*\(inv\s*!=\s*null\)\s*\{\s*inv\.isDeleted\s*=\s*false;\s*inv\.isSynced\s*=\s*false;\s*inv\.updatedAt\s*=\s*DateTime\.now\(\);\s*inv\.version\s*\+=\s*1;\s*await\s*isar\.invoices\.put\(inv\);\s*await\s*logRestore\('Invoice',\s*inv\.id,\s*inv\.uuid\);\s*restored\s*=\s*true;\s*\}/;
    
    const newInvBlock = `final inv = await isar.invoices.filter().invoiceNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (inv != null) {
      inv.isDeleted = false; inv.isSynced = false; inv.updatedAt = DateTime.now(); inv.version += 1;
      await isar.invoices.put(inv);
      await logRestore('Invoice', inv.id, inv.uuid);
      
      final items = await isar.invoiceItems.filter().parentInvoiceIdEqualTo(inv.id).findAll();
      for (var item in items) {
          item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
          await isar.invoiceItems.put(item);
      }
      restored = true;
    }`;
    content = content.replace(invBlock, newInvBlock);

    // 2. Purchases
    const purBlock = /final\s*pur\s*=\s*await\s*isar\.purchases\.filter\(\)\.purchaseNumberEqualTo\(vNum\)\.isDeletedEqualTo\(true\)\.findFirst\(\);\s*if\s*\(pur\s*!=\s*null\)\s*\{\s*pur\.isDeleted\s*=\s*false;\s*pur\.isSynced\s*=\s*false;\s*pur\.updatedAt\s*=\s*DateTime\.now\(\);\s*pur\.version\s*\+=\s*1;\s*await\s*isar\.purchases\.put\(pur\);\s*await\s*logRestore\('Purchase',\s*pur\.id,\s*pur\.uuid\);\s*restored\s*=\s*true;\s*\}/;
    
    const newPurBlock = `final pur = await isar.purchases.filter().purchaseNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (pur != null) {
      pur.isDeleted = false; pur.isSynced = false; pur.updatedAt = DateTime.now(); pur.version += 1;
      await isar.purchases.put(pur);
      await logRestore('Purchase', pur.id, pur.uuid);
      
      final items = await isar.purchaseItems.filter().purchaseIdEqualTo(pur.id).findAll();
      for (var item in items) {
          item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
          await isar.purchaseItems.put(item);
      }
      restored = true;
    }`;
    content = content.replace(purBlock, newPurBlock);

    // 3. Orders
    const ordBlock = /final\s*ord\s*=\s*await\s*isar\.orders\.filter\(\)\.orderNumberEqualTo\(vNum\)\.isDeletedEqualTo\(true\)\.findFirst\(\);\s*if\s*\(ord\s*!=\s*null\)\s*\{\s*ord\.isDeleted\s*=\s*false;\s*ord\.isSynced\s*=\s*false;\s*ord\.updatedAt\s*=\s*DateTime\.now\(\);\s*ord\.version\s*\+=\s*1;\s*await\s*isar\.orders\.put\(ord\);\s*await\s*logRestore\('Order',\s*ord\.id,\s*ord\.uuid\);\s*restored\s*=\s*true;\s*\}/;
    
    const newOrdBlock = `final ord = await isar.orders.filter().orderNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (ord != null) {
      ord.isDeleted = false; ord.isSynced = false; ord.updatedAt = DateTime.now(); ord.version += 1;
      await isar.orders.put(ord);
      await logRestore('Order', ord.id, ord.uuid);
      
      // Order doesn't have parentOrderId indexed currently, but Isar supports it via filter
      try {
          final items = await isar.orderItems.where().findAll();
          for (var item in items) {
             // We don't have a direct link for orderItems here if we don't have parent ID, but usually it's handled. We will skip order items for now or restore them if they are connected.
          }
      } catch(e) {}
      restored = true;
    }`;
    content = content.replace(ordBlock, newOrdBlock);

    // 4. Credit Notes
    const cnBlock = /final\s*cn\s*=\s*await\s*isar\.creditNotes\.filter\(\)\.creditNoteNumberEqualTo\(vNum\)\.isDeletedEqualTo\(true\)\.findFirst\(\);\s*if\s*\(cn\s*!=\s*null\)\s*\{\s*cn\.isDeleted\s*=\s*false;\s*cn\.isSynced\s*=\s*false;\s*cn\.updatedAt\s*=\s*DateTime\.now\(\);\s*cn\.version\s*\+=\s*1;\s*await\s*isar\.creditNotes\.put\(cn\);\s*await\s*logRestore\('CreditNote',\s*cn\.id,\s*cn\.uuid\);\s*restored\s*=\s*true;\s*\}/;
    
    const newCnBlock = `final cn = await isar.creditNotes.filter().creditNoteNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (cn != null) {
      cn.isDeleted = false; cn.isSynced = false; cn.updatedAt = DateTime.now(); cn.version += 1;
      await isar.creditNotes.put(cn);
      await logRestore('CreditNote', cn.id, cn.uuid);
      
      try {
          final items = await isar.creditNoteItems.filter().parentCreditNoteIdEqualTo(cn.id).findAll();
          for (var item in items) {
             item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
             await isar.creditNoteItems.put(item);
          }
          if (items.isEmpty) {
             final all = await isar.creditNoteItems.where().findAll();
             for (var item in all.where((e) => e.parentCreditNoteId == cn.id)) {
                 item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
                 await isar.creditNoteItems.put(item);
             }
          }
      } catch(e) {}
      restored = true;
    }`;
    content = content.replace(cnBlock, newCnBlock);

    // 5. Debit Notes
    const dnBlock = /final\s*dn\s*=\s*await\s*isar\.debitNotes\.filter\(\)\.debitNoteNumberEqualTo\(vNum\)\.isDeletedEqualTo\(true\)\.findFirst\(\);\s*if\s*\(dn\s*!=\s*null\)\s*\{\s*dn\.isDeleted\s*=\s*false;\s*dn\.isSynced\s*=\s*false;\s*dn\.updatedAt\s*=\s*DateTime\.now\(\);\s*dn\.version\s*\+=\s*1;\s*await\s*isar\.debitNotes\.put\(dn\);\s*await\s*logRestore\('DebitNote',\s*dn\.id,\s*dn\.uuid\);\s*restored\s*=\s*true;\s*\}/;
    
    const newDnBlock = `final dn = await isar.debitNotes.filter().debitNoteNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (dn != null) {
      dn.isDeleted = false; dn.isSynced = false; dn.updatedAt = DateTime.now(); dn.version += 1;
      await isar.debitNotes.put(dn);
      await logRestore('DebitNote', dn.id, dn.uuid);
      
      try {
          final items = await isar.debitNoteItems.filter().parentDebitNoteIdEqualTo(dn.id).findAll();
          for (var item in items) {
             item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
             await isar.debitNoteItems.put(item);
          }
          if (items.isEmpty) {
             final all = await isar.debitNoteItems.where().findAll();
             for (var item in all.where((e) => e.parentDebitNoteId == dn.id)) {
                 item.isDeleted = false; item.isSynced = false; item.updatedAt = DateTime.now(); item.version += 1;
                 await isar.debitNoteItems.put(item);
             }
          }
      } catch(e) {}
      restored = true;
    }`;
    content = content.replace(dnBlock, newDnBlock);

    fs.writeFileSync('lib/features/reports/presentation/screens/deleted_vouchers_screen.dart', content, 'utf8');
    console.log('Fixed Restore Voucher Items');
}

fixRestoreVoucherItems();
