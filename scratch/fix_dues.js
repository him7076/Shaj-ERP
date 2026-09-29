const fs = require('fs');

function fixPayables() {
  let code = fs.readFileSync('lib/features/reports/presentation/screens/payables_screen.dart', 'utf8');
  let lines = code.split('\n');

  let start = lines.findIndex(l => l.includes('return FutureBuilder<List<Purchase>>('));
  let end = lines.findIndex(l => l.includes('final cities ='));
  
  if (start !== -1 && end !== -1) {
    const replace = `          double getPartyDue(Party p) {
            final bal = p.outstandingBalance ?? p.openingBalance ?? 0.0;
            if (bal < 0) return -bal; // Payable amount is positive here
            return 0.0;
          }

          final supplierParties = allParties.where((p) => getPartyDue(p) > 0).toList();
          `;
    lines.splice(start, end - start, replace);
    
    // Remove the extra closing braces for FutureBuilder
    const searchEnd = `          );
        },
          );
        },`;
    const replaceEnd = `          );
        },`;
    code = lines.join('\n');
    code = code.replace(searchEnd, replaceEnd);
    fs.writeFileSync('lib/features/reports/presentation/screens/payables_screen.dart', code);
    console.log("payables fixed");
  }
}

function fixReceivables() {
  let code = fs.readFileSync('lib/features/reports/presentation/screens/receivables_screen.dart', 'utf8');
  let lines = code.split('\n');

  let start = lines.findIndex(l => l.includes('return FutureBuilder<List<Invoice>>('));
  let end = lines.findIndex(l => l.includes('final cities ='));
  
  if (start !== -1 && end !== -1) {
    const replace = `          double getPartyDue(Party p) {
            final bal = p.outstandingBalance ?? p.openingBalance ?? 0.0;
            if (bal > 0) return bal; // Receivable amount is positive here
            return 0.0;
          }

          final customerParties = allParties.where((p) => getPartyDue(p) > 0).toList();
          `;
    lines.splice(start, end - start, replace);
    
    // Remove the extra closing braces for FutureBuilder
    const searchEnd = `          );
        },
          );
        },`;
    const replaceEnd = `          );
        },`;
    code = lines.join('\n');
    code = code.replace(searchEnd, replaceEnd);
    fs.writeFileSync('lib/features/reports/presentation/screens/receivables_screen.dart', code);
    console.log("receivables fixed");
  }
}

fixPayables();
fixReceivables();
