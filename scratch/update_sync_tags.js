const fs = require('fs');
let c = fs.readFileSync('lib/core/services/sync_service.dart', 'utf8');

if (!c.includes("'tags': e.tags,")) {
  c = c.replace(
    "'transactionType': e.transactionType,",
    "'transactionType': e.transactionType,\n          'tags': e.tags,"
  );
}

if (!c.includes("..tags = ")) {
  c = c.replace(
    "..transactionType = data['transactionType']",
    "..transactionType = data['transactionType']\n          ..tags = (data['tags'] as List?)?.map((e) => e.toString()).toList()"
  );
}

fs.writeFileSync('lib/core/services/sync_service.dart', c);
