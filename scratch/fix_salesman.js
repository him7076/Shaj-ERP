const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(filePath));
    } else if (filePath.endsWith('.dart')) {
      results.push(filePath);
    }
  });
  return results;
}

const files = walk('lib');
let changedFiles = [];

files.forEach(file => {
  let content = fs.readFileSync(file, 'utf8');
  let original = content;

  // Replace content padding
  content = content.replace(/contentPadding: const EdgeInsets\.symmetric\(horizontal: 10, vertical: 12\),/g, 'contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),');
  
  // Remove prefixIcon for Salesman Name
  content = content.replace(/labelText: 'Salesman Name',\s*isDense: true,\s*contentPadding: const EdgeInsets\.symmetric\(horizontal: 4, vertical: 12\),\s*prefixIcon: const Icon\(Icons\.badge_outlined, size: 18\),/g, "labelText: 'Salesman Name',\n                                    isDense: true,\n                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),");

  // Fix suffixIcon
  const suffixRegex = /suffixIcon: Row\([\s\S]*?const SizedBox\(width: 8\),\s*\],\s*\),/g;
  content = content.replace(suffixRegex, `suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_selectedSalesman.isNotEmpty && _selectedSalesman != 'Default Salesman')
                                          InkWell(
                                            onTap: () => setState(() => _selectedSalesman = ''),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4.0),
                                              child: Icon(Icons.close, size: 14),
                                            ),
                                          ),
                                        const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                                        const SizedBox(width: 4),
                                      ],
                                    ),`);

  // We should also replace text size if possible, maybe it's 13.
  if (content !== original) {
    fs.writeFileSync(file, content, 'utf8');
    changedFiles.push(file);
  }
});

console.log('Fixed salesman dropdowns in: ' + changedFiles.join(', '));
