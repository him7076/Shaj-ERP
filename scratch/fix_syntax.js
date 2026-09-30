const fs = require('fs');

function fixBOM(filePath) {
  let content = fs.readFileSync(filePath);
  if (content[0] === 0xEF && content[1] === 0xBB && content[2] === 0xBF) {
    content = content.slice(3);
    fs.writeFileSync(filePath, content);
    console.log(`Fixed BOM in ${filePath}`);
  } else if (content.toString('utf8').charCodeAt(0) === 0xFEFF) {
    // Sometimes it's read as string with BOM
    let str = content.toString('utf8');
    str = str.replace(/^\uFEFF/, '');
    fs.writeFileSync(filePath, str, 'utf8');
    console.log(`Fixed BOM string in ${filePath}`);
  }
}

function fixSyntaxError(filePath) {
  let code = fs.readFileSync(filePath, 'utf8');
  let originalCode = code;

  // The error is an extra `),` after `decoration: InputDecoration(labelText: 'Remarks / Notes', ),\n            ),`
  code = code.replace(/decoration: InputDecoration\(labelText: 'Remarks \/ Notes', \),\s*\n\s*\),\s*\n\s*\),/g, 
    "decoration: InputDecoration(labelText: 'Remarks / Notes', ),\n            ),");

  if (code !== originalCode) {
    fs.writeFileSync(filePath, code);
    console.log(`Fixed Syntax Error in ${filePath}`);
  }
}

fixBOM('lib/features/expenses/presentation/screens/add_edit_expense_screen.dart');
fixBOM('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
fixBOM('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');

fixSyntaxError('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
fixSyntaxError('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');
