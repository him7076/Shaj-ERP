const fs = require('fs');
const file = 'c:/Users/lenovo/Desktop/Shaj ERP/lib/features/items/presentation/screens/add_edit_item_screen.dart';

let buffer = fs.readFileSync(file);
let content = buffer.toString('utf16le');

if (!content.includes('import')) {
  content = buffer.toString('utf8');
}

if (!content.includes('Widget _buildResponsiveRow(List<Widget> children)')) {
  const helperCode = `
  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: child,
            )).toList(),
          );
        } else {
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

  Widget _buildSectionCard({`;
  content = content.replace('  Widget _buildSectionCard({', helperCode);
}

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

fs.writeFileSync(file, content, 'utf8');
console.log('Done refactoring UI');
