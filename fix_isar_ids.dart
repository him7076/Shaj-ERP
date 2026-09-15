import 'dart:io';

void main() {
  final maxSafe = BigInt.parse('9007199254740991');
  final minSafe = BigInt.parse('-9007199254740991');

  final dir = Directory('lib/data/local/collections');
  if (!dir.existsSync()) return;

  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.g.dart'));

  for (final file in files) {
    var content = file.readAsStringSync();
    
    // Regular expression to match id: <number>,
    final regex = RegExp(r'id:\s*(-?\d+),');
    
    var newContent = content.replaceAllMapped(regex, (match) {
      final numStr = match.group(1)!;
      final num = BigInt.parse(numStr);
      
      if (num > maxSafe || num < minSafe) {
        // Truncate to 15 digits
        final isNegative = num.isNegative;
        final absStr = num.abs().toString();
        final truncated = absStr.substring(0, 15);
        final newNumStr = isNegative ? '-$truncated' : truncated;
        return 'id: $newNumStr,';
      }
      return match.group(0)!;
    });

    if (content != newContent) {
      file.writeAsStringSync(newContent);
      print('Patched ${file.path}');
    }
  }
}
