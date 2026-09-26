import 'dart:io';

void main() {
  final dir = Directory(r'c:\Users\lenovo\Desktop\Shaj ERP\lib\features');
  final files = dir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.contains('detail') && f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('border: Border(left:')) {
      content = content.replaceAll('border: Border(left:', 'border: isNeu ? null : const Border(left:');
      file.writeAsStringSync(content);
      print('Fixed \${file.path}');
    }
  }
}
