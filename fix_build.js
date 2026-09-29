const fs = require('fs');

const path = 'lib/features/transactions/presentation/screens/add_edit_party_transfer_screen.dart';
let content = fs.readFileSync(path, 'utf8');

const regex = /  @override\r?\n  void initState\(\) \{\r?\n    super\.initState\(\);\r?\n    if \(widget\.existingTransaction == null\) \{\r?\n      _fetchVoucherNumber\(\);\r?\n    \}\r?\n    _allocations = Map\.from\(widget\.initialAllocations\);\r?\n    _loadBills\(\);\r?\n  \}/;

const fix = `  @override
  void initState() {
    super.initState();
    _allocations = Map.from(widget.initialAllocations);
    _loadBills();
  }`;

if (regex.test(content)) {
    content = content.replace(regex, fix);
    fs.writeFileSync(path, content, 'utf8');
    console.log("Fixed!");
} else {
    console.log("Not found.");
}
