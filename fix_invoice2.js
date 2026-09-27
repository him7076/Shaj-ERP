const fs = require('fs');
let content = fs.readFileSync('lib/features/sales/presentation/screens/invoice_detail_screen.dart', 'utf8');

if (!content.includes('bank_account_collection.dart')) {
  content = content.replace(
    "import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';",
    "import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';\nimport 'package:business_sahaj_erp/data/local/collections/bank_account_collection.dart';"
  );
  fs.writeFileSync('lib/features/sales/presentation/screens/invoice_detail_screen.dart', content);
  console.log('Added import');
} else {
  console.log('Import already exists');
}
