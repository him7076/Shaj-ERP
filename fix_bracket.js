const fs = require('fs');

const path = 'lib/features/transactions/presentation/screens/add_edit_transaction_dialog.dart';
let content = fs.readFileSync(path, 'utf8');

const regex = /\s+\),\r?\n\s+\),\r?\n\s+\);\r?\n\s+\},\r?\n\s+\);/;
const fix = `
                ),
              ),
             ),
            );
          },
        );`;

if (regex.test(content)) {
    content = content.replace(regex, fix);
    fs.writeFileSync(path, content, 'utf8');
    console.log("Fixed bracket!");
} else {
    console.log("Not found.");
}
