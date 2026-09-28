const fs = require('fs');

function fixImageFile(file) {
  let c = fs.readFileSync(file, 'utf8');
  if (!c.includes("import 'package:flutter/foundation.dart';")) {
    c = "import 'package:flutter/foundation.dart';\n" + c;
  }
  
  c = c.replace(
    /Image\.file\(\s*File\(([^)]+)\)([^)]*)\)/g,
    "kIsWeb ? Image.network($1$2) : Image.file(File($1)$2)"
  );
  
  fs.writeFileSync(file, c);
  console.log('Fixed ' + file);
}

fixImageFile('lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart');
fixImageFile('lib/features/bank/presentation/screens/transfer_funds_dialog.dart');
