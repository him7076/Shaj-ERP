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

        // We will split the file by "TextFormField(" and find the ones containing "roundoff_"
        let parts = code.split('TextFormField(');
        for (let i = 1; i < parts.length; i++) {
          let part = parts[i];
          if (part.includes("key: ValueKey('roundoff_")) {
            // Find the end of this TextFormField call. Since there can be nested parentheses, we need a balancer.
            let open = 1;
            let j = 0;
            while (open > 0 && j < part.length) {
              if (part[j] === '(') open++;
              if (part[j] === ')') open--;
              j++;
            }
            if (open === 0) {
              let fieldCode = part.substring(0, j);
              // Extract logic based on initialValue
              if (fieldCode.includes("totals['roundOff']")) {
                parts[i] = "RoundOffField(value: totals['roundOff'] ?? 0.0, onChanged: (val) { ref.read(invoiceCartProvider.notifier).setCustomRoundOff(double.tryParse(val)); })" + part.substring(j);
              } else if (fieldCode.includes("_roundOff.toStringAsFixed(2)")) {
                parts[i] = "RoundOffField(value: _roundOff, onChanged: (val) { setState(() { _customRoundOff = double.tryParse(val); }); _recalculateTotals(); })" + part.substring(j);
              } else if (fieldCode.includes("_totalRoundOff.toStringAsFixed(2)")) {
                parts[i] = "RoundOffField(value: _totalRoundOff, onChanged: (val) { setState(() { _customRoundOff = double.tryParse(val); }); _calculateTotals(); })" + part.substring(j);
              }
            }
          } else {
             // For safety, re-add the "TextFormField(" since we split by it.
             // Wait! the split approach means we have to rejoin with "TextFormField(".
             // If we already replaced it with "RoundOffField", we shouldn't add "TextFormField(".
             // We can do this cleaner:
          }
        }
        
        let newCode = parts[0];
        for (let i = 1; i < parts.length; i++) {
            if (parts[i].startsWith("RoundOffField(")) {
               newCode += parts[i];
            } else {
               newCode += "TextFormField(" + parts[i];
            }
        }

        if (newCode !== originalCode) {
          if (!newCode.includes("import 'package:business_sahaj_erp/core/widgets/round_off_field.dart';")) {
            newCode = "import 'package:business_sahaj_erp/core/widgets/round_off_field.dart';\n" + newCode;
          }
          fs.writeFileSync(filePath, newCode);
          console.log(`Patched RoundOff in ${file}`);
        }
      }
    }
  }
}

patchRoundOffs();
