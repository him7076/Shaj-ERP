const fs = require('fs');
let content = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 'utf8');
let match = content.match(/const SizedBox\(width: 8\),[\s\S]*?Internal Bill #[\s\S]*?\]/);
if (match) {
    console.log(match[0]);
} else {
    console.log("No match");
}
