import 'package:flutter/material.dart';

class ResponsiveFormRow extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveFormRow({
    Key? key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          // Mobile View: Column
          final List<Widget> columnChildren = [];
          
          for (int i = 0; i < children.length; i++) {
            final child = children[i];
            
            // Skip pure horizontal spacing in Column view
            if (child is SizedBox && child.width != null && child.height == null && child.child == null) {
              continue; 
            }

            // Extract child from Expanded/Flexible since they cause errors in Column (if not bounded)
            // or they stretch vertically which we don't want here
            Widget actualChild = child;
            if (child is Expanded) {
              actualChild = child.child;
            } else if (child is Flexible) {
              actualChild = child.child;
            }

            columnChildren.add(actualChild);
            
            // Add vertical spacing between elements
            if (i < children.length - 1) {
              // Only add spacing if the next element isn't just a spacer we're skipping
              final nextChild = children[i + 1];
              if (!(nextChild is SizedBox && nextChild.width != null && nextChild.height == null && nextChild.child == null)) {
                  columnChildren.add(const SizedBox(height: 16));
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnChildren,
          );
        } else {
          // PC/Tablet View: Row
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisAlignment: mainAxisAlignment,
            children: children,
          );
        }
      },
    );
  }
}
