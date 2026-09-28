const fs = require('fs');
const path = require('path');

const projectDir = process.cwd();
const collectionsDir = path.join(projectDir, 'lib', 'data', 'local', 'collections');
const files = fs.readdirSync(collectionsDir).filter(f => f.endsWith('.dart') && !f.endsWith('.g.dart'));

let markdown = '# App Schema & Forms Analysis\n\n';
markdown += 'This document lists all the forms (data models) in the application and their corresponding input fields.\n\n';

for (const file of files) {
  const content = fs.readFileSync(path.join(collectionsDir, file), 'utf8');
  
  // Find class name
  const classMatch = content.match(/class\s+([A-Za-z0-9_]+)\s*(?:implements|extends)/);
  if (!classMatch) continue;
  const className = classMatch[1];
  
  markdown += `## ${className} Form\n`;
  markdown += '| Field Type | Field Name | Description / Notes |\n';
  markdown += '|---|---|---|\n';
  
  // Extract fields (lines with types and names, ending in semicolon)
  const lines = content.split('\n');
  for (let line of lines) {
    line = line.trim();
    if (line.startsWith('//') || line.startsWith('@') || line.startsWith('final') || line.startsWith('part ') || line.startsWith('import ') || line.startsWith('class ')) continue;
    
    // match: type name = default; or type name;
    // Example: String? itemName;
    const fieldMatch = line.match(/^([A-Za-z0-9_<>?]+)\s+([A-Za-z0-9_]+)(?:\s*=\s*[^;]+)?;/);
    if (fieldMatch) {
      const type = fieldMatch[1];
      const name = fieldMatch[2];
      
      // skip standard Isar fields if we want, or include them
      if (['id', 'createdAt', 'updatedAt', 'isDeleted', 'isSynced', 'version'].includes(name)) continue;
      
      markdown += `| \`${type}\` | **${name}** | |\n`;
    }
  }
  markdown += '\n';
}

const targetPath = path.join(projectDir, 'scratch', 'schema_analysis.md');
fs.writeFileSync(targetPath, markdown);
