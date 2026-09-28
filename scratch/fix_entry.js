const fs = require('fs');
const path = 'C:/Users/lenovo/Desktop/Shaj ERP/lib/core/widgets/full_screen_item_entry.dart';
let content = fs.readFileSync(path, 'utf-8');

const importIndex = content.indexOf("import 'package:flutter/material.dart';");
if (importIndex !== -1) {
    content = content.substring(importIndex);
    fs.writeFileSync(path, content, 'utf-8');
    console.log("Fixed full_screen_item_entry.dart");
} else {
    console.log("Could not find import statement in full_screen_item_entry.dart");
}
