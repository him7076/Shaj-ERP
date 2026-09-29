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
  
  const regex = /final match = RegExp\(r'\\d\+'\)\.firstMatch\(([^)]+)\);\s*if\s*\(match\s*!=\s*null\)\s*{\s*final parsed = int\.tryParse\(match\.group\(0\)!?\)\s*\?\?\s*0;\s*if\s*\(parsed\s*>\s*maxNum\)\s*maxNum\s*=\s*parsed;\s*}/g;
  
  content = content.replace(regex, (match, p1) => {
    return `final matches = RegExp(r'\\d+').allMatches(${p1});
          if (matches.isNotEmpty) {
            final parsed = int.tryParse(matches.last.group(0)!) ?? 0;
            if (parsed > maxNum) maxNum = parsed;
          }`;
  });
  
  const startsWithRegex = /&&\s*[a-zA-Z0-9_.]+\!\.startsWith\([^)]+\)/g;
  content = content.replace(startsWithRegex, '');

  if (content !== original) {
    fs.writeFileSync(file, content, 'utf8');
    changedFiles.push(file);
  }
});

console.log('Fixed files: ' + changedFiles.join(', '));
