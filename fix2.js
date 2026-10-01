const fs = require('fs');

let f = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';
let t = fs.readFileSync(f, 'utf8');

const oldText = `            } else if (t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
              linkedPurchaseAllocations[uuid] = (linkedPurchaseAllocations[uuid] ?? 0.0) + amt;
            }
          }
        }
      }`;

const newText = `            } else if (t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
              linkedPurchaseAllocations[uuid] = (linkedPurchaseAllocations[uuid] ?? 0.0) + amt;
            }
          }
        } else if (t.linkedBillNumber != null && t.linkedBillNumber!.isNotEmpty) {
           final numbers = t.linkedBillNumber!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
           final amt = (t.amount ?? 0.0) / (numbers.isEmpty ? 1 : numbers.length);
           for (var num in numbers) {
              if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note') {
                linkedInvoiceAllocations[num] = (linkedInvoiceAllocations[num] ?? 0.0) + amt;
              } else if (t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
                linkedPurchaseAllocations[num] = (linkedPurchaseAllocations[num] ?? 0.0) + amt;
              }
           }
        }
      }`;

t = t.replace(oldText, newText);
fs.writeFileSync(f, t);
console.log('Replaced');
