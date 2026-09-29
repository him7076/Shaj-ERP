const fs = require('fs');

let c1 = fs.readFileSync('lib/core/widgets/searchable_item_dropdown.dart', 'utf8');
c1 = c1.replace(/if\s*\(query\.isEmpty\)\s*{[\s\S]*?}\s*else\s*{([\s\S]*?)\s*}\s*final createActionItem = Item\(\)/, (match, p1) => {
  return 'if (query.isEmpty) return const Iterable<Item>.empty();\n' + p1 + '\n        final createActionItem = Item()';
});
c1 = c1.replace(/itemName = query\.isNotEmpty[\s\S]*?\+ Create New Item';/, 'itemName = \'+ Create New "$query"\';');
fs.writeFileSync('lib/core/widgets/searchable_item_dropdown.dart', c1, 'utf8');
console.log('Fixed item dropdown');

if (fs.existsSync('lib/core/widgets/searchable_party_dropdown.dart')) {
  let c2 = fs.readFileSync('lib/core/widgets/searchable_party_dropdown.dart', 'utf8');
  c2 = c2.replace(/if\s*\(query\.isEmpty\)\s*{[\s\S]*?}\s*else\s*{([\s\S]*?)\s*}\s*final createActionParty = Party\(\)/, (match, p1) => {
    return 'if (query.isEmpty) return const Iterable<Party>.empty();\n' + p1 + '\n        final createActionParty = Party()';
  });
  c2 = c2.replace(/partyName = query\.isNotEmpty[\s\S]*?\+ Create New Party';/, 'partyName = \'+ Create New "$query"\';');
  fs.writeFileSync('lib/core/widgets/searchable_party_dropdown.dart', c2, 'utf8');
  console.log('Fixed party dropdown');
}
