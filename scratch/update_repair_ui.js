const fs = require('fs');
const path = 'lib/features/backup/presentation/screens/data_repair_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const importStr = "import 'package:business_sahaj_erp/core/services/deep_repair_service.dart';\n";
if (!code.includes('deep_repair_service.dart')) {
  code = importStr + code;
}

const targetStr = `Future<void> _startRepair() async {
    setState(() {
      _isRepairing = true;
      _currentTask = 'Clearing deep repair...';
    });

    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isRepairing = false;
      _currentTask = 'Old deep repair system has been completely cleared out.';
      _progress = 1.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deep repair logic cleared successfully.')),
      );
    }
  }`;

const replacement = `Future<void> _startRepair() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final dbService = ref.read(databaseServiceProvider);
    final deepRepairService = ref.read(deepRepairServiceProvider);

    setState(() {
      _isRepairing = true;
      _progress = 0.0;
      _processedRecords = 0;
      _fixedRecords = 0;
      _currentTask = 'Initializing Deep Repair to a NEW firm...';
    });

    try {
      await deepRepairService.runDeepRepair(
        dbService: dbService,
        prefs: prefs,
        onProgress: (task, progress) {
          if (mounted) {
            setState(() {
              _currentTask = task;
              _progress = progress;
            });
          }
        },
      );
      
      if (mounted) {
        setState(() {
          _isRepairing = false;
          _progress = 1.0;
          _currentTask = 'Deep Repair Complete!';
        });

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Expanded(child: Text('Firm Migrated Successfully', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            content: const Text(
              'A completely new database (firm) has been created with all transactions strictly repaired and restored.\\n\\nYou are now actively logged into the new repaired firm.',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRepairing = false;
          _currentTask = 'Repair failed: $e';
        });
      }
    }
  }`;

if (code.includes('Future<void> _startRepair() async {')) {
  // Simple replacement of the method
  const start = code.indexOf('Future<void> _startRepair() async {');
  const end = code.indexOf('Widget build(BuildContext context) {');
  if (start !== -1 && end !== -1) {
    code = code.substring(0, start) + replacement + '\n\n  @override\n  ' + code.substring(end);
    fs.writeFileSync(path, code);
    console.log('Successfully updated _startRepair');
  }
}
