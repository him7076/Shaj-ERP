const fs = require('fs');
let content = fs.readFileSync('lib/router.dart', 'utf8');

// Replace all occurrences where a builder ending with const Something(), is immediately followed by GoRoute(
content = content.replace(/builder:\s*\(context,\s*state\)\s*=>\s*const\s+[a-zA-Z0-9_]+\(\),\s*\n\s*GoRoute\(/g, function(match) {
    return match.replace(/,\s*\n\s*GoRoute\(/, ",\n          ),\n          GoRoute(");
});

// Replace non-const ones if any
content = content.replace(/builder:\s*\(context,\s*state\)\s*=>\s*[a-zA-Z0-9_]+\([^)]*\),\s*\n\s*GoRoute\(/g, function(match) {
    return match.replace(/,\s*\n\s*GoRoute\(/, ",\n          ),\n          GoRoute(");
});

fs.writeFileSync('lib/router.dart', content);
console.log('Fixed ALL missing parenthesis for routes');
