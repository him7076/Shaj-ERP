import re

def fix_ui(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to find the showModalBottomSheet or Dialog where items are added.
    # The dialog contains fields like 'Qty', 'Unit', 'Rate'.
    # We will replace ResponsiveFormRow with Row, but ONLY inside the dialog builder or carefully targeted.
    
    # Actually, we can just replace all ResponsiveFormRow that contain Expanded(child: TextFormField(... 'Qty' ...))
    # But it's easier to just replace all ResponsiveFormRow with Row inside the specific blocks.
    # Let's replace ResponsiveFormRow with Row where they wrap Qty, Unit, Rate, Discount etc.
    
    # We can just replace ResponsiveFormRow with Row globally in these two files, 
    # EXCEPT for the ones that should actually be responsive (like the main form fields: Date, Party Name, etc).
    # Wait, the main form fields are NOT inside ResponsiveFormRow? 
    # Let's check where ResponsiveFormRow is used.
    
    # Since the user specifically complained about item section, let's target the fields inside the item dialog.
    
    # Find the _showAddItemDialog function or similar.
    # Let's just use regex to replace ResponsiveFormRow -> Row if it's near 'Qty', 'Unit', 'Rate', 'Free Qty'.
    
    # A safer approach: I'll just change the ones inside the Item Dialog.
    # We can match `ResponsiveFormRow(` and replace with `Row(`.
    
    parts = content.split('void _showAddItemDialog')
    if len(parts) == 2:
        top_part = parts[0]
        bottom_part = parts[1]
        
        # Replace ResponsiveFormRow with Row in the bottom part (which contains the dialog)
        bottom_part = bottom_part.replace('ResponsiveFormRow(', 'Row(')
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(top_part + 'void _showAddItemDialog' + bottom_part)
        print(f"Fixed {filepath}")
    else:
        print(f"Could not find _showAddItemDialog in {filepath}")

fix_ui(r"lib\features\sales\presentation\screens\add_edit_invoice_screen.dart")
fix_ui(r"lib\features\purchases\presentation\screens\add_edit_purchase_screen.dart")

