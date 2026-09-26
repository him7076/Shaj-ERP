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

    // Remove the leftover shape: ... \n ), \n ),
    const regex = /const SizedBox\.shrink\(\),\s*\/\/\s*old save button\s*shape:\s*RoundedRectangleBorder\(borderRadius:\s*BorderRadius\.circular\(12\)\),\s*\),\s*\),/g;
    const newContent = content.replace(regex, 'const SizedBox.shrink(), // old save button');

    if (content !== newContent) {
        fs.writeFileSync(filePath, newContent, 'utf8');
        console.log('Fixed', file);
    }
}
