const fs = require('fs');
const file = 'c:/Users/lenovo/Desktop/Shaj ERP/lib/features/items/presentation/screens/add_edit_item_screen.dart';

let content = fs.readFileSync(file, 'utf8');

// First fix the existing syntax error in the file!
content = content.replace(`            TextFormField(
                controller: _dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Dimensions (L x W x H)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
              ),
          ]),`, `            Expanded(
              child: TextFormField(
                controller: _dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Dimensions (L x W x H)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
              ),
            ),
          ],
        ),`);

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

// Function to find the end of a block given its start index and opening/closing chars
function findClosing(str, start, open, close) {
  let count = 1;
  for (let i = start + 1; i < str.length; i++) {
    if (str[i] === open) count++;
    else if (str[i] === close) count--;
    if (count === 0) return i;
  }
  return -1;
}

// We want to replace Row(children: [...]) with _buildResponsiveRow([...])
// ONLY IF the children directly contain multiple Expanded() widgets separated by SizedBox
let startIndex = 0;
while (true) {
  let index = content.indexOf('Row(', startIndex);
  if (index === -1) break;

  let endParen = findClosing(content, index + 3, '(', ')');
  if (endParen === -1) {
    startIndex = index + 1;
    continue;
  }

  let rowBlock = content.substring(index, endParen + 1);
  
  // Check if this row is one of our target rows (must be mostly Expanded + SizedBox)
  // Our target rows look like: Row( children: [ Expanded(...), const SizedBox(...), Expanded(...) ] )
  // Let's be very safe: must contain 'children: [' and at least two 'Expanded(' and 'SizedBox('
  if (rowBlock.includes('children:') && 
      rowBlock.split('Expanded(').length >= 3 && 
      rowBlock.includes('SizedBox(') && 
      !rowBlock.includes('Navigator.pop') && // exclude save/cancel rows
      !rowBlock.includes('DropdownButtonFormField') && // Dropdown with "Add Category" button is tricky
      !rowBlock.includes('_selectedSecUnit') // skip the complex secondary unit row
      ) {
    
    // We can confidently replace this block
    // We need to extract the children list.
    let childrenIndex = rowBlock.indexOf('children:');
    let childrenBracketOpen = rowBlock.indexOf('[', childrenIndex);
    let childrenBracketClose = findClosing(rowBlock, childrenBracketOpen, '[', ']');
    
    let childrenContent = rowBlock.substring(childrenBracketOpen + 1, childrenBracketClose);
    
    // The children are: Expanded(...), SizedBox(...), Expanded(...)
    // Let's strip out the SizedBox widgets entirely.
    // Also we want to keep the content inside the Expanded(...) but REMOVE the Expanded() wrapper.
    // Wait, _buildResponsiveRow ADDS Expanded internally. So we MUST remove the Expanded(child: ) wrapper!
    // But what if it has flex? Let's just remove Expanded(child: and the matching closing paren.
    
    let parts = [];
    let childIndex = 0;
    while(true) {
      let expIndex = childrenContent.indexOf('Expanded(', childIndex);
      if (expIndex === -1) break;
      
      let childPropIndex = childrenContent.indexOf('child:', expIndex);
      let childStart = childrenContent.indexOf('(', expIndex);
      let expEnd = findClosing(childrenContent, childStart, '(', ')');
      
      // The actual widget is inside Expanded(child: WIDGET)
      // WIDGET is from childPropIndex + 6 to expEnd
      // But WIDGET might have its own brackets. Actually, childPropIndex + 6 might be space.
      // Better: find child: and find the next widget.
      
      let widgetContent = childrenContent.substring(childPropIndex + 6, expEnd).trim();
      parts.push(widgetContent);
      
      childIndex = expEnd + 1;
    }
    
    if (parts.length >= 2) {
      let newBlock = '_buildResponsiveRow([\n' + parts.map(p => '        ' + p + ',').join('\n') + '\n      ])';
      
      // Replace in content
      content = content.substring(0, index) + newBlock + content.substring(endParen + 1);
      // adjust startIndex
      startIndex = index + newBlock.length;
      continue;
    }
  }
  
  startIndex = index + 1;
}

fs.writeFileSync(file, content, 'utf8');
console.log('Done refactoring UI');
