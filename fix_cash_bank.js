const fs = require('fs');

function fixCashBank() {
  const f = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';
  if (!fs.existsSync(f)) return;
  let t = fs.readFileSync(f, 'utf8');

  // Fix 1: Fallback for linkedBillNumber
  const oldLinkedBill = `          } catch (_) {
            // Fallback for legacy data where linkedBillUuid is just a plain UUID string
            final uuid = t.linkedBillUuid!;
            final amt = t.amount ?? 0.0;
            if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note') {
              linkedInvoiceAllocations[uuid] = (linkedInvoiceAllocations[uuid] ?? 0.0) + amt;
            } else if (t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
              linkedPurchaseAllocations[uuid] = (linkedPurchaseAllocations[uuid] ?? 0.0) + amt;
            }
          }
        }`;
  const newLinkedBill = `          } catch (_) {
            // Fallback for legacy data where linkedBillUuid is just a plain UUID string
            final uuid = t.linkedBillUuid!;
            final amt = t.amount ?? 0.0;
            if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note') {
              linkedInvoiceAllocations[uuid] = (linkedInvoiceAllocations[uuid] ?? 0.0) + amt;
            } else if (t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
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
        }`;
  t = t.replace(oldLinkedBill, newLinkedBill);

  // Fix 2: PaymentMode vs PaymentStatus for Invoices
  t = t.replace(
      `final mode = (inv.paymentStatus ?? 'cash').trim().toLowerCase();`,
      `final mode = (inv.paymentMode ?? 'cash').trim().toLowerCase();`
  );
  
  // Fix 3: PaymentMode vs PaymentStatus for Purchases
  t = t.replace(
      `final mode = (pur.paymentStatus ?? 'cash').trim().toLowerCase();`,
      `final mode = (pur.paymentMode ?? 'cash').trim().toLowerCase();`
  );

  // The isCash check might also use status wrongly, but earlier I found:
  // bool isCash = mode == 'cash' || mode.contains('cash') || (mode.isEmpty && (status == 'cash' || status.contains('cash') || remarks.contains('paid via cash') || status == 'paid'));
  // This is actually fine as long as `mode` is derived from `paymentMode` instead of `paymentStatus`.
  
  fs.writeFileSync(f, t);
}

function fixDayBook() {
  const f = 'lib/features/reports/presentation/screens/day_book_report_screen.dart';
  if (!fs.existsSync(f)) return;
  let t = fs.readFileSync(f, 'utf8');

  // Fix 1: linkedAmountMap fallback for linkedBillNumber
  const oldLinked = `        } catch (_) {
          final uuid = t.linkedBillUuid!;
          final amt = t.amount ?? 0.0;
          if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note' || t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
            linkedAmountMap[uuid] = (linkedAmountMap[uuid] ?? 0.0) + amt;
          }
        }
      }`;
  const newLinked = `        } catch (_) {
          final uuid = t.linkedBillUuid!;
          final amt = t.amount ?? 0.0;
          if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note' || t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
            linkedAmountMap[uuid] = (linkedAmountMap[uuid] ?? 0.0) + amt;
          }
        }
      } else if (t.linkedBillNumber != null && t.linkedBillNumber!.isNotEmpty) {
           final numbers = t.linkedBillNumber!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
           final amt = (t.amount ?? 0.0) / (numbers.isEmpty ? 1 : numbers.length);
           for (var num in numbers) {
              if (t.transactionType == 'Receipt' || t.transactionType == 'Credit Note' || t.transactionType == 'Payment' || t.transactionType == 'Debit Note') {
                linkedAmountMap[num] = (linkedAmountMap[num] ?? 0.0) + amt;
              }
           }
      }`;
  t = t.replace(oldLinked, newLinked);

  // Fix 2: Day Book invoice lookup uses invoiceNumber too
  t = t.replace(
      `final linked = linkedAmountMap[inv.uuid ?? ''] ?? 0.0;`,
      `final linked = (linkedAmountMap[inv.uuid ?? ''] ?? 0.0) + (linkedAmountMap[inv.invoiceNumber ?? ''] ?? 0.0);`
  );
  
  t = t.replace(
      `final linked = linkedAmountMap[pur.uuid ?? ''] ?? 0.0;`,
      `final linked = (linkedAmountMap[pur.uuid ?? ''] ?? 0.0) + (linkedAmountMap[pur.purchaseNumber ?? ''] ?? 0.0);`
  );

  // Fix 3: paymentMode should NOT be paymentStatus in Day Book
  t = t.replace(`paymentMode: inv.paymentStatus ?? 'Cash'`, `paymentMode: inv.paymentMode ?? 'Cash'`);
  t = t.replace(`paymentMode: pur.paymentStatus ?? 'Cash'`, `paymentMode: pur.paymentMode ?? 'Cash'`);

  fs.writeFileSync(f, t);
}

fixCashBank();
fixDayBook();
console.log('Fixed CashBank and DayBook!');
