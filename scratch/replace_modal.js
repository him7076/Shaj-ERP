const fs = require('fs');
const path = require('path');

function processFile(filepath) {
    let content = fs.readFileSync(filepath, 'utf-8');
    
    if (!content.includes('ItemSearchPickerModal.show')) {
        return;
    }
    
    console.log(`Processing ${filepath}`);

    if (!content.includes('full_screen_item_entry.dart')) {
        content = content.replace(
            "import 'package:flutter/material.dart';",
            "import 'package:flutter/material.dart';\nimport 'package:business_sahaj_erp/core/widgets/full_screen_item_entry.dart';"
        );
    }

    const regex = /(?:final\s+\w+\s*=\s*)?await\s+ItemSearchPickerModal\.show\([^,]+,\s*(excludeBundles|onlyBundles|isPurchase)?\s*[:=]\s*(true|false)(?:,\s*(excludeBundles|onlyBundles|isPurchase)\s*[:=]\s*(true|false))?\);\s*if\s*\([^\{]+\{\s*(?:await\s+)?(_handleItemAdded|_addItemLine)\(([^)]+)\);\s*(?:ref\.invalidate[^;]+;\s*)?\}/gm;

    content = content.replace(regex, (match, arg1_key, arg1_val, arg2_key, arg2_val, func_name, var_name) => {
        let args = [];
        if (arg1_key) args.push(`${arg1_key}: ${arg1_val}`);
        if (arg2_key) args.push(`${arg2_key}: ${arg2_val}`);
        
        let argsStr = args.join(', ');
        if (argsStr) argsStr = ', ' + argsStr;
        
        return `FullScreenItemEntry.show(
      context${argsStr},
      onAdd: (data) async {
        final tempSelected = SelectedProductData(data.item);
        tempSelected.item.sellRate = data.rate;
        tempSelected.item.buyRate = data.rate; // fallback
        tempSelected.item.gstRate = data.gstRate;
        // Since cart updates only default to 1 qty, we'll need to manually set it after!
        await ${func_name}(tempSelected);
      },
    );`;
    });

    // We also need to fix SelectedProductData constructor if it's missing or we can just use the item directly in some cases.
    // Wait! _addItemLine takes an `Item` in purchase screen, NOT SelectedProductData? Let's check!
    // In add_edit_purchase_screen, the line is:
    // final selectedItem = await ItemSearchPickerModal.show(context, isPurchase: true);
    // if (selectedItem != null) {
    //   _addItemLine(selectedItem);
    // }
    
    // So selectedItem is a SelectedProductData? Yes, because ItemSearchPickerModal.show returns SelectedProductData.

    fs.writeFileSync(filepath, content, 'utf-8');
}

function walkSync(dir, filelist = []) {
    let files = fs.readdirSync(dir);
    for (let file of files) {
        let filepath = path.join(dir, file);
        let stat = fs.statSync(filepath);
        if (stat.isDirectory()) {
            filelist = walkSync(filepath, filelist);
        } else if (file.endsWith('.dart')) {
            filelist.push(filepath);
        }
    }
    return filelist;
}

const baseDir = path.join(__dirname, '..', 'lib', 'features');
const dartFiles = walkSync(baseDir);

for (let file of dartFiles) {
    processFile(file);
}

console.log("Done");
