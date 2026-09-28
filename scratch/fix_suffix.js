const fs = require('fs');

function fixFile(filepath) {
    let content = fs.readFileSync(filepath, 'utf-8');
    
    // We want to replace the suffixIcon logic in searchable_item_dropdown.dart
    const target = `            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  )
                : null,`;
                
    const replacement = `            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  ),
                TextButton.icon(
                  onPressed: () {
                    final query = controller.text.trim();
                    FocusScope.of(context).unfocus();
                    controller.clear();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => widget.isFixedAsset 
                            ? AddEditFixedAssetScreen(prefilledName: query.isNotEmpty ? query : null) 
                            : AddEditItemScreen(prefilledItem: query.isNotEmpty ? (Item()..itemName = query) : null)
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),`;

    if (content.includes('suffixIcon: controller.text.isNotEmpty')) {
        content = content.replace(target, replacement);
        fs.writeFileSync(filepath, content, 'utf-8');
        console.log("Fixed " + filepath);
    } else {
        console.log("Could not find target in " + filepath);
    }
}

const file = "C:/Users/lenovo/Desktop/Shaj ERP/lib/core/widgets/searchable_item_dropdown.dart";
fixFile(file);
