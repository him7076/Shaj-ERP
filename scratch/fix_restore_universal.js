const fs = require('fs');

const path = 'lib/features/reports/presentation/screens/deleted_vouchers_screen.dart';
let content = fs.readFileSync(path, 'utf8');

const oldLogicRegex = /if\s*\(type\.contains\('Invoice'\)[\s\S]*?if\s*\(restored\)\s*\{\s*await isar\.collection<DeletedVoucher>\(\)\.delete\(v\.id\);\s*\}/;

const newLogic = `
    // Try to restore from ALL possible collections that match this voucher number
    
    // 1. Invoices
    final inv = await isar.invoices.filter().invoiceNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (inv != null) {
      inv.isDeleted = false; inv.isSynced = false; inv.updatedAt = DateTime.now(); inv.version += 1;
      await isar.invoices.put(inv);
      await logRestore('Invoice', inv.id, inv.uuid);
      restored = true;
    }
    
    // 2. Purchases
    final pur = await isar.purchases.filter().purchaseNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (pur != null) {
      pur.isDeleted = false; pur.isSynced = false; pur.updatedAt = DateTime.now(); pur.version += 1;
      await isar.purchases.put(pur);
      await logRestore('Purchase', pur.id, pur.uuid);
      restored = true;
    }
    
    // 3. Orders
    final ord = await isar.orders.filter().orderNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (ord != null) {
      ord.isDeleted = false; ord.isSynced = false; ord.updatedAt = DateTime.now(); ord.version += 1;
      await isar.orders.put(ord);
      await logRestore('Order', ord.id, ord.uuid);
      restored = true;
    }
    
    // 4. Credit Notes
    final cn = await isar.creditNotes.filter().creditNoteNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (cn != null) {
      cn.isDeleted = false; cn.isSynced = false; cn.updatedAt = DateTime.now(); cn.version += 1;
      await isar.creditNotes.put(cn);
      await logRestore('CreditNote', cn.id, cn.uuid);
      restored = true;
    }
    
    // 5. Debit Notes
    final dn = await isar.debitNotes.filter().debitNoteNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (dn != null) {
      dn.isDeleted = false; dn.isSynced = false; dn.updatedAt = DateTime.now(); dn.version += 1;
      await isar.debitNotes.put(dn);
      await logRestore('DebitNote', dn.id, dn.uuid);
      restored = true;
    }
    
    // 6. Transactions (This also covers Payments, Receipts, and the ledger entries for Invoices/CreditNotes)
    final txn = await isar.transactions.filter().transactionNumberEqualTo(vNum).isDeletedEqualTo(true).findFirst();
    if (txn != null) {
      txn.isDeleted = false; txn.isSynced = false; txn.updatedAt = DateTime.now(); txn.version += 1;
      await isar.transactions.put(txn);
      await logRestore('Transaction', txn.id, txn.uuid);
      
      // Also restore party balance
      if (txn.partyUuid != null) {
        final party = await isar.partys.filter().uuidEqualTo(txn.partyUuid).findFirst();
        if (party != null) {
           final amt = txn.amount ?? 0.0;
           final tType = txn.transactionType;
           if (tType == 'Receipt' || tType == 'Credit Note' || tType == 'Payment' || tType == 'Debit Note') {
             party.outstandingBalance = (party.outstandingBalance ?? 0.0) - amt;
           } else if (tType == 'Sales' || tType == 'Purchase') {
             party.outstandingBalance = (party.outstandingBalance ?? 0.0) + amt;
           }
           party.updatedAt = DateTime.now();
           party.isSynced = false;
           await isar.partys.put(party);
           await logRestore('Party', party.id, party.uuid);
        }
      }
      
      restored = true;
    }

    if (restored) {
       await isar.collection<DeletedVoucher>().delete(v.id);
    }`;

content = content.replace(oldLogicRegex, newLogic);
fs.writeFileSync(path, content, 'utf8');
console.log('Fixed restore voucher logic.');
