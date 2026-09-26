const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'lib/core/services/web_mock_isar.dart');
let content = fs.readFileSync(file, 'utf8');

// We need to add a timer variable and modify autoSave
const target1 = `  Future<void> autoSave() async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await saveToPrefs(p);
    } catch (e) {
      print('WebMockIsar autoSave failed: $e');
    }
  }`;

const replacement1 = `  Timer? _autoSaveTimer;

  Future<void> autoSave() async {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 100), () async {
      try {
        final p = prefs ?? await SharedPreferences.getInstance();
        await saveToPrefs(p);
      } catch (e) {
        print('WebMockIsar autoSave failed: $e');
      }
    });
  }`;

content = content.replace(target1, replacement1);

// We need to ensure Timer is imported from dart:async if not already
if (!content.includes("import 'dart:async';")) {
  content = "import 'dart:async';\n" + content;
}

fs.writeFileSync(file, content, 'utf8');
console.log('Fixed web_mock_isar.dart autoSave performance issue');
