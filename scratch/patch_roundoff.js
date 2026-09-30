const fs = require('fs');
const path = require('path');

const dirPaths = [
  'lib/features/sales/presentation/screens',
  'lib/features/purchases/presentation/screens',
  'lib/features/expenses/presentation/screens',
  'lib/features/transactions/presentation/screens',
];

function patchRoundOffs() {
  for (const dir of dirPaths) {
    if (!fs.existsSync(dir)) continue;
    const files = fs.readdirSync(dir);
    for (const file of files) {
      if (file.endsWith('.dart')) {
        const filePath = path.join(dir, file);
        let code = fs.readFileSync(filePath, 'utf8');
        
        let originalCode = code;

        // Sales invoice round off
        code = code.replace(/TextFormField\(\s*initialValue:\s*totals\['roundOff'\]!\.toStringAsFixed\(2\),\s*key:\s*ValueKey\('roundoff_.*?'\),\s*keyboardType:.*?,\s*textAlign:.*?,\s*style:.*?,\s*decoration:.*?,\s*onChanged:\s*\(val\)\s*\{\s*ref\.read\(invoiceCartProvider\.notifier\)\.setCustomRoundOff\(double\.tryParse\(val\)\);\s*\},?\s*\)/gs,
          "RoundOffField(value: totals['roundOff'] ?? 0.0, onChanged: (val) { ref.read(invoiceCartProvider.notifier).setCustomRoundOff(double.tryParse(val)); })");

        // Generic transaction screens (Credit note, Debit note, Purchase)
        code = code.replace(/TextFormField\(\s*initialValue:\s*_roundOff\.toStringAsFixed\(2\),\s*key:\s*ValueKey\('roundoff_.*?'\),\s*keyboardType:.*?,\s*textAlign:.*?,\s*style:.*?,\s*decoration:.*?,\s*onChanged:\s*\(val\)\s*\{\s*setState\(\(\)\s*\{\s*_customRoundOff\s*=\s*double\.tryParse\(val\);\s*\}\);\s*_recalculateTotals\(\);\s*\},?\s*\)/gs,
          "RoundOffField(value: _roundOff, onChanged: (val) { setState(() { _customRoundOff = double.tryParse(val); }); _recalculateTotals(); })");

        // Expense screen 
        code = code.replace(/TextFormField\(\s*initialValue:\s*_totalRoundOff\.toStringAsFixed\(2\),\s*key:\s*ValueKey\('roundoff_.*?'\),\s*keyboardType:.*?,\s*textAlign:.*?,\s*style:.*?,\s*decoration:.*?,\s*onChanged:\s*\(val\)\s*\{\s*setState\(\(\)\s*\{\s*_customRoundOff\s*=\s*double\.tryParse\(val\);\s*\}\);\s*_calculateTotals\(\);\s*\},?\s*\)/gs,
          "RoundOffField(value: _totalRoundOff, onChanged: (val) { setState(() { _customRoundOff = double.tryParse(val); }); _calculateTotals(); })");

        if (code !== originalCode) {
          // Add import if not present
          if (!code.includes("import 'package:business_sahaj_erp/core/widgets/round_off_field.dart';")) {
            code = "import 'package:business_sahaj_erp/core/widgets/round_off_field.dart';\n" + code;
          }
          fs.writeFileSync(filePath, code);
          console.log(`Patched RoundOff in ${file}`);
        }
      }
    }
  }
}

patchRoundOffs();
