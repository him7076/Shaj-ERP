const fs = require('fs');

function fixFile(path) {
    let content = fs.readFileSync(path, 'utf8');
    const regex = /                const SizedBox\(width: 8\),[\s\S]*?Expanded\([\s\S]*?controller: _billNumberController,[\s\S]*?readOnly: true,[\s\S]*?decoration: InputDecoration\(labelText: 'Internal Bill # \(Auto\)',  isDense: true\),[\s\S]*?\),[\s\S]*?\),[\s\S]*?const SizedBox\(width: 8\),[\s\S]*?Expanded\([\s\S]*?child: TextFormField\([\s\S]*?controller: _originalBillNumberController,[\s\S]*?decoration: InputDecoration\([\s\S]*?labelText: 'Supplier Invoice #',[\s\S]*?isDense: true,[\s\S]*?suffixIcon: IconButton\([\s\S]*?icon: const Icon\(Icons\.link, color: Colors\.blue\),[\s\S]*?onPressed: _showLinkBillsModal,[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),/g;

    const replacement = `                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: const InputDecoration(
                      labelText: 'INV NO',
                      isDense: true,
                    ),
                  ),
                ),`;

    if (regex.test(content)) {
        content = content.replace(regex, replacement);
        fs.writeFileSync(path, content, 'utf8');
        console.log("Fixed " + path);
    } else {
        console.log("Could not find pattern in " + path);
    }
}

fixFile('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
fixFile('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');
