const fs = require('fs');

function fixDayBook() {
    let file = 'lib/features/reports/presentation/screens/day_book_report_screen.dart';
    let code = fs.readFileSync(file, 'utf8');
    
    // Replace: type != 'Transfer' with !['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(type)
    code = code.replace(/type != 'Transfer'/g, "!['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(type)");
    
    // Replace: || v.voucherType == 'Transfer' with || ['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(v.voucherType)
    code = code.replace(/\|\| v.voucherType == 'Transfer'/g, "|| ['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(v.voucherType)");
    
    fs.writeFileSync(file, code);
    console.log('Fixed day_book_report_screen.dart');
}

fixDayBook();
