const fs = require('fs');

let code = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');

// Replace in _loadAccounts (which uses `txns`)
let regex1 = /for \(var t in txns\) \{\s*if \(t\.linkedBillUuid != null && t\.linkedBillUuid!\.isNotEmpty\) \{\s*try \{\s*final allocs = json\.decode\(t\.linkedBillUuid!\);\s*if \(allocs is Map\) \{\s*for \(var entry in allocs\.entries\) \{\s*final uuid = entry\.key\.toString\(\);\s*final amt = \(entry\.value as num\)\.toDouble\(\);\s*if \(t\.transactionType == 'Receipt' \|\| t\.transactionType == 'Credit Note'\) \{\s*linkedInvoiceAllocations\[uuid\] = \(linkedInvoiceAllocations\[uuid\] \?\? 0\.0\) \+ amt;\s*\} else if \(t\.transactionType == 'Payment' \|\| t\.transactionType == 'Debit Note'\) \{\s*linkedPurchaseAllocations\[uuid\] = \(linkedPurchaseAllocations\[uuid\] \?\? 0\.0\) \+ amt;\s*\}\s*\}\s*\}\s*\} catch \(\_\) \{\s*\}\s*\}\s*\}/;

let replacement1 = `for (var t in txns) {
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
            // Fallback for legacy data where linkedBillUuid is just a plain UUID string
            final uuid = t.linkedBillUuid!;
            final amt = t.amount ?? 0.0;
            if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note') {
              linkedInvoiceAllocations[uuid] = (linkedInvoiceAllocations[uuid] ?? 0.0) + amt;
            } else if (t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
              linkedPurchaseAllocations[uuid] = (linkedPurchaseAllocations[uuid] ?? 0.0) + amt;
            }
          }
        }
      }`;

code = code.replace(regex1, replacement1);

// Replace in _loadTransactions (which uses `rawTxns`)
let regex2 = /for \(var t in rawTxns\) \{\s*if \(t\.linkedBillUuid != null && t\.linkedBillUuid!\.isNotEmpty\) \{\s*try \{\s*final allocs = json\.decode\(t\.linkedBillUuid!\);\s*if \(allocs is Map\) \{\s*for \(var entry in allocs\.entries\) \{\s*final uuid = entry\.key\.toString\(\);\s*final amt = \(entry\.value as num\)\.toDouble\(\);\s*if \(t\.transactionType == 'Receipt' \|\| t\.transactionType == 'Credit Note'\) \{\s*linkedInvoiceAllocations\[uuid\] = \(linkedInvoiceAllocations\[uuid\] \?\? 0\.0\) \+ amt;\s*\} else if \(t\.transactionType == 'Payment' \|\| t\.transactionType == 'Debit Note'\) \{\s*linkedPurchaseAllocations\[uuid\] = \(linkedPurchaseAllocations\[uuid\] \?\? 0\.0\) \+ amt;\s*\}\s*\}\s*\}\s*\} catch \(\_\) \{\s*\}\s*\}\s*\}/;

let replacement2 = `for (var t in rawTxns) {
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
            // Fallback for legacy data where linkedBillUuid is just a plain UUID string
            final uuid = t.linkedBillUuid!;
            final amt = t.amount ?? 0.0;
            if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note') {
              linkedInvoiceAllocations[uuid] = (linkedInvoiceAllocations[uuid] ?? 0.0) + amt;
            } else if (t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
              linkedPurchaseAllocations[uuid] = (linkedPurchaseAllocations[uuid] ?? 0.0) + amt;
            }
          }
        }
      }`;

code = code.replace(regex2, replacement2);

fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', code);
console.log('Fixed UUID logic');
