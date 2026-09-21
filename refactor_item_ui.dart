import 'dart:io';

void main() {
  final file = File('lib/features/items/presentation/screens/add_edit_item_screen.dart');
  var content = file.readAsStringSync();

  // 1. Add _buildResponsiveRow helper method if not exists
  if (!content.contains('Widget _buildResponsiveRow(List<Widget> children)')) {
    final helperCode = '''
  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Stack vertically
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: child,
            )).toList(),
          );
        } else {
          // Tablet/Desktop: Row
          List<Widget> rowChildren = [];
          for (int i = 0; i < children.length; i++) {
            rowChildren.add(Expanded(child: children[i]));
            if (i < children.length - 1) {
              rowChildren.add(const SizedBox(width: 16));
            }
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          );
        }
      },
    );
  }

  Widget _buildSectionCard({''';
    content = content.replaceAll('  Widget _buildSectionCard({', helperCode);
  }

  // 2. Replace hardcoded Rows with _buildResponsiveRow
  // This is tricky with regex, so we'll do some targeted replacements for known sections.

  // Helper function to replace a specific row block with _buildResponsiveRow
  String replaceRowBlock(String source, String searchRow, String replacement) {
    if (source.contains(searchRow)) {
      return source.replaceAll(searchRow, replacement);
    }
    return source;
  }

  // We will do a generic replacement for common patterns.
  // Pattern: Row( children: [ Expanded( child: Widget1 ), SizedBox(width: 16), Expanded( child: Widget2 ) ] )
  final regex = RegExp(r'Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*\]\s*,\s*\)', dotAll: true);
  
  content = content.replaceAllMapped(regex, (match) {
    final widget1 = match.group(1);
    final widget2 = match.group(2);
    return '_buildResponsiveRow([\n            \,\n            \,\n          ])';
  });

  // Pattern for 3 items: Row( children: [ Expanded( child: Widget1 ), SizedBox(width: 16), Expanded( child: Widget2 ), SizedBox(width: 16), Expanded( child: Widget3 ) ] )
  final regex3 = RegExp(r'Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*\]\s*,\s*\)', dotAll: true);
  
  content = content.replaceAllMapped(regex3, (match) {
    final widget1 = match.group(1);
    final widget2 = match.group(2);
    final widget3 = match.group(3);
    return '_buildResponsiveRow([\n            \,\n            \,\n            \,\n          ])';
  });

  // Pattern for 4 items
  final regex4 = RegExp(r'Row\(\s*children:\s*\[\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*const SizedBox\(width:\s*\d+\),\s*Expanded\(\s*child:\s*(.*?),\s*\),\s*\]\s*,\s*\)', dotAll: true);
  
  content = content.replaceAllMapped(regex4, (match) {
    final widget1 = match.group(1);
    final widget2 = match.group(2);
    final widget3 = match.group(3);
    final widget4 = match.group(4);
    return '_buildResponsiveRow([\n            \,\n            \,\n            \,\n            \,\n          ])';
  });

  file.writeAsStringSync(content);
  print('Refactored AddEditItemScreen to be responsive.');
}
