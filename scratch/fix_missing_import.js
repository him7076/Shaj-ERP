const fs = require('fs');

const path = 'lib/features/reports/presentation/screens/deleted_vouchers_screen.dart';
let content = fs.readFileSync(path, 'utf8');

if (!content.includes('party_collection.dart')) {
    content = content.replace(
        "import 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';",
        "import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';\nimport 'package:business_sahaj_erp/data/local/collections/credit_note_collection.dart';"
    );
    fs.writeFileSync(path, content, 'utf8');
    console.log('Added party_collection import.');
} else {
    console.log('Import already exists.');
}
