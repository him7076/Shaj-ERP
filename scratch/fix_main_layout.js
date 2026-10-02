const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '..', 'lib', 'core', 'widgets', 'main_layout.dart');
let content = fs.readFileSync(filePath, 'utf8');

const target = `      return Scaffold(
        key: scaffoldKey,`;

const replacement = `      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            if (location != '/' && location != '/dashboard') {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                ref.read(navigationIndexProvider.notifier).state = 0;
                context.go('/dashboard');
              }
            }
          }
        },
        child: Scaffold(
          key: scaffoldKey,`;

if (content.includes(target)) {
  content = content.replace(target, replacement);
  // Add closing parenthesis for PopScope at end of scaffold
  content = content.replace(`          ),
      );
    }`, `          ),
        ),
      );
    }`);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log('SUCCESS: main_layout.dart updated');
} else {
  console.log('Target string not found');
}
