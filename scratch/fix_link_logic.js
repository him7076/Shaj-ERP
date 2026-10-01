const fs = require('fs');

function fixLinkLogic(path, isCredit) {
    let content = fs.readFileSync(path, 'utf8');

    // Add _linkedBillUuid variable
    if (!content.includes('String? _linkedBillUuid;')) {
        content = content.replace(
            'TextEditingController _originalBillNumberController = TextEditingController();',
            'TextEditingController _originalBillNumberController = TextEditingController();\n  String? _linkedBillUuid;'
        );
    }

    // Populate _linkedBillUuid in init
    if (isCredit) {
        content = content.replace(
            '_originalBillNumberController.text = creditNote.originalInvoiceNumber ?? \'\';',
            '_originalBillNumberController.text = creditNote.originalInvoiceNumber ?? \'\';\n        _linkedBillUuid = creditNote.originalInvoiceUuid;'
        );
        content = content.replace(
            'creditNote.originalInvoiceUuid = _existingCreditNote?.originalInvoiceUuid;',
            'creditNote.originalInvoiceUuid = _linkedBillUuid;'
        );
    } else {
        content = content.replace(
            '_originalBillNumberController.text = debitNote.originalPurchaseNumber ?? \'\';',
            '_originalBillNumberController.text = debitNote.originalPurchaseNumber ?? \'\';\n        _linkedBillUuid = debitNote.originalPurchaseUuid;'
        );
        content = content.replace(
            'debitNote.originalPurchaseUuid = _existingDebitNote?.originalPurchaseUuid;',
            'debitNote.originalPurchaseUuid = _linkedBillUuid;'
        );
    }
    
    // In _showLinkBillsModal, replace the condition that checks if linked
    const oldConditionCredit = `final isLinked = _originalBillNumberController.text == (true ? bill.invoiceNumber : bill.purchaseNumber);`;
    const oldConditionDebit = `final isLinked = _originalBillNumberController.text == (false ? bill.invoiceNumber : bill.purchaseNumber);`;
    
    content = content.replace(oldConditionCredit, `final isLinked = _linkedBillUuid == bill.uuid;`);
    content = content.replace(oldConditionDebit, `final isLinked = _linkedBillUuid == bill.uuid;`);
    
    // Also change the pending amount condition to include the linked bill uuid
    const oldPendingCondCredit1 = `return pendingAmount > 0 || _originalBillNumberController.text == inv.invoiceNumber;`;
    const oldPendingCondCredit2 = `return pendingAmount > 0 || _originalBillNumberController.text == pur.purchaseNumber;`;
    
    content = content.replace(oldPendingCondCredit1, `return pendingAmount > 0 || _linkedBillUuid == inv.uuid;`);
    content = content.replace(oldPendingCondCredit2, `return pendingAmount > 0 || _linkedBillUuid == pur.uuid;`);
    
    const oldPendingCondDebit1 = `return pendingAmount > 0 || _originalBillNumberController.text == inv.invoiceNumber;`;
    const oldPendingCondDebit2 = `return pendingAmount > 0 || _originalBillNumberController.text == pur.purchaseNumber;`;
    
    content = content.replace(oldPendingCondDebit1, `return pendingAmount > 0 || _linkedBillUuid == inv.uuid;`);
    content = content.replace(oldPendingCondDebit2, `return pendingAmount > 0 || _linkedBillUuid == pur.uuid;`);

    // Fix the onChange
    if (isCredit) {
        const oldOnChange = `                                  if (val == true) {
                                    _originalBillNumberController.text = billNo ?? '';
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = bill.uuid;
                                    }
                                  } else {
                                    _originalBillNumberController.clear();
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = null;
                                    }
                                  }`;
        const newOnChange = `                                  if (val == true) {
                                    _linkedBillUuid = bill.uuid;
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = bill.uuid;
                                    }
                                  } else {
                                    _linkedBillUuid = null;
                                    if (_existingCreditNote != null) {
                                      _existingCreditNote!.originalInvoiceUuid = null;
                                    }
                                  }`;
        content = content.replace(oldOnChange, newOnChange);
    } else {
        const oldOnChange = `                                  if (val == true) {
                                    _originalBillNumberController.text = billNo ?? '';
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = bill.uuid;
                                    }
                                  } else {
                                    _originalBillNumberController.clear();
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = null;
                                    }
                                  }`;
        const newOnChange = `                                  if (val == true) {
                                    _linkedBillUuid = bill.uuid;
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = bill.uuid;
                                    }
                                  } else {
                                    _linkedBillUuid = null;
                                    if (_existingDebitNote != null) {
                                      _existingDebitNote!.originalPurchaseUuid = null;
                                    }
                                  }`;
        content = content.replace(oldOnChange, newOnChange);
    }
    
    // Check if initialInvoiceUuid was used to pre-fill the _linkedBillUuid
    const initHook = `_originalBillNumberController.text = widget.initialInvoiceNumber!;`;
    const newInitHook = `_originalBillNumberController.text = widget.initialInvoiceNumber!;\n        _linkedBillUuid = widget.initialInvoiceUuid;`;
    content = content.replace(initHook, newInitHook);

    fs.writeFileSync(path, content, 'utf8');
    console.log('Fixed link logic in ' + path);
}

fixLinkLogic('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', true);
fixLinkLogic('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', false);
