
import 'dart:io';
void main() {
  final file = File('lib/core/services/sync_service.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('-CLOUD', '-\');
  file.writeAsStringSync(content);
  print('Dart replacement complete.');
}

