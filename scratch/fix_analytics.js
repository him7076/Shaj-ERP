const fs = require('fs');
const lines = fs.readFileSync('lib/data/repositories/analytics_repository_impl.dart', 'utf8').split('\n');

const newLogic = `
    for (var p in parties) {
      final bal = p.outstandingBalance ?? p.openingBalance ?? 0.0;
      if (bal > 0) {
        totalOutstanding += bal; // Receivable
      } else if (bal < 0) {
        totalPayable += (-bal);  // Payable
      }
    }
`;

lines.splice(138, 47, newLogic);
fs.writeFileSync('lib/data/repositories/analytics_repository_impl.dart', lines.join('\n'));
