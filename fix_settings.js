const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'lib/features/settings/presentation/screens/settings_screen.dart');
let content = fs.readFileSync(file, 'utf8');

// The pattern is:
// try {
//   // handleFirmSwitch clears stale timestamps first, then does full cloud download
//   await ref.read(syncManagerProvider).handleFirmSwitch(id); // or firmId
// } catch (_) {}

const regex = /try\s*\{\s*\/\/\s*handleFirmSwitch[\s\S]*?await\s*ref\.read\(syncManagerProvider\)\.handleFirmSwitch\((.*?)\);\s*\}\s*catch\s*\(_\)\s*\{\}/g;

const newContent = content.replace(regex, (match, p1) => {
    return `// Run handleFirmSwitch in background without awaiting
                                            ref.read(syncManagerProvider).handleFirmSwitch(${p1}).catchError((_) {});`;
});

if (content !== newContent) {
    fs.writeFileSync(file, newContent, 'utf8');
    console.log('Fixed settings_screen.dart');
} else {
    console.log('Regex did not match');
}
