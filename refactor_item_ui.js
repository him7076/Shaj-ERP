const fs = require('fs');
const file = 'c:/Users/lenovo/Desktop/Shaj ERP/lib/features/items/presentation/screens/add_edit_item_screen.dart';

// Read file as utf-16le because we know it's UTF-16 LE without BOM
let buffer = fs.readFileSync(file);
let content = buffer.toString('utf16le');

// Check if it's already UTF-8 by looking for null bytes
if (!content.includes('import')) {
  // It was probably utf8 already
  content = buffer.toString('utf8');
}

// 1. Add _buildResponsiveRow helper method if not exists
if (!content.includes('Widget _buildResponsiveRow(List<Widget> children)')) {
  const helperCode = 
  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Stack vertically
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: child,
            )).toList(),
          );
        } else {
          // Tablet/Desktop: Row
          List<Widget> rowChildren = [];
          for (int i = 0; i < children.length; i++) {
            rowChildren.add(Expanded(child: children[i]));
            if (i < children.length - 1) {
              rowChildren.add(const SizedBox(width: 16));
            }
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          );
        }
      },
    );
  }

  Widget _buildSectionCard({;
  content = content.replace('  Widget _buildSectionCard({', helperCode);
}

// 2. Replace hardcoded Rows with _buildResponsiveRow
const regex2 = /Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*\]\s*,\s*\)/g;
content = content.replace(regex2, (match, p1, p2) => {
  return '_buildResponsiveRow([\n            ' + p1.trim() + ',\n            ' + p2.trim() + ',\n          ])';
});

const regex3 = /Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*\]\s*,\s*\)/g;
content = content.replace(regex3, (match, p1, p2, p3) => {
  return '_buildResponsiveRow([\n            ' + p1.trim() + ',\n            ' + p2.trim() + ',\n            ' + p3.trim() + ',\n          ])';
});

const regex4 = /Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*([\s\S]*?),\s*\),\s*\]\s*,\s*\)/g;
content = content.replace(regex4, (match, p1, p2, p3, p4) => {
  return '_buildResponsiveRow([\n            ' + p1.trim() + ',\n            ' + p2.trim() + ',\n            ' + p3.trim() + ',\n            ' + p4.trim() + ',\n          ])';
});

// We must write it back as utf16le because dart format and the user's IDE expect it?
// Actually, flutter supports UTF-8, but let's just write UTF-8 to fix it forever.
fs.writeFileSync(file, content, 'utf8');
console.log('Done refactoring UI');
