import 'dart:io';

void main() {
  final dir = Directory('lib/data/repositories');
  if (!dir.existsSync()) {
    print('Directory not found');
    return;
  }

  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('_repository_impl.dart')).toList();

  for (final file in files) {
    if (file.path.contains('item_repository_impl.dart')) continue; // Already done

    String content = file.readAsStringSync();
    
    // Extract entity name from class declaration
    final classRegex = RegExp(r'class\s+(\w+)RepositoryImpl\s+extends\s+BaseIsarRepository<(\w+)>');
    final match = classRegex.firstMatch(content);
    
    if (match == null) continue;
    
    final entityType = match.group(2)!;
    
    // Check if already overridden
    if (content.contains('Future<List<$entityType>> getAll()')) continue;
    if (content.contains('Future<$entityType?> getByUuid(String uuid)')) continue;
    
    // For sync queue, the entity type is SyncQueueTask. Let's just use the matched type.
    final methods = '''

  @override
  Future<List<$entityType>> getAll() async {
    try {
      final items = await collection.filter().isDeletedEqualTo(false).findAll();
      return items;
    } catch (e) {
      throw DatabaseException('Failed to retrieve all active $entityType: \$e');
    }
  }

  @override
  Future<$entityType?> getByUuid(String uuid) async {
    try {
      final entity = await collection.filter().uuidEqualTo(uuid).findFirst();
      if (entity == null || entity.isDeleted) return null;
      return entity;
    } catch (e) {
      throw DatabaseException('Failed to retrieve $entityType by uuid: \$e');
    }
  }
''';

    // Insert before the last closing brace
    final lastBraceIndex = content.lastIndexOf('}');
    if (lastBraceIndex != -1) {
      content = content.substring(0, lastBraceIndex) + methods + '}\n';
      file.writeAsStringSync(content);
      print('Patched \${file.path}');
    }
  }
}
