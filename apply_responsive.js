const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
  if (!fs.existsSync(dir)) return;
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
  });
}

function processFile(filePath) {
  if (!filePath.endsWith('.dart')) return;
  if (filePath.includes('responsive_form_row.dart')) return;

  let content = fs.readFileSync(filePath, 'utf8');
  let originalContent = content;

  // We look for Row( ... children: [ ... Expanded( ... ) ... ] )
  // Since parsing Dart with RegExp is hard due to nested brackets, we will find `Row(` and trace the brackets.
  
  let searchIdx = 0;
  while (true) {
    const rowMatch = content.indexOf('Row(', searchIdx);
    if (rowMatch === -1) break;

    const startIdx = rowMatch;
    const parenStartIdx = startIdx + 3; // index of '('

    let openParens = 0;
    let endIdx = -1;
    let inString = false;
    let stringChar = '';
    let escapeNext = false;

    for (let i = parenStartIdx; i < content.length; i++) {
      let char = content[i];
      if (escapeNext) { escapeNext = false; continue; }
      if (char === '\\') { escapeNext = true; continue; }
      if (char === "'" || char === '"') {
        if (!inString) { inString = true; stringChar = char; }
        else if (stringChar === char) { inString = false; }
        continue;
      }
      if (!inString) {
        if (char === '(') openParens++;
        else if (char === ')') {
          openParens--;
          if (openParens === 0) {
            endIdx = i;
            break;
          }
        }
      }
    }

    if (endIdx !== -1) {
      const rowCode = content.substring(startIdx, endIdx + 1);
      
      // Check if it's a form row. Heuristics:
      // It contains Expanded and one of the form inputs
      const isFormRow = rowCode.includes('Expanded') && 
        (rowCode.includes('TextFormField') || 
         rowCode.includes('NeuInputContainer') || 
         rowCode.includes('Dropdown') || 
         rowCode.includes('Searchable'));
      
      // Do not replace if it's a button row or header row
      const isButtonRow = rowCode.includes('ElevatedButton') || rowCode.includes('OutlinedButton') || rowCode.includes('TextButton');
      
      if (isFormRow && !isButtonRow) {
        // Replace Row with ResponsiveFormRow
        const replacedCode = 'ResponsiveFormRow' + rowCode.substring(3); // remove 'Row'
        content = content.substring(0, startIdx) + replacedCode + content.substring(endIdx + 1);
        searchIdx = startIdx + replacedCode.length;
      } else {
        searchIdx = startIdx + 4;
      }
    } else {
      searchIdx = startIdx + 4;
    }
  }

  if (content !== originalContent) {
    // Add import if needed
    if (!content.includes('responsive_form_row.dart')) {
        const importMatch = content.match(/import\s+['"][^'"]+['"];/);
        if (importMatch) {
            const insertIdx = importMatch.index + importMatch[0].length;
            content = content.substring(0, insertIdx) + "\nimport 'package:business_sahaj_erp/core/widgets/responsive_form_row.dart';" + content.substring(insertIdx);
        } else {
            content = "import 'package:business_sahaj_erp/core/widgets/responsive_form_row.dart';\n" + content;
        }
    }
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Updated ${filePath}`);
  }
}

const featuresDir = path.join('c:', 'Users', 'lenovo', 'Desktop', 'Shaj ERP', 'lib', 'features');
walkDir(featuresDir, processFile);
