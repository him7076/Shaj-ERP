const fs = require('fs');
let content = fs.readFileSync('lib/router.dart', 'utf8');
content = content.replace(/\s*GoRoute\(\s*path: '\/fixed-assets',[\s\S]*?\),/g, '');
fs.writeFileSync('lib/router.dart', content);
console.log('Fixed router regex');
