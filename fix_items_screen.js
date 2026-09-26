const fs = require('fs');
const path = require('path');

const screenPath = path.join(__dirname, 'lib/features/items/presentation/screens/items_screen.dart');
let screenContent = fs.readFileSync(screenPath, 'utf8');

const regex = /      final progressController = StreamController<ImportProgressState>\.broadcast\(\);\s+BuildContext\? progressDialogContext;\s+if \(mounted\) \{\s+showDialog\(\s+context: context,\s+barrierDismissible: false,\s+builder: \(ctx\) \{\s+progressDialogContext = ctx;\s+return ImportProgressModal\(\s+title: 'Importing Products & Stock',\s+progressStream: progressController\.stream,\s+\);\s+\},\s+\);\s+\}\s+final dbService = ref\.read\(databaseServiceProvider\);\s+final importResult = await ItemExcelImportService\.importItemsFromBytes\(/g;

const replacement = `      final dbService = ref.read(databaseServiceProvider);
      
      final validationResult = await ItemExcelImportService.validateImport(fileBytes, dbService);
      if (validationResult.errors.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Validation Error: \${validationResult.errors.first}')));
        }
        return;
      }
      
      if (validationResult.hasMissingEntities && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Missing Entities Found'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('The following items were found in the Excel file but are missing in your database. They will be auto-created if you proceed:'),
                  if (validationResult.missingCategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(validationResult.missingCategories.join(', ')),
                  ],
                  if (validationResult.missingBrands.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Brands:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(validationResult.missingBrands.join(', ')),
                  ],
                  if (validationResult.missingUnits.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Units:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(validationResult.missingUnits.join(', ')),
                  ],
                  const SizedBox(height: 16),
                  const Text('Do you want to proceed and auto-create them?'),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed & Auto-Create')),
            ],
          )
        );
        if (proceed != true) return;
      }

      final progressController = StreamController<ImportProgressState>.broadcast();
      BuildContext? progressDialogContext;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            progressDialogContext = ctx;
            return ImportProgressModal(
              title: 'Importing Products & Stock',
              progressStream: progressController.stream,
            );
          },
        );
      }

      final importResult = await ItemExcelImportService.importItemsFromBytes(`;

if (regex.test(screenContent)) {
    screenContent = screenContent.replace(regex, replacement);
    fs.writeFileSync(screenPath, screenContent, 'utf8');
    console.log('Successfully replaced items_screen.dart');
} else {
    console.log('Regex did not match!');
}
