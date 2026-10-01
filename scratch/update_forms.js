const fs = require('fs');

function updateFile(path) {
  let content = fs.readFileSync(path, 'utf8');
  let target = `                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _billNumberController,
                    readOnly: true,
                    decoration: InputDecoration(labelText: 'Internal Bill # (Auto)',  isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: InputDecoration(
                      labelText: 'Supplier Invoice #',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.link, color: Colors.blue),
                        onPressed: _showLinkBillsModal,
                      ),
                    ),
                  ),
                ),`;
  let target2 = `                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _billNumberController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Internal Bill # (Auto)',  isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: InputDecoration(
                      labelText: 'Supplier Invoice #',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.link, color: Colors.blue),
                        onPressed: _showLinkBillsModal,
                      ),
                    ),
                  ),
                ),`;
  let target3 = target.replace(/const /g, '').replace(/\s+/g, '');

  let replacement = `                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _originalBillNumberController,
                    decoration: const InputDecoration(
                      labelText: 'INV NO',
                      isDense: true,
                    ),
                  ),
                ),`;
  
  if (content.includes(target)) {
    content = content.replace(target, replacement);
    fs.writeFileSync(path, content, 'utf8');
    console.log("Updated " + path + " (target 1)");
  } else if (content.includes(target2)) {
    content = content.replace(target2, replacement);
    fs.writeFileSync(path, content, 'utf8');
    console.log("Updated " + path + " (target 2)");
  } else {
      // Find the index of _billNumberController and then the end of the Expanded.
      let startIdx = content.indexOf('                const SizedBox(width: 8),\n                Expanded(\n                  child: TextFormField(\n                    controller: _billNumberController');
      if (startIdx !== -1) {
          let endStr = '                ),';
          let expanded2Start = content.indexOf('const SizedBox(width: 8)', startIdx + 20);
          let expanded2End = content.indexOf('              ],\n            ),\n          ],\n        ),\n      ),\n      ),', expanded2Start);
          if (expanded2Start !== -1 && expanded2End !== -1) {
              let chunkToReplace = content.substring(startIdx, expanded2End);
              let fallbackReplacement = replacement + "\n";
              content = content.replace(chunkToReplace, fallbackReplacement);
              fs.writeFileSync(path, content, 'utf8');
              console.log("Updated " + path + " (regex/index match)");
          } else {
             console.log("Failed to parse " + path);
          }
      } else {
          console.log("Could not find start in " + path);
      }
  }
}

updateFile('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart');
updateFile('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart');
