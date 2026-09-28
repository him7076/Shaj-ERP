const fs = require('fs');
let content = fs.readFileSync('lib/router.dart', 'utf8');

// The issue might be leading spaces or carriage returns
content = content.replace(/\),\r?\n\s*\),\r?\n\s*GoRoute\(/g, '),\r\n          GoRoute(');

fs.writeFileSync('lib/router.dart', content);
console.log('Fixed extra parenthesis');
