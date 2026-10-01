const fs = require('fs');

function fixVar(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    content = content.replace(/_totalAmount/g, '_grandTotal');
    fs.writeFileSync(filePath, content, 'utf8');
    console.log('Fixed ' + filePath);
}

fixVar('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
fixVar('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');
