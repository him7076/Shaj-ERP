const fs = require('fs');
let c = fs.readFileSync('lib/core/services/pdf_service.dart', 'utf8');
if (!c.includes('package:intl/intl.dart')) {
  fs.writeFileSync('lib/core/services/pdf_service.dart', "import 'package:intl/intl.dart';\n" + c, 'utf8');
  console.log('Imported intl');
}
