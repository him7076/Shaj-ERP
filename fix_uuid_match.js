const fs = require('fs');

function fixBug(file) {
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace(/p\.uuid == _selectedParty!\.partyName/g, 'p.uuid == _selectedParty!.uuid');
  fs.writeFileSync(file, content);
  console.log('Fixed ' + file);
}

fixBug('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
fixBug('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');
