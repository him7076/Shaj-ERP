import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.20);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedScaler),
            child: child ?? const SizedBox.shrink(),
          );
        },'''

new_code = '''        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child ?? const SizedBox.shrink(),
          );
        },'''

old_code_crlf = old_code.replace('\n', '\r\n')

if old_code in content:
    content = content.replace(old_code, new_code)
elif old_code_crlf in content:
    content = content.replace(old_code_crlf, new_code)
else:
    print('NOT FOUND!')

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)