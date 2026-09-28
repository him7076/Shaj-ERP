const fs = require('fs');

function fixFile(filepath) {
    let content = fs.readFileSync(filepath, 'utf-8');
    
    // We want to replace the bundle item modal logic.
    const regex = /final selected = await ItemSearchPickerModal\.show\(ctx, excludeBundles: true\);\s*if \(selected != null && selected\.item\.uuid != null\) \{\s*if \(!uuids\.contains\(selected\.item\.uuid\)\) \{\s*setSheetState\(\(\) \{\s*uuids\.add\(selected\.item\.uuid!\);\s*quantities\.add\(1\.0\);\s*units\.add\(selected\.item\.primaryUnitName \?\? 'PCS'\);\s*rates\.add\(selected\.item\.sellRate \?\? 0\.0\);\s*buyRates\.add\(selected\.item\.buyRate \?\? 0\.0\);\s*gstRates\.add\(selected\.item\.gstRate \?\? 18\.0\);\s*descriptions\.add\(selected\.item\.description \?\? ''\);\s*\}\);\s*\}\s*\}/g;
    
    const replacement = `FullScreenItemEntry.show(
                          ctx,
                          excludeBundles: true,
                          onAdd: (data) {
                            if (data.item.uuid != null) {
                              if (!uuids.contains(data.item.uuid)) {
                                setSheetState(() {
                                  uuids.add(data.item.uuid!);
                                  quantities.add(data.quantity);
                                  units.add(data.item.primaryUnitName ?? 'PCS');
                                  rates.add(data.rate);
                                  buyRates.add(data.item.buyRate ?? 0.0);
                                  gstRates.add(data.gstRate);
                                  descriptions.add(data.item.description ?? '');
                                });
                              }
                            }
                          },
                        );`;

    if (regex.test(content)) {
        content = content.replace(regex, replacement);
        fs.writeFileSync(filepath, content, 'utf-8');
        console.log("Fixed " + filepath);
    } else {
        console.log("Regex didn't match.");
    }
}

const file = "C:/Users/lenovo/Desktop/Shaj ERP/lib/features/sales/presentation/screens/add_edit_invoice_screen.dart";
fixFile(file);
