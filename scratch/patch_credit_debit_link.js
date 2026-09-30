const fs = require('fs');

const creditFile = 'lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart';
const debitFile = 'lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart';

function addLinkFunction(file, isDebit) {
  let code = fs.readFileSync(file, 'utf8');
  let originalCode = code;

  // Add suffixIcon to the Original Bill Number TextFormField
  const fieldRegex = /TextFormField\(\s*controller: _originalBillNumberController,\s*decoration: InputDecoration\(labelText: ('.*?'),\s*isDense: true\),\s*\)/;
  
  if (code.match(fieldRegex)) {
    code = code.replace(fieldRegex, 
      `TextFormField(
                    controller: _originalBillNumberController,
                    decoration: InputDecoration(
                      labelText: $1,
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.link, color: Colors.blue),
                        onPressed: _showLinkBillsModal,
                      ),
                    ),
                  )`);
  }

  // Add the _showLinkBillsModal function right before build method
  const modalCode = `
  void _showLinkBillsModal() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account first.')));
      return;
    }

    final isar = ref.read(databaseServiceProvider).isar;
    List<dynamic> pendingBills = [];
    
    if (${!isDebit}) {
      // Credit Note -> Link to Sales Invoices
      final invoices = await isar.invoices.filter()
          .partyUuidEqualTo(_selectedParty!.uuid)
          .and()
          .isDeletedEqualTo(false)
          .findAll();
      pendingBills = invoices.where((inv) {
        final grandTotal = inv.grandTotal ?? 0.0;
        final pendingAmount = inv.pendingAmount ?? grandTotal;
        return pendingAmount > 0 || _originalBillNumberController.text == inv.invoiceNumber;
      }).toList();
    } else {
      // Debit Note -> Link to Purchases
      final purchases = await isar.purchases.filter()
          .partyUuidEqualTo(_selectedParty!.uuid)
          .and()
          .isDeletedEqualTo(false)
          .findAll();
      pendingBills = purchases.where((pur) {
        final grandTotal = pur.grandTotal ?? 0.0;
        final pendingAmount = pur.pendingAmount ?? grandTotal;
        return pendingAmount > 0 || _originalBillNumberController.text == pur.purchaseNumber;
      }).toList();
    }

    if (pendingBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending bills found for this account.')));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: const Text('Link Bill'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: pendingBills.map((bill) {
                      final isLinked = _originalBillNumberController.text == (${!isDebit} ? bill.invoiceNumber : bill.purchaseNumber);
                      final grandTotal = bill.grandTotal ?? 0.0;
                      final pendingToPay = bill.pendingAmount ?? grandTotal;
                      final billNo = ${!isDebit} ? bill.invoiceNumber : bill.purchaseNumber;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: isLinked ? theme.colorScheme.primary.withOpacity(0.5) : theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                          color: isLinked ? theme.colorScheme.primaryContainer.withOpacity(0.1) : Colors.transparent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: isLinked,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    _originalBillNumberController.text = billNo ?? '';
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = bill.uuid;
                                    }
                                  } else {
                                    _originalBillNumberController.clear();
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = null;
                                    }
                                  }
                                });
                                setState((){});
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bill #\${billNo ?? bill.uuid.substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Total: ₹\${grandTotal.toStringAsFixed(2)} | Pending: ₹\${pendingToPay.toStringAsFixed(2)}',
                                    style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isLinked)
                              IconButton(
                                tooltip: 'Unlink',
                                icon: const Icon(Icons.link_off_rounded, color: Colors.red, size: 20),
                                onPressed: () {
                                  setModalState(() {
                                    _originalBillNumberController.clear();
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = null;
                                    }
                                  });
                                  setState((){});
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget build(BuildContext context)`;

  // Note: for Debit Note, it uses _existingDebitNote instead of _existingCreditNote. Let's fix that.
  let finalModalCode = modalCode;
  if (isDebit) {
    finalModalCode = finalModalCode.replace(/_existingCreditNote/g, '_existingDebitNote');
  }

  code = code.replace(/Widget build\(BuildContext context\)/, finalModalCode);

  // Add imports if needed
  if (!code.includes('package:business_sahaj_erp/data/local/collections/invoice_collection.dart')) {
    code = "import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';\n" + code;
  }
  if (!code.includes('package:business_sahaj_erp/data/local/collections/purchase_collection.dart')) {
    code = "import 'package:business_sahaj_erp/data/local/collections/purchase_collection.dart';\n" + code;
  }

  if (code !== originalCode) {
    fs.writeFileSync(file, code);
    console.log(`Added Link Bills UI to ${file}`);
  }
}

addLinkFunction(creditFile, false);
addLinkFunction(debitFile, true);
