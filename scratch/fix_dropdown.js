const fs = require('fs');
const path = 'C:/Users/lenovo/Desktop/Shaj ERP/lib/core/widgets/searchable_item_dropdown.dart';
let content = fs.readFileSync(path, 'utf-8');

// The file has an unterminated comment on line 74: `return const SizedBox.shrink(); /*`
// Let's remove `return const SizedBox.shrink(); /*` completely.
const badString = "return const SizedBox.shrink(); /*";
if (content.includes(badString)) {
    content = content.replace(badString, "");
    fs.writeFileSync(path, content, 'utf-8');
    console.log("Fixed searchable_item_dropdown.dart");
} else {
    console.log("Could not find the bad string in searchable_item_dropdown.dart");
}
