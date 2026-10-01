const fs = require('fs');

function fixLinkIcon(path) {
    let content = fs.readFileSync(path, 'utf8');

    const regex = /Expanded\(\s*child:\s*TextFormField\(\s*controller:\s*_originalBillNumberController,\s*decoration:\s*const\s*InputDecoration\(\s*labelText:\s*'INV NO',\s*isDense:\s*true,\s*\),\s*\),\s*\),/g;

    const replacement = `Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: InputDecoration(
                      labelText: 'INV NO',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.link, color: _linkedBillUuid != null ? Colors.green : null),
                        tooltip: 'Link to Pending Bill',
                        onPressed: _showLinkBillsModal,
                      ),
                    ),
                  ),
                ),`;

    if (regex.test(content)) {
        content = content.replace(regex, replacement);
        fs.writeFileSync(path, content, 'utf8');
        console.log('Successfully injected link icon in ' + path);
    } else {
        console.log('Regex not matched in ' + path);
    }
}

fixLinkIcon('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
fixLinkIcon('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');
