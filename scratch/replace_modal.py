import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'ItemSearchPickerModal.show' not in content:
        return

    print(f"Processing {filepath}")

    # Ensure import exists
    if 'full_screen_item_entry.dart' not in content:
        content = content.replace(
            "import 'package:flutter/material.dart';",
            "import 'package:flutter/material.dart';\nimport 'package:business_sahaj_erp/core/widgets/full_screen_item_entry.dart';"
        )

    # We want to replace blocks like:
    # final selectedItem = await ItemSearchPickerModal.show(context, excludeBundles: true);
    # if (selectedItem != null) {
    #   await _handleItemAdded(selectedItem);
    # }
    
    # We will use regex to find these patterns.
    # Pattern: 
    # (?:final\s+\w+\s*=\s*)?await\s+ItemSearchPickerModal\.show\s*\([^;]+?;
    # \s*if\s*\([^\{]+\{\s*(?:await\s+)?(_handleItemAdded|_addItemLine)\([^;]+\);\s*(?:ref\.invalidate[^;]+;)?\s*\}
    
    pattern1 = re.compile(
        r'(?:final\s+\w+\s*=\s*)?await\s+ItemSearchPickerModal\.show\([^,]+,\s*(excludeBundles|onlyBundles|isPurchase)?\s*[:=]\s*(true|false)(?:,\s*(excludeBundles|onlyBundles|isPurchase)\s*[:=]\s*(true|false))?\);\s*'
        r'if\s*\([^\{]+\{\s*(?:await\s+)?(_handleItemAdded|_addItemLine)\(([^)]+)\);\s*(?:ref\.invalidate[^;]+;\s*)?\}',
        re.MULTILINE
    )

    def replacer(match):
        arg1_key = match.group(1)
        arg1_val = match.group(2)
        arg2_key = match.group(3)
        arg2_val = match.group(4)
        func_name = match.group(5)
        var_name = match.group(6)
        
        args = []
        if arg1_key:
            args.append(f"{arg1_key}: {arg1_val}")
        if arg2_key:
            args.append(f"{arg2_key}: {arg2_val}")
        
        args_str = ", ".join(args)
        if args_str:
            args_str = ", " + args_str
            
        return f"""FullScreenItemEntry.show(
      context{args_str},
      onAdd: (data) async {{
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate; // pass rate via item
        tempSelected.item.gstRate = data.gstRate;
        await {func_name}(tempSelected);
      }},
    );"""

    content = pattern1.sub(replacer, content)

    # Let's also do a simpler regex in case the above one misses something (like without if statement)
    # Wait, the screens always do: if (selectedItem != null) { _handleItemAdded(selectedItem); }
    # So the above pattern is good, but let's make it more flexible.

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

base_dir = r"c:\Users\lenovo\Desktop\Shaj ERP\lib\features"
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Done")
