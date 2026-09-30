const fs = require('fs');
let code = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');

if(!code.includes('dart:convert')) {
    code = `import 'dart:convert';\n` + code;
}

const regex = /final Set<String> linkedInvoiceUuids = txns\.where[\s\S]*?if \(paid > 0 && \(status == accName \|\| status\.contains\(accName\) \|\| remarks\.contains\('paid via \\\$accName'\) \|\| remarks\.contains\(accName\)\)\) \{\s*bankOutflows \+= paid;\s*\}\s*\}/;

const replacement = `      final Map<String, double> linkedInvoiceAllocations = {};
      final Map<String, double> linkedPurchaseAllocations = {};

      for (var t in txns) {
        if (t.linkedBillUuid != null && t.linkedBillUuid!.isNotEmpty) {
          try {
            final allocs = json.decode(t.linkedBillUuid!);
            if (allocs is Map) {
              for (var entry in allocs.entries) {
                final uuid = entry.key.toString();
                final amt = (entry.value as num).toDouble();
                if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note') {
                  linkedInvoiceAllocations[uuid] = (linkedInvoiceAllocations[uuid] ?? 0.0) + amt;
                } else if (t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
                  linkedPurchaseAllocations[uuid] = (linkedPurchaseAllocations[uuid] ?? 0.0) + amt;
                }
              }
            }
          } catch (_) {
          }
        }
      }

      // 1. Calculate Live Cash in Hand Balance
      double cashInflows = 0.0;
      double cashOutflows = 0.0;

      for (var t in txns) {
        final mode = (t.paymentMode ?? 'cash').trim().toLowerCase();
        final target = (t.partyName ?? '').trim().toLowerCase();
        final amt = t.amount ?? 0.0;
        
        bool matches = mode == 'cash' || mode.contains('cash') || mode.isEmpty;
        if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType) && (target == 'cash' || target.contains('cash'))) {
          matches = true;
        }

        if (matches) {
          bool isCredit = false;
          if (t.transactionType == 'Receipt' || t.transactionType == 'Other Income') {
            isCredit = true;
          } else if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType)) {
             isCredit = (target == 'cash' || target.contains('cash'));
          }
          if (isCredit) cashInflows += amt; else cashOutflows += amt;
        }
      }

      for (var inv in invoices) {
        final status = (inv.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (inv.remarks ?? '').trim().toLowerCase();
        
        final totalPaidInDb = inv.paidAmount ?? 0.0;
        final linkedAlloc = linkedInvoiceAllocations[inv.uuid] ?? 0.0;
        final initialPaid = totalPaidInDb - linkedAlloc;

        if (initialPaid > 0 && (status == 'paid' || status == 'cash' || status.contains('cash') || remarks.contains('paid via cash'))) {
          cashInflows += initialPaid;
        }
      }

      for (var pur in purchases) {
        final status = (pur.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (pur.remarks ?? '').trim().toLowerCase();
        
        final totalPaidInDb = pur.paidAmount ?? 0.0;
        final linkedAlloc = linkedPurchaseAllocations[pur.uuid] ?? 0.0;
        final initialPaid = totalPaidInDb - linkedAlloc;

        if (initialPaid > 0 && (status == 'paid' || status == 'cash' || status.contains('cash') || remarks.contains('paid via cash'))) {
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
          final status = (inv.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (inv.remarks ?? '').trim().toLowerCase();
          
          final totalPaidInDb = inv.paidAmount ?? 0.0;
          final linkedAlloc = linkedInvoiceAllocations[inv.uuid] ?? 0.0;
          final initialPaid = totalPaidInDb - linkedAlloc;

          if (initialPaid > 0 && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName))) {
            bankInflows += initialPaid;
          }
        }

        for (var pur in purchases) {
          final status = (pur.paymentStatus ?? '').trim().toLowerCase();
          final remarks = (pur.remarks ?? '').trim().toLowerCase();
          
          final totalPaidInDb = pur.paidAmount ?? 0.0;
          final linkedAlloc = linkedPurchaseAllocations[pur.uuid] ?? 0.0;
          final initialPaid = totalPaidInDb - linkedAlloc;

          if (initialPaid > 0 && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName))) {
            bankOutflows += initialPaid;
          }
        }`;

code = code.replace(regex, replacement);
fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', code);
console.log('Fixed');
