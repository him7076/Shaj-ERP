const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'lib/core/widgets/custom_drawer.dart');
let content = fs.readFileSync(file, 'utf8');

const regex = /\/\/ Show switching indicator dialog[\s\S]*?Navigator\.of\(context,\s*rootNavigator:\s*true\)\.pop\(\);\s*\/\/\s*Close dialog/g;

const replacement = `try {
                          final db = ref.read(databaseServiceProvider);
                          await db.switchFirm(selectedFirmId, prefs);
                          ref.read(activeFirmIdProvider.notifier).state = selectedFirmId;
                          
                          // Sync Manager clears stale timestamps and downloads data in background
                          ref.read(syncManagerProvider).handleFirmSwitch(selectedFirmId).catchError((_) {});

                          // Invalidate providers to force refresh UI
                          ref.invalidate(sharedPreferencesProvider);
                          
                          if (context.mounted) {`;

let newContent = content.replace(regex, replacement);

if (content !== newContent) {
    fs.writeFileSync(file, newContent, 'utf8');
    console.log('Fixed custom_drawer.dart');
} else {
    console.log('Regex did not match');
}
