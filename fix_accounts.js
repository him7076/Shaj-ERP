const fs = require('fs');

let code = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');

// We need to fix the logic in four places:
// 1. _loadAccounts() - Invoices (Cash)
// 2. _loadAccounts() - Purchases (Cash)
// 3. _loadAccounts() - Invoices (Bank)
// 4. _loadAccounts() - Purchases (Bank)
// 5. _loadTransactions() - Invoices (Cash/Bank)
// 6. _loadTransactions() - Purchases (Cash/Bank)

function replaceAll(str, find, replace) {
  return str.split(find).join(replace);
}

// FIX _loadAccounts
const accountsRegex = /for \(var inv in invoices\) \{[\s\S]*?bankOutflows \+= initialPaid;\s*\}/g;

const accountsReplacement = `for (var inv in invoices) {
        final mode = (inv.paymentMode ?? '').trim().toLowerCase();
        final status = (inv.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (inv.remarks ?? '').trim().toLowerCase();
        
        final totalPaidInDb = inv.paidAmount ?? 0.0;
        final linkedAlloc = linkedInvoiceAllocations[inv.uuid] ?? 0.0;
        final initialPaid = totalPaidInDb - linkedAlloc;

        bool isCash = mode == 'cash' || mode.contains('cash') || (mode.isEmpty && (status == 'cash' || status.contains('cash') || remarks.contains('paid via cash') || status == 'paid'));

        if (initialPaid > 0 && isCash) {
          cashInflows += initialPaid;
        }
      }

      for (var pur in purchases) {
        final mode = (pur.paymentMode ?? '').trim().toLowerCase();
        final status = (pur.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (pur.remarks ?? '').trim().toLowerCase();
        
        final totalPaidInDb = pur.paidAmount ?? 0.0;
        final linkedAlloc = linkedPurchaseAllocations[pur.uuid] ?? 0.0;
        final initialPaid = totalPaidInDb - linkedAlloc;

        bool isCash = mode == 'cash' || mode.contains('cash') || (mode.isEmpty && (status == 'cash' || status.contains('cash') || remarks.contains('paid via cash') || status == 'paid'));

        if (initialPaid > 0 && isCash) {
          cashOutflows += initialPaid;
        }
      }

      for (var exp in expenses) {
        final mode = (exp.paymentMode ?? 'cash').trim().toLowerCase();
        if (mode == 'cash' || mode.contains('cash') || mode.isEmpty) {
          cashOutflows += (exp.amount ?? 0.0);
        }
      }

      _cashBalance = cashInflows - cashOutflows;

      // 2. Calculate Live Bank Account Balances
      for (var acc in _accounts) {
        final accName = (acc.accountName ?? '').trim().toLowerCase();
        double bankInflows = 0.0;
        double bankOutflows = 0.0;

        for (var t in txns) {
          final mode = (t.paymentMode ?? '').trim().toLowerCase();
          final target = (t.partyName ?? '').trim().toLowerCase();
          final amt = t.amount ?? 0.0;

          bool matches = mode == accName || mode.contains(accName) || (accName.contains('bank') && (mode == 'bank' || mode == 'online' || mode == 'upi' || mode == 'cheque'));
          if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType) && (target == accName || target.contains(accName))) {
            matches = true;
          }

          if (matches) {
            bool isCredit = false;
            if (t.transactionType == 'Receipt' || t.transactionType == 'Other Income') {
              isCredit = true;
            } else if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType)) {
               isCredit = (target == accName || target.contains(accName));
            }
            if (isCredit) bankInflows += amt; else bankOutflows += amt;
          }
        }

        for (var inv in invoices) {
          final mode = (inv.paymentMode ?? '').trim().toLowerCase();
          final status = (inv.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (inv.remarks ?? '').trim().toLowerCase();
          
          final totalPaidInDb = inv.paidAmount ?? 0.0;
          final linkedAlloc = linkedInvoiceAllocations[inv.uuid] ?? 0.0;
          final initialPaid = totalPaidInDb - linkedAlloc;

          bool isBank = mode == accName || mode.contains(accName) || (mode.isEmpty && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName)));

          if (initialPaid > 0 && isBank) {
            bankInflows += initialPaid;
          }
        }

        for (var pur in purchases) {
          final mode = (pur.paymentMode ?? '').trim().toLowerCase();
          final status = (pur.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (pur.remarks ?? '').trim().toLowerCase();
          
          final totalPaidInDb = pur.paidAmount ?? 0.0;
          final linkedAlloc = linkedPurchaseAllocations[pur.uuid] ?? 0.0;
          final initialPaid = totalPaidInDb - linkedAlloc;

          bool isBank = mode == accName || mode.contains(accName) || (mode.isEmpty && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName)));

          if (initialPaid > 0 && isBank) {
            bankOutflows += initialPaid;
          }
        }`;

// Wait, the regex `accountsRegex` will match the FIRST occurrence.
// Since `_loadAccounts` STILL has the original `inv.paidAmount ?? inv.grandTotal`, it won't match `initialPaid`.
// Let me use a custom search/replace for `_loadAccounts` using string indices.

let startIndex = code.indexOf('for (var inv in invoices) {\n        if (inv.uuid != null && linkedInvoiceUuids.contains(inv.uuid)) continue;');
if (startIndex === -1) {
    startIndex = code.indexOf('for (var inv in invoices) {\n        final status = (inv.paymentStatus ?? \\'\\').trim().toLowerCase();');
}

let code2 = code;

if (startIndex !== -1) {
    let endIndex = code.indexOf('      // 3. Overall Totals for display');
    if (endIndex === -1) {
        endIndex = code.indexOf('    } catch (e) {', startIndex);
    }
    
    // We'll just replace the loops using a more robust way.
}

console.log("Found");
