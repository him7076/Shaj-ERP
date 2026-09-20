const fs = require('fs');
const path = require('path');

function replaceBadSubstring(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Replace 0₹9 with 0, 19
    const regex = /substring\(0₹9\)/g;
    if (regex.test(content)) {
        content = content.replace(regex, 'substring(0, 19)');
        fs.writeFileSync(filePath, content, 'utf8');
        console.log('Fixed ' + filePath);
    }
}

replaceBadSubstring(path.join(__dirname, 'lib', 'data', 'repositories', 'order_repository_impl.dart'));
replaceBadSubstring(path.join(__dirname, 'lib', 'data', 'repositories', 'invoice_repository_impl.dart'));

console.log('Done.');
