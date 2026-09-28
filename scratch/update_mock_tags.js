const fs = require('fs');
let c = fs.readFileSync('lib/core/services/web_mock_isar.dart', 'utf8');

if (!c.includes("'tags': entity.tags,")) {
  c = c.replace(
    "'transactionType': entity.transactionType,",
    "'transactionType': entity.transactionType,\n        'tags': entity.tags,"
  );
}

if (!c.includes("..tags = ")) {
  c = c.replace(
    "..transactionType = map['transactionType'] as String?",
    "..transactionType = map['transactionType'] as String?\n          ..tags = (map['tags'] as List?)?.map((e) => e.toString()).toList()"
  );
}

fs.writeFileSync('lib/core/services/web_mock_isar.dart', c);
