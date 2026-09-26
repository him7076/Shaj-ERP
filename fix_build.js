const fs = require('fs');
const path = require('path');

// 1. Fix responsive_form_row.dart
const responsiveRowPath = path.join(__dirname, 'lib/core/widgets/responsive_form_row.dart');
let content = fs.readFileSync(responsiveRowPath, 'utf8');

const targetClass = `class ResponsiveFormRow extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveFormRow({
    Key? key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  }) : super(key: key);`;

const replacementClass = `class ResponsiveFormRow extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  const ResponsiveFormRow({
    Key? key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  }) : super(key: key);`;

content = content.replace(targetClass, replacementClass);

// Also update the Row in ResponsiveFormRow to pass mainAxisSize
const targetRow = `        } else {
          // PC/Tablet View: Row
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            children: children,
          );
        }`;
const replacementRow = `        } else {
          // PC/Tablet View: Row
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: children,
          );
        }`;

content = content.replace(targetRow, replacementRow);

// Also Column in Mobile view: Column doesn't support mainAxisSize directly in the same way, but let's pass it to Column too just in case.
const targetColumn = `          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnChildren,
          );`;
const replacementColumn = `          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: mainAxisSize,
            children: columnChildren,
          );`;
content = content.replace(targetColumn, replacementColumn);

fs.writeFileSync(responsiveRowPath, content, 'utf8');
console.log('Fixed responsive_form_row.dart');


// 2. Fix add_edit_item_screen.dart
const itemScreenPath = path.join(__dirname, 'lib/features/items/presentation/screens/add_edit_item_screen.dart');
let itemContent = fs.readFileSync(itemScreenPath, 'utf8');
itemContent = itemContent.replace(/_buildResponsiveResponsiveFormRow/g, '_buildResponsiveRow');
fs.writeFileSync(itemScreenPath, itemContent, 'utf8');
console.log('Fixed add_edit_item_screen.dart');
