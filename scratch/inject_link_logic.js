const fs = require('fs');

function patchScreen(filePath, isCreditNote) {
    let content = fs.readFileSync(filePath, 'utf8');

    // 1. Add state variables
    const stateVars = `
  Map<String, double> _linkedAllocations = {};
  final Map<String, TextEditingController> _allocControllers = {};
  final Map<String, FocusNode> _allocFocusNodes = {};`;
    content = content.replace(/String\?\s+_linkedBillUuid;/, stateVars);

    // 2. Initialize in _initValues()
    const loadStr = isCreditNote ? `_existingCreditNote?.originalInvoiceUuid` : `_existingDebitNote?.originalPurchaseUuid`;
    
    // find _initValues block
    const initRegex = /(void _initValues\(\)\s*\{[\s\S]*?)(_linkedBillUuid\s*=\s*[^;]+;)/;
    const newInit = `$1
    final initialLink = ${loadStr};
    if (initialLink != null && initialLink.isNotEmpty) {
      if (initialLink.startsWith('{')) {
        try {
          final decoded = json.decode(initialLink) as Map<String, dynamic>;
          _linkedAllocations = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
        } catch (_) {}
      } else {
        _linkedAllocations = {initialLink: _totalAmount};
      }
    }`;
    content = content.replace(initRegex, newInit);

    // 3. Dispose controllers
    const disposeRegex = /(void dispose\(\)\s*\{[\s\S]*?)(super\.dispose\(\);)/;
    const newDispose = `$1
    for (var controller in _allocControllers.values) {
      controller.dispose();
    }
    for (var node in _allocFocusNodes.values) {
      node.dispose();
    }
    $2`;
    content = content.replace(disposeRegex, newDispose);

    // 4. Update Save logic
    const saveRegex = isCreditNote 
      ? /(_existingCreditNote!\.originalInvoiceUuid\s*=\s*)_linkedBillUuid;/g
      : /(_existingDebitNote!\.originalPurchaseUuid\s*=\s*)_linkedBillUuid;/g;
    const newSave = `$1_linkedAllocations.isNotEmpty ? json.encode(_linkedAllocations) : null;`;
    content = content.replace(saveRegex, newSave);
    
    // Also update where a new note is created in save logic
    const createRegex = isCreditNote
      ? /(\.\.originalInvoiceUuid\s*=\s*)_linkedBillUuid/g
      : /(\.\.originalPurchaseUuid\s*=\s*)_linkedBillUuid/g;
    const newCreate = `$1_linkedAllocations.isNotEmpty ? json.encode(_linkedAllocations) : null`;
    content = content.replace(createRegex, newCreate);

    // 5. Update the Link Button Text
    const btnRegex = /(label:\s*const\s*Text\(')Link('\),)/;
    const newBtn = `label: Text(_linkedAllocations.isNotEmpty ? 'Linked (\${_linkedAllocations.length})' : 'Link'),`;
    content = content.replace(btnRegex, newBtn);

    // 6. Rewrite _showLinkBillsModal
    const modalRegex = /void _showLinkBillsModal\(\)\s*async\s*\{[\s\S]*?(?=\n\n  \/\/)/;
    
    // We need to inject the full logic for the modal
    const billType = isCreditNote ? 'invoices' : 'purchases';
    const numberField = isCreditNote ? 'invoiceNumber' : 'purchaseNumber';

    const newModal = `void _showLinkBillsModal() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an account first.')));
      return;
    }

    final isar = ref.read(databaseServiceProvider).isar;
    List<dynamic> pendingBills = [];
    
    if (${isCreditNote}) {
      final invoices = await isar.invoices.filter()
          .partyNameEqualTo(_selectedParty!.partyName)
          .and()
          .isDeletedEqualTo(false)
          .findAll();
      pendingBills = invoices.where((inv) {
        final grandTotal = inv.grandTotal ?? 0.0;
        final pendingAmount = inv.pendingAmount ?? grandTotal;
        return pendingAmount > 0 || _linkedAllocations.containsKey(inv.uuid);
      }).toList();
    } else {
      final purchases = await isar.purchases.filter()
          .partyNameEqualTo(_selectedParty!.partyName)
          .and()
          .isDeletedEqualTo(false)
          .findAll();
      pendingBills = purchases.where((pur) {
        final grandTotal = pur.grandTotal ?? 0.0;
        final pendingAmount = pur.pendingAmount ?? grandTotal;
        return pendingAmount > 0 || _linkedAllocations.containsKey(pur.uuid);
      }).toList();
    }

    if (pendingBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending bills found for this account.')));
      return;
    }

    // Initialize controllers for the modal
    final currentUuids = pendingBills.map((b) => b.uuid as String).toSet();
    _allocControllers.removeWhere((uuid, controller) {
      if (!currentUuids.contains(uuid)) {
        controller.dispose();
        _allocFocusNodes[uuid]?.dispose();
        _allocFocusNodes.remove(uuid);
        return true;
      }
      return false;
    });

    for (var bill in pendingBills) {
      final uuid = bill.uuid as String;
      final alloc = _linkedAllocations[uuid] ?? 0.0;
      if (!_allocControllers.containsKey(uuid)) {
        _allocControllers[uuid] = TextEditingController(
          text: alloc > 0 ? alloc.toStringAsFixed(2) : '',
        );
        _allocFocusNodes[uuid] = FocusNode();
      } else {
        final textValue = alloc > 0 ? alloc.toStringAsFixed(2) : '';
        if (_allocControllers[uuid]!.text != textValue && !(_allocFocusNodes[uuid]?.hasFocus ?? false)) {
          _allocControllers[uuid]!.text = textValue;
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            
            // Re-calculate totals dynamically
            final totalAllocated = _linkedAllocations.values.fold(0.0, (sum, val) => sum + val);
            
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Link Bills'),
                  Text(
                    'Allocated: ₹\${totalAllocated.toStringAsFixed(2)} / ₹\${_totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: totalAllocated > _totalAmount ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: pendingBills.map((bill) {
                      final uuid = bill.uuid as String;
                      final isLinked = _linkedAllocations.containsKey(uuid);
                      final grandTotal = bill.grandTotal ?? 0.0;
                      final pendingToPay = bill.pendingAmount ?? grandTotal;
                      final currentAlloc = _linkedAllocations[uuid] ?? 0.0;
                      final billNo = ${isCreditNote} ? bill.invoiceNumber : bill.purchaseNumber;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: isLinked ? theme.colorScheme.primary.withOpacity(0.5) : theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                          color: isLinked ? theme.colorScheme.primaryContainer.withOpacity(0.1) : Colors.transparent,
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: isLinked,
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        double remainingTxn = _totalAmount - totalAllocated;
                                        if (remainingTxn > 0) {
                                          double allocVal = remainingTxn > pendingToPay ? pendingToPay : remainingTxn;
                                          _linkedAllocations[uuid] = double.parse(allocVal.toStringAsFixed(2));
                                          _allocControllers[uuid]!.text = allocVal.toStringAsFixed(2);
                                        } else {
                                          _linkedAllocations[uuid] = 0.0;
                                          _allocControllers[uuid]!.text = '';
                                        }
                                      } else {
                                        _linkedAllocations.remove(uuid);
                                        _allocControllers[uuid]!.text = '';
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
                                        'Bill #\${billNo ?? uuid.substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Total: ₹\${grandTotal.toStringAsFixed(2)} | Pending: ₹\${pendingToPay.toStringAsFixed(2)}',
                                        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isLinked)
                              Padding(
                                padding: const EdgeInsets.only(left: 48, right: 8, bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _allocControllers[uuid],
                                        focusNode: _allocFocusNodes[uuid],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelText: 'Amount to Link (₹)',
                                          border: const OutlineInputBorder(),
                                          errorText: currentAlloc > pendingToPay ? 'Exceeds pending' : null,
                                        ),
                                        onChanged: (val) {
                                          setModalState(() {
                                            final parsed = double.tryParse(val);
                                            if (parsed != null && parsed > 0) {
                                              _linkedAllocations[uuid] = parsed;
                                            } else {
                                              _linkedAllocations.remove(uuid);
                                            }
                                          });
                                          setState((){});
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        setModalState(() {
                                          _allocControllers[uuid]!.text = pendingToPay.toStringAsFixed(2);
                                          _linkedAllocations[uuid] = pendingToPay;
                                        });
                                        setState((){});
                                      },
                                      child: const Text('Max'),
                                    ),
                                  ],
                                ),
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
                  onPressed: () {
                    setState((){});
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }`;

    // Note: The regex must correctly replace the ENTIRE old modal function.
    // In Dart, _showLinkBillsModal ends where another function begins or the file ends.
    // We'll replace it by finding the start of _showLinkBillsModal and replacing up to the start of the next method or end of class.
    
    // It's safer to just split by "void _showLinkBillsModal" and then find the matching closing brace.
    const methodStart = content.indexOf('void _showLinkBillsModal() async {');
    if (methodStart !== -1) {
       let braceCount = 0;
       let i = methodStart;
       let foundFirst = false;
       for (; i < content.length; i++) {
           if (content[i] === '{') {
               braceCount++;
               foundFirst = true;
           } else if (content[i] === '}') {
               braceCount--;
           }
           if (foundFirst && braceCount === 0) {
               break;
           }
       }
       const methodEnd = i + 1;
       const oldMethod = content.substring(methodStart, methodEnd);
       content = content.replace(oldMethod, newModal);
    }
    
    // Missing import? We use json.encode, ensure dart:convert is imported
    if (!content.includes("import 'dart:convert';")) {
       content = content.replace(/import 'package:flutter\/material\.dart';/, "import 'package:flutter/material.dart';\nimport 'dart:convert';");
    }

    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Patched ' + filePath);
}

patchScreen('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', true);
patchScreen('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', false);
