const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');

// 1. Fix party_detail_screen.dart
const pDetailPath = path.join(rootDir, 'lib', 'features', 'parties', 'presentation', 'screens', 'party_detail_screen.dart');
let pDetail = fs.readFileSync(pDetailPath, 'utf8');

pDetail = pDetail.replace(
  `          } else if (type == 'Credit Note') {
            if (matchesSource) bal -= amt;
          } else if (type == 'Debit Note') {
            if (matchesSource) bal += amt;`,
  `          } else if (type == 'Credit Note') {
            if (matchesSource && !isLinkedToBill) bal -= amt;
          } else if (type == 'Debit Note') {
            if (matchesSource && !isLinkedToBill) bal += amt;`
);

fs.writeFileSync(pDetailPath, pDetail, 'utf8');
console.log('Fixed party_detail_screen.dart');

// 2. Fix party_providers.dart
const pProvPath = path.join(rootDir, 'lib', 'features', 'parties', 'presentation', 'providers', 'party_providers.dart');
let pProv = fs.readFileSync(pProvPath, 'utf8');

pProv = pProv.replace(
  `      } else if (type == 'Credit Note') {
        if (matchesSource) bal -= amt;
      } else if (type == 'Debit Note') {
        if (matchesSource) bal += amt;`,
  `      } else if (type == 'Credit Note') {
        if (matchesSource && !isLinkedToBill) bal -= amt;
      } else if (type == 'Debit Note') {
        if (matchesSource && !isLinkedToBill) bal += amt;`
);

fs.writeFileSync(pProvPath, pProv, 'utf8');
console.log('Fixed party_providers.dart');

// 3. Fix analytics_repository_impl.dart
const analyticsPath = path.join(rootDir, 'lib', 'data', 'repositories', 'analytics_repository_impl.dart');
let analytics = fs.readFileSync(analyticsPath, 'utf8');

const targetAnalytics = `    // 4. Receivables and Payables — Dynamic calculation from Invoices/Purchases
    final parties = await isar.partys.filter().isDeletedEqualTo(false).findAll();

    double totalOutstanding = 0.0;
    double totalPayable = 0.0;


    for (var p in parties) {
      final bal = p.outstandingBalance ?? p.openingBalance ?? 0.0;
      if (bal > 0) {
        totalOutstanding += bal; // Receivable
      } else if (bal < 0) {
        totalPayable += (-bal);  // Payable
      }
    }`;

const replacementAnalytics = `    // 4. Receivables and Payables — Live calculation from Invoices/Purchases/Transactions
    final parties = await isar.partys.filter().isDeletedEqualTo(false).findAll();
    final allInvoices = await isar.invoices.filter().isDeletedEqualTo(false).findAll();
    final allPurchases = await isar.purchases.filter().isDeletedEqualTo(false).findAll();
    final allTxns = await isar.transactions.filter().isDeletedEqualTo(false).findAll();

    double totalOutstanding = 0.0;
    double totalPayable = 0.0;

    for (var party in parties) {
      final partyUuid = party.uuid;
      final partyId = party.id;
      final partyNameLower = party.partyName?.trim().toLowerCase() ?? '';

      double bal = party.openingBalance ?? 0.0;
      if (party.balanceType == 'Cr') {
        bal = -bal.abs();
      } else {
        bal = bal.abs();
      }

      for (var inv in allInvoices) {
        final invNameLower = inv.partyName?.trim().toLowerCase() ?? '';
        final matches = (partyUuid != null && partyUuid.isNotEmpty && inv.party.value?.uuid == partyUuid) ||
                        (partyId > 0 && inv.partyId == partyId) ||
                        (partyNameLower.isNotEmpty && invNameLower == partyNameLower);
        if (matches && inv.paymentStatus != 'Cancelled') {
          final pending = inv.pendingAmount ?? ((inv.grandTotal ?? 0.0) - (inv.paidAmount ?? 0.0));
          bal += pending > 0 ? pending : 0.0;
        }
      }

      for (var pur in allPurchases) {
        final purNameLower = pur.partyName?.trim().toLowerCase() ?? '';
        final matches = (partyUuid != null && partyUuid.isNotEmpty && pur.party.value?.uuid == partyUuid) ||
                        (partyId > 0 && pur.partyId == partyId) ||
                        (partyNameLower.isNotEmpty && purNameLower == partyNameLower);
        if (matches && pur.paymentStatus != 'Cancelled') {
          final pending = pur.pendingAmount ?? ((pur.grandTotal ?? 0.0) - (pur.paidAmount ?? 0.0));
          bal -= pending > 0 ? pending : 0.0;
        }
      }

      for (var txn in allTxns) {
        if (txn.paymentStatus == 'Cancelled' || txn.isDeleted == true) continue;
        final amt = txn.amount ?? 0.0;
        final type = txn.transactionType;
        final matchesSource = (partyUuid != null && partyUuid.isNotEmpty && txn.partyUuid == partyUuid) ||
                              (txn.partyUuid == null && partyNameLower.isNotEmpty && txn.partyName?.trim().toLowerCase() == partyNameLower);
        final matchesTarget = (partyUuid != null && partyUuid.isNotEmpty && txn.targetPartyUuid == partyUuid);
        final isLinkedToBill = txn.linkedBillUuid != null && txn.linkedBillUuid!.isNotEmpty;

        if (type == 'Receipt' || type == 'Other Income') {
          if (matchesSource && !isLinkedToBill) bal -= amt;
        } else if (type == 'Payment' || type == 'Expense') {
          if (matchesSource && !isLinkedToBill) bal += amt;
        } else if (type == 'Credit Note') {
          if (matchesSource && !isLinkedToBill) bal -= amt;
        } else if (type == 'Debit Note') {
          if (matchesSource && !isLinkedToBill) bal += amt;
        } else if (['Transfer', 'Bank Transfer', 'Cash Adjustment', 'Party Transfer', 'Party to Party Transfer'].contains(type)) {
          if (matchesSource) bal -= amt;
          else if (matchesTarget) bal += amt;
        }
      }

      if (bal > 0) {
        totalOutstanding += bal;
      } else if (bal < 0) {
        totalPayable += (-bal);
      }
    }`;

if (analytics.includes(targetAnalytics)) {
  analytics = analytics.replace(targetAnalytics, replacementAnalytics);
  fs.writeFileSync(analyticsPath, analytics, 'utf8');
  console.log('Fixed analytics_repository_impl.dart');
} else {
  console.log('Target string not found in analytics_repository_impl.dart');
}
