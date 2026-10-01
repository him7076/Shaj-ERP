const fs = require('fs');

function fix(f, oldText, newText) {
  let t = fs.readFileSync(f, 'utf8');
  t = t.replace(oldText, newText);
  fs.writeFileSync(f, t);
}

fix('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', 
`            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save DebitNote Bill'),
              onPressed: _saveBill,
              style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),`,
`            ElevatedButton(
              onPressed: _saveBill,
              style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline), SizedBox(width: 8), Text('Save DebitNote Bill')]),
            ),`);

fix('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 
`            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save CreditNote Bill'),
              onPressed: _saveBill,
              style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),`,
`            ElevatedButton(
              onPressed: _saveBill,
              style: (ref.watch(themeProvider).themeType == ThemeType.neumorphism) ? ElevatedButton.styleFrom(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))) : ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline), SizedBox(width: 8), Text('Save CreditNote Bill')]),
            ),`);
