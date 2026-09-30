const fs = require('fs');
let code = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');

const regexInv = /for \(var inv in invoices\) \{\s*final status = \(inv\.paymentStatus \?\? ''\)\.trim\(\)\.toLowerCase\(\);\s*final remarks = \(inv\.remarks \?\? ''\)\.trim\(\)\.toLowerCase\(\);\s*final totalPaidInDb = inv\.paidAmount \?\? 0\.0;\s*final linkedAlloc = linkedInvoiceAllocations\[inv\.uuid\] \?\? 0\.0;\s*final initialPaid = totalPaidInDb - linkedAlloc;\s*bool matches = false;\s*if \(widget\.isCash\) \{\s*if \(initialPaid > 0 && \(status == 'paid' \|\| status == 'cash' \|\| status\.contains\('cash'\) \|\| remarks\.contains\('paid via cash'\)\)\) \{\s*matches = true;\s*\}\s*\} else \{\s*final accName = widget\.accountName\.trim\(\)\.toLowerCase\(\);\s*if \(initialPaid > 0 && \(status == accName \|\| status\.contains\(accName\) \|\| remarks\.contains\('paid via \\$accName'\) \|\| remarks\.contains\(accName\)\)\) \{\s*matches = true;\s*\}\s*\}\s*if \(matches\) \{/g;

const replacementInv = `for (var inv in invoices) {
        final mode = (inv.paymentMode ?? '').trim().toLowerCase();
        final status = (inv.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (inv.remarks ?? '').trim().toLowerCase();
        
        final totalPaidInDb = inv.paidAmount ?? 0.0;
        final linkedAlloc = linkedInvoiceAllocations[inv.uuid] ?? 0.0;
        final initialPaid = totalPaidInDb - linkedAlloc;
        
        bool matches = false;
        if (widget.isCash) {
           bool isCash = mode == 'cash' || mode.contains('cash') || (mode.isEmpty && (status == 'cash' || status.contains('cash') || remarks.contains('paid via cash') || status == 'paid'));
           if (initialPaid > 0 && isCash) {
              matches = true;
           }
        } else {
           final accName = widget.accountName.trim().toLowerCase();
           bool isBank = mode == accName || mode.contains(accName) || (mode.isEmpty && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName)));
           if (initialPaid > 0 && isBank) {
              matches = true;
           }
        }

        if (matches) {`;

code = code.replace(regexInv, replacementInv);

const regexPur = /for \(var pur in purchases\) \{\s*final status = \(pur\.paymentStatus \?\? ''\)\.trim\(\)\.toLowerCase\(\);\s*final remarks = \(pur\.remarks \?\? ''\)\.trim\(\)\.toLowerCase\(\);\s*final totalPaidInDb = pur\.paidAmount \?\? 0\.0;\s*final linkedAlloc = linkedPurchaseAllocations\[pur\.uuid\] \?\? 0\.0;\s*final initialPaid = totalPaidInDb - linkedAlloc;\s*bool matches = false;\s*if \(widget\.isCash\) \{\s*if \(initialPaid > 0 && \(status == 'paid' \|\| status == 'cash' \|\| status\.contains\('cash'\) \|\| remarks\.contains\('paid via cash'\)\)\) \{\s*matches = true;\s*\}\s*\} else \{\s*final accName = widget\.accountName\.trim\(\)\.toLowerCase\(\);\s*if \(initialPaid > 0 && \(status == accName \|\| status\.contains\(accName\) \|\| remarks\.contains\('paid via \\$accName'\) \|\| remarks\.contains\(accName\)\)\) \{\s*matches = true;\s*\}\s*\}\s*if \(matches\) \{/g;

const replacementPur = `for (var pur in purchases) {
        final mode = (pur.paymentMode ?? '').trim().toLowerCase();
        final status = (pur.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (pur.remarks ?? '').trim().toLowerCase();
        
        final totalPaidInDb = pur.paidAmount ?? 0.0;
        final linkedAlloc = linkedPurchaseAllocations[pur.uuid] ?? 0.0;
        final initialPaid = totalPaidInDb - linkedAlloc;
        
        bool matches = false;
        if (widget.isCash) {
           bool isCash = mode == 'cash' || mode.contains('cash') || (mode.isEmpty && (status == 'cash' || status.contains('cash') || remarks.contains('paid via cash') || status == 'paid'));
           if (initialPaid > 0 && isCash) {
              matches = true;
           }
        } else {
           final accName = widget.accountName.trim().toLowerCase();
           bool isBank = mode == accName || mode.contains(accName) || (mode.isEmpty && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName)));
           if (initialPaid > 0 && isBank) {
              matches = true;
           }
        }

        if (matches) {`;

code = code.replace(regexPur, replacementPur);

fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', code);
console.log('Fixed _loadTransactions');
