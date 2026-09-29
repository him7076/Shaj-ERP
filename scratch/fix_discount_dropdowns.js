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
    } else if (filePath.endsWith('.dart') && (filePath.includes('add_edit') || filePath.includes('item_entry'))) {
      results.push(filePath);
    }
  });
  return results;
}

const files = walk('lib');

files.forEach(file => {
  let c = fs.readFileSync(file, 'utf8');
  let original = c;

  // We find the suffixIcon block.
  const regex = /suffixIcon:\s*Padding\(\s*padding:\s*const\s*EdgeInsets\.only\(right:\s*8\.0\),\s*child:\s*DropdownButtonHideUnderline\(\s*child:\s*DropdownButton<bool>\([\s\S]*?onChanged:\s*\(val\)\s*\{\s*if\s*\(val\s*!=\s*null\)\s*\{\s*setState\(\(\)\s*\{([\s\S]*?)\}\);\s*\}\s*\},?\s*\),\s*\),\s*\),/g;

  c = c.replace(regex, (match, setStateBody) => {
    // Modify setStateBody to use 'idx == 0' instead of 'val'
    let newBody = setStateBody.replace('_isDiscountPercent = val;', '_isDiscountPercent = idx == 0;');
    
    return `suffixIcon: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ToggleButtons(
                            isSelected: [_isDiscountPercent, !_isDiscountPercent],
                            onPressed: (idx) {
                                  setState(() {
                                    ${newBody}
                                  });
                            },
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                            children: const [
                              Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),`;
  });

  if (c !== original) {
    fs.writeFileSync(file, c, 'utf8');
    console.log('Modified ' + file);
  }
});
