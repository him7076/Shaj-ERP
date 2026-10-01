const fs = require('fs');

function fix(path, isCredit) {
    let content = fs.readFileSync(path, 'utf8');

    if (isCredit) {
        content = content.replace('..rate = e.price', '..rate = e.rate');
        content = content.replace('..discount = e.discountAmount', '..discount = e.discount');
        content = content.replace('..gstRate = e.taxRate', '..gstRate = e.gstRate');
        content = content.replace('..gstAmount = e.taxAmount', '..gstAmount = e.gstAmount');
    } else {
        content = content.replace('..rate = e.price', '..rate = e.rate');
        content = content.replace('..discount = e.discountAmount', '..discount = e.discount');
        content = content.replace('..gstRate = e.taxRate', '..gstRate = e.gstRate');
        content = content.replace('..gstAmount = e.taxAmount', '..gstAmount = e.gstAmount');
        content = content.replace('.parentPurchaseIdEqualTo(pur.id)', '.purchaseIdEqualTo(pur.id)');
    }

    fs.writeFileSync(path, content, 'utf8');
}

fix('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', true);
fix('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', false);
