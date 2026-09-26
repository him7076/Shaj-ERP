const fs = require('fs');
const path = require('path');

const files = [
    'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart',
    'lib/features/orders/presentation/screens/add_edit_order_screen.dart',
];

for (const file of files) {
    const filePath = path.join(__dirname, file);
    if (!fs.existsSync(filePath)) continue;

    let content = fs.readFileSync(filePath, 'utf8');

    // Replace the dangling syntax
    // Pattern matches:
    // const SizedBox.shrink(), // old save button
    // // 
    //   style: ...
    //   ...
    // ),
    
    // We can just match the block starting with `const SizedBox.shrink(), // old save button`
    // up to the closing `),` and replace it with just `const SizedBox.shrink(), // old save button`
    const regex = /const SizedBox\.shrink\(\),\s*\/\/\s*old save button[\s\S]*?style:[\s\S]*?\),/g;
    
    const newContent = content.replace(regex, 'const SizedBox.shrink(), // old save button');
    
    if (content !== newContent) {
        fs.writeFileSync(filePath, newContent, 'utf8');
        console.log('Fixed', file);
    }
}
