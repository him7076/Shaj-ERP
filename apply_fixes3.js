const fs = require('fs');
let code = fs.readFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', 'utf8');

const regex = /final Set<String> linkedInvoiceUuids = rawTxns\.where[\s\S]*?entityType: 'Expense',\s*\)\);\s*\}\s*\}/;

const replacement = `      final Map<String, double> linkedInvoiceAllocations = {};
      final Map<String, double> linkedPurchaseAllocations = {};

      for (var t in rawTxns) {
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

      for (var t in rawTxns) {
        final mode = (t.paymentMode ?? 'cash').trim().toLowerCase();
        final target = (t.partyName ?? '').trim().toLowerCase();
        bool matches = false;
        if (widget.isCash) {
          matches = mode == 'cash' || mode.contains('cash') || mode.isEmpty;
          if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType)) {
            if (mode == 'cash' || mode.contains('cash') || target == 'cash' || target.contains('cash')) {
              matches = true;
            }
          }
        } else {
          final accName = widget.accountName.trim().toLowerCase();
          matches = mode == accName || mode.contains(accName) || (accName.contains('bank') && (mode == 'bank' || mode == 'online' || mode == 'upi' || mode == 'cheque'));
          if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType) && (target == accName || target.contains(accName))) {
            matches = true;
          }
        }

        if (matches) {
          bool isCredit = false;
          if (t.transactionType == 'Receipt' || t.transactionType == 'Other Income') {
            isCredit = true;
          } else if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType)) {
             if (widget.isCash) {
                isCredit = (target == 'cash' || target.contains('cash'));
             } else {
                final accName = widget.accountName.trim().toLowerCase();
                isCredit = (target == accName || target.contains(accName));
             }
          }

          String displayType = t.transactionType ?? 'Payment';
          if (t.linkedBillUuid != null && t.transactionType == 'Receipt') {
            displayType = 'Sales'; // Show as Sales for clarity
          } else if (t.linkedBillUuid != null && t.transactionType == 'Payment') {
            displayType = 'Purchase';
          }

          items.add(AccountTransactionDisplayItem(
            transactionNumber: t.transactionNumber ?? 'TXN',
            partyName: t.partyName ?? 'Party',
            transactionType: displayType,
            date: t.transactionDate ?? t.createdAt,
            amount: t.amount ?? 0.0,
            isCredit: isCredit,
            remarks: t.remarks,
            entityUuid: t.uuid,
            entityType: 'Transaction',
          ));
        }
      }

      for (var inv in invoices) {
        final status = (inv.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (inv.remarks ?? '').trim().toLowerCase();
        
        final totalPaidInDb = inv.paidAmount ?? 0.0;
        final linkedAlloc = linkedInvoiceAllocations[inv.uuid] ?? 0.0;
        final initialPaid = totalPaidInDb - linkedAlloc;
        
        bool matches = false;
        if (widget.isCash) {
           if (initialPaid > 0 && (status == 'paid' || status == 'cash' || status.contains('cash') || remarks.contains('paid via cash'))) {
              matches = true;
           }
        } else {
           final accName = widget.accountName.trim().toLowerCase();
           if (initialPaid > 0 && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName))) {
              matches = true;
           }
        }

        if (matches) {
          items.add(AccountTransactionDisplayItem(
            transactionNumber: inv.invoiceNumber ?? 'INV',
            partyName: inv.partyName ?? 'Customer',
            transactionType: 'Sales',
            date: inv.invoiceDate ?? inv.createdAt,
            amount: initialPaid,
            isCredit: true,
            remarks: inv.remarks,
            entityUuid: inv.uuid,
            entityType: 'Invoice',
          ));
        }
      }

      for (var pur in purchases) {
        final status = (pur.paymentStatus ?? '').trim().toLowerCase();
        final remarks = (pur.remarks ?? '').trim().toLowerCase();
        
        final totalPaidInDb = pur.paidAmount ?? 0.0;
        final linkedAlloc = linkedPurchaseAllocations[pur.uuid] ?? 0.0;
        final initialPaid = totalPaidInDb - linkedAlloc;
        
        bool matches = false;
        if (widget.isCash) {
           if (initialPaid > 0 && (status == 'paid' || status == 'cash' || status.contains('cash') || remarks.contains('paid via cash'))) {
              matches = true;
           }
        } else {
           final accName = widget.accountName.trim().toLowerCase();
           if (initialPaid > 0 && (status == accName || status.contains(accName) || remarks.contains('paid via $accName') || remarks.contains(accName))) {
              matches = true;
           }
        }

        if (matches) {
          items.add(AccountTransactionDisplayItem(
            transactionNumber: pur.purchaseNumber ?? 'PUR',
            partyName: pur.partyName ?? 'Supplier',
            transactionType: 'Purchase',
            date: pur.purchaseDate ?? pur.createdAt,
            amount: initialPaid,
            isCredit: false,
            remarks: pur.remarks,
            entityUuid: pur.uuid,
            entityType: 'Purchase',
          ));
        }
      }

      for (var exp in expenses) {
        final mode = (exp.paymentMode ?? 'cash').trim().toLowerCase();
        bool matches = false;
        if (widget.isCash) {
          if (mode == 'cash' || mode.contains('cash') || mode.isEmpty) matches = true;
        } else {
          final accName = widget.accountName.trim().toLowerCase();
          if (mode == accName || mode.contains(accName)) matches = true;
        }

        if (matches) {
          items.add(AccountTransactionDisplayItem(
            transactionNumber: exp.voucherNo ?? 'EXP',
            partyName: exp.partyName ?? exp.category ?? 'Expense',
            transactionType: 'Expense (\${exp.category ?? "General"})',
            date: exp.expenseDate ?? exp.createdAt,
            amount: exp.amount ?? 0.0,
            isCredit: false,
            remarks: exp.remarks,
            entityUuid: exp.uuid,
            entityType: 'Expense',
          ));
        }
      }`;

code = code.replace(regex, replacement);
fs.writeFileSync('lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart', code);
console.log('Fixed');
