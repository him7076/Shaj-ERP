const fs = require('fs');

function fixLinkedBillUuid(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');

    // Replace assignments to _linkedBillUuid
    content = content.replace(/_linkedBillUuid\s*=\s*creditNote\.originalInvoiceUuid;/g, '');
    content = content.replace(/_linkedBillUuid\s*=\s*debitNote\.originalPurchaseUuid;/g, '');
    content = content.replace(/_linkedBillUuid\s*=\s*widget\.initialInvoiceUuid;/g, '');
    content = content.replace(/_linkedBillUuid\s*=\s*widget\.initialPurchaseUuid;/g, '');

    // Now look for where originalInvoiceUuid / originalPurchaseUuid are saved
    // e.g. creditNote.originalInvoiceUuid = _linkedBillUuid;
    // We already patched it to:
    // creditNote.originalInvoiceUuid = _linkedAllocations.isNotEmpty ? json.encode(_linkedAllocations) : null;
    // Let's verify.
    
    // There might be assignments inside the Save method we missed:
    const saveAssignCredit = /(\.\.originalInvoiceUuid\s*=\s*)_linkedBillUuid/g;
    content = content.replace(saveAssignCredit, "$1_linkedAllocations.isNotEmpty ? json.encode(_linkedAllocations) : null");

    const saveAssignDebit = /(\.\.originalPurchaseUuid\s*=\s*)_linkedBillUuid/g;
    content = content.replace(saveAssignDebit, "$1_linkedAllocations.isNotEmpty ? json.encode(_linkedAllocations) : null");

    const editAssignCredit = /(creditNote\.originalInvoiceUuid\s*=\s*)_linkedBillUuid;/g;
    content = content.replace(editAssignCredit, "$1_linkedAllocations.isNotEmpty ? json.encode(_linkedAllocations) : null;");

    const editAssignDebit = /(debitNote\.originalPurchaseUuid\s*=\s*)_linkedBillUuid;/g;
    content = content.replace(editAssignDebit, "$1_linkedAllocations.isNotEmpty ? json.encode(_linkedAllocations) : null;");

    // Fix remaining occurrences if any
    content = content.replace(/_linkedBillUuid/g, "null");

    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Fixed _linkedBillUuid in ' + filePath);
}

fixLinkedBillUuid('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
fixLinkedBillUuid('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');
