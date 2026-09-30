const fs = require('fs');
const path = require('path');

const filePath = path.join('lib', 'core', 'services', 'web_mock_isar.dart');
let content = fs.readFileSync(filePath, 'utf8');

// 1. Add _parseDateTime method
const parseDateTimeMethod = `
  DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) {
      final t = int.tryParse(val);
      if (t != null) return DateTime.fromMillisecondsSinceEpoch(t);
      return DateTime.tryParse(val);
    }
    return null;
  }
`;

if (!content.includes('_parseDateTime')) {
    content = content.replace(
        '  String? _parseString(dynamic val) {',
        parseDateTimeMethod + '\n  String? _parseString(dynamic val) {'
    );
}

// 2. Replace DateTime.parse patterns
// pattern 1: map['key'] != null ? DateTime.parse(map['key'] as String) : DateTime.now()
// pattern 2: map['key'] != null ? DateTime.parse(map['key'] as String) : null
content = content.replace(/map\['([^']+)'\] != null \? DateTime\.parse\(map\['\1'\] as String\) : DateTime\.now\(\)/g, '_parseDateTime(map[\'$1\']) ?? DateTime.now()');
content = content.replace(/map\['([^']+)'\] != null \? DateTime\.parse\(map\['\1'\] as String\) : null/g, '_parseDateTime(map[\'$1\'])');

// pattern 3 (just in case): DateTime.parse(map['key'] as String) -> _parseDateTime(map['key']) ?? DateTime.now()
// Not doing this broadly to avoid breaking things, regex above covers the exact usages in WebMockIsar.

fs.writeFileSync(filePath, content, 'utf8');
console.log('web_mock_isar.dart patched successfully!');
