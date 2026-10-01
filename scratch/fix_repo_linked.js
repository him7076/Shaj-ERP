const fs = require('fs');

function fixRepo(filePath, propName) {
    let content = fs.readFileSync(filePath, 'utf8');
    const regex = /(\.\.paymentMode = 'Credit'\s*\n\s*\.\.remarks = [^\n]+)/;
    
    // Add linkedBillUuid mapping
    const replacement = `$1\n            ..linkedBillUuid = note.${propName}`;
    content = content.replace(regex, replacement);
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Fixed repo ' + filePath);
}

fixRepo('lib/data/repositories/credit_note_repository_impl.dart', 'originalInvoiceUuid');
fixRepo('lib/data/repositories/debit_note_repository_impl.dart', 'originalPurchaseUuid');
