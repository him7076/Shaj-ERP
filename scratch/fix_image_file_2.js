const fs = require('fs');

function fixImageFile(file) {
  if (!fs.existsSync(file)) return;
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

fixImageFile('lib/features/items/presentation/screens/add_edit_item_screen.dart');
fixImageFile('lib/features/tasks/presentation/screens/add_edit_machinery_screen.dart');
