import 'dart:io';

void main() {
  final file = File('lib/core/services/web_mock_isar.dart');
  String content = file.readAsStringSync();

  // Fix saveToPrefs
  final saveOld = '''
        try {
          final collectionMaps = list.map((item) => _entityToMap(item)).toList();
          final colJson = jsonEncode(collectionMaps);
          prefsInstance.setString('web_mock_col_\${firmId}_\$collectionName', colJson);
        } catch (colError) {
''';
  final saveNew = '''
        try {
          final collectionMaps = list.map((item) => _entityToMap(item)).toList();
          final colJson = jsonEncode(collectionMaps);
          final compressedBytes = GZipEncoder().encode(utf8.encode(colJson));
          if (compressedBytes != null) {
            final base64Str = base64Encode(compressedBytes);
            prefsInstance.setString('web_mock_col_\${firmId}_\$collectionName', base64Str);
          } else {
            prefsInstance.setString('web_mock_col_\${firmId}_\$collectionName', colJson);
          }
        } catch (colError) {
''';
  content = content.replaceAll(saveOld.trim(), saveNew.trim());

  // Fix loadFromPrefs
  final loadOld = '''
          if (colJson != null && colJson.isNotEmpty) {
            try {
              final listData = jsonDecode(colJson) as List<dynamic>;
              final expectedType = _getTypeForCol(colName);
''';
  final loadNew = '''
          if (colJson != null && colJson.isNotEmpty) {
            try {
              List<dynamic> listData;
              if (colJson.startsWith('[')) {
                listData = jsonDecode(colJson) as List<dynamic>;
              } else {
                try {
                  final compressedBytes = base64Decode(colJson);
                  final jsonBytes = GZipDecoder().decodeBytes(compressedBytes);
                  listData = jsonDecode(utf8.decode(jsonBytes)) as List<dynamic>;
                } catch (_) {
                  listData = jsonDecode(colJson) as List<dynamic>;
                }
              }
              final expectedType = _getTypeForCol(colName);
''';
  content = content.replaceAll(loadOld.trim(), loadNew.trim());

  file.writeAsStringSync(content);
  print('Done!');
}
