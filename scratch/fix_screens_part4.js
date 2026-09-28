const fs = require('fs');

let screen = fs.readFileSync('lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart', 'utf8');

screen = screen.replace(/createTransaction\(/g, 'saveTransaction(');
screen = screen.replace(/updateTransaction\(/g, 'saveTransaction(');

// Remove padding from NeuCard and wrap child in Padding
screen = screen.replace(/NeuCard\(\s*padding:\s*const\s*EdgeInsets\.all\(16\),\s*child:\s*Column\(/g, "NeuCard(\nmargin: const EdgeInsets.symmetric(vertical: 4),\nchild: Padding(padding: const EdgeInsets.all(16), child: Column(");

// Wait, the regex might not match exactly. Let's just remove the padding line and add it to the child manually, or we can just replace the specific strings.
screen = screen.replace(/NeuCard\(\s*padding: const EdgeInsets\.all\(16\),/g, "NeuCard(\nmargin: const EdgeInsets.symmetric(vertical: 4),");

fs.writeFileSync('lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart', screen);
console.log('Fixed party transfer screen');
