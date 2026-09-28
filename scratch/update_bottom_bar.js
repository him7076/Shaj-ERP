const fs = require('fs');

const path = 'lib/core/widgets/full_screen_item_entry.dart';
let content = fs.readFileSync(path, 'utf8');

// The bottomNavigationBar starts at "bottomNavigationBar: Container("
// We'll just replace the entire block from "bottomNavigationBar:" to the end of the file.
// Since it's at the end of the _FullScreenItemEntryState build method, we can do this.

const searchStart = "      bottomNavigationBar: Container(";
const searchIndex = content.lastIndexOf(searchStart);

if (searchIndex !== -1) {
  const beforeContent = content.substring(0, searchIndex);
  
  const replaceStr = `      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                        child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 2,
                        ),
                        child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}`;

  fs.writeFileSync(path, beforeContent + replaceStr, 'utf8');
  console.log('Successfully updated bottomNavigationBar via write_to_file script.');
} else {
  console.log('Could not find searchStart.');
}
