const fs = require('fs');
const path = 'lib/features/backup/presentation/screens/data_repair_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const startStr = 'Future<void> _startRepair() async {';
const endStr = 'Widget build(BuildContext context) {';
const start = code.indexOf(startStr);
const end = code.indexOf(endStr);

if (start !== -1 && end !== -1) {
  const replacement = `Future<void> _startRepair() async {
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
  }

  @override
  `;
  
  code = code.substring(0, start) + replacement + code.substring(end);
  fs.writeFileSync(path, code);
  console.log('Cleared _startRepair successfully');
} else {
  console.error('Could not find start or end bounds');
}
