import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/features/items/presentation/screens/add_edit_item_screen.dart';

class SearchableItemDropdown extends StatefulWidget {
  final List<Item> items;
  final ValueChanged<Item> onSelected;
  final String labelText;

  const SearchableItemDropdown({
    Key? key,
    required this.items,
    required this.onSelected,
    this.labelText = 'Search and add component...',
  }) : super(key: key);

  @override
  State<SearchableItemDropdown> createState() => _SearchableItemDropdownState();
}

class _SearchableItemDropdownState extends State<SearchableItemDropdown> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RawAutocomplete<Item>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (item) => item.uuid == 'NEW_ACTION' ? '' : (item.itemName ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        List<Item> filtered = [];
        if (query.isEmpty) {
          filtered = widget.items.take(20).toList();
        } else {
          filtered = widget.items.where((i) {
            final name = i.itemName?.toLowerCase() ?? '';
            final code = i.itemCode?.toLowerCase() ?? '';
            final barcode = i.barcode?.toLowerCase() ?? '';
            return name.contains(query) || code.contains(query) || barcode.contains(query);
          }).take(30).toList();
        }

        final createActionItem = Item()
          ..uuid = 'NEW_ACTION'
          ..itemName = query.isNotEmpty
              ? '+ Create New Product "$query"'
              : '+ Create New Product';

        return [...filtered, createActionItem];
      },
      onSelected: (item) {
        if (item.uuid == 'NEW_ACTION') {
          final query = _controller.text.trim();
          FocusScope.of(context).unfocus();
          _controller.clear();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditItemScreen(
              prefilledItem: query.isNotEmpty ? (Item()..itemName = query) : null,
            )),
          );
          return;
        }
        widget.onSelected(item);
        _controller.clear();
        FocusScope.of(context).unfocus();
      },
      optionsViewBuilder: (context, onSelected, options) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dropdownWidth = (screenWidth - 32).clamp(260.0, 480.0);

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 12,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
            child: Container(
              width: dropdownWidth,
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);
                  if (item.uuid == 'NEW_ACTION') {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.12),
                        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 18),
                        title: Text(
                          item.itemName ?? '+ Create New Product',
                          style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 12.5),
                        ),
                        onTap: () => onSelected(item),
                      ),
                    );
                  }

                  final rate = item.sellRate ?? 0.0;
                  final stock = item.currentStock ?? 0.0;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    title: Text(item.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text(
                      'Code: ${item.itemCode ?? "N/A"} | Price: ₹${rate.toStringAsFixed(2)} | Stock: $stock',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          onChanged: (_) => setState(() {}),
        );
      },
    );
  }
}
