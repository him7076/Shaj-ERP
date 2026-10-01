const fs = require('fs');

function fixRestoreLogic() {
    const path = 'lib/features/reports/presentation/screens/deleted_vouchers_screen.dart';
    let content = fs.readFileSync(path, 'utf8');

    content = content.replace("type.contains('Credit Note')", "(type.contains('Credit Note') || type.contains('CreditNote'))");
    content = content.replace("type.contains('Debit Note')", "(type.contains('Debit Note') || type.contains('DebitNote'))");
    content = content.replace("type.contains('Invoice')", "(type.contains('Invoice') || type.contains('Sales'))");
    
    fs.writeFileSync(path, content, 'utf8');
    console.log("Fixed restore logic conditions.");
}

function removeLinkIcon(path) {
    let content = fs.readFileSync(path, 'utf8');

    const regex = /suffixIcon:\s*IconButton\([\s\S]*?onPressed:\s*_showLinkBillsModal,\s*\),/g;

    if (regex.test(content)) {
        content = content.replace(regex, '');
        fs.writeFileSync(path, content, 'utf8');
        console.log('Removed link icon from ' + path);
    } else {
        console.log('Regex not matched in ' + path);
    }
}

fixRestoreLogic();
removeLinkIcon('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
removeLinkIcon('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');
