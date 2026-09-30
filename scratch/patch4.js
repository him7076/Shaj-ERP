const fs = require('fs');
const path = 'lib/features/bank/presentation/screens/manage_cash_and_bank_screen.dart';
let code = fs.readFileSync(path, 'utf8');

// For _loadAccounts
code = code.replace(/if \(widget\.isCash\) \{[\s\S]*?matches = mode == 'cash' \|\| mode\.contains\('cash'\) \|\| mode\.isEmpty;[\s\S]*?if \(\['Transfer', 'Bank Transfer', 'Cash Adjustment'\]\.contains\(t\.transactionType\) && \(target == 'cash' \|\| target\.contains\('cash'\)\)\) \{[\s\S]*?matches = true;[\s\S]*?\}[\s\S]*?\}/g, 
`if (widget.isCash) {
          matches = mode == 'cash' || mode.contains('cash') || mode.isEmpty;
          if (['Transfer', 'Bank Transfer', 'Cash Adjustment'].contains(t.transactionType)) {
            if (mode == 'cash' || mode.contains('cash') || target == 'cash' || target.contains('cash')) {
              matches = true;
            }
          }
        }`);

fs.writeFileSync(path, code);
console.log("Done");
