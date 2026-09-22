import 'package:flutter/material.dart';

class SearchableBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemAsString;
  final bool Function(T, String)? filterFn;
  final Widget Function(BuildContext, T, bool)? itemBuilder;
  final VoidCallback? onAddPressed;
  final T? selectedItem;
  final bool isMultiSelect;
  final List<T>? initialSelectedItems;

  const SearchableBottomSheet({
    Key? key,
    required this.title,
    required this.items,
    required this.itemAsString,
    this.filterFn,
    this.itemBuilder,
    this.onAddPressed,
    this.selectedItem,
    this.isMultiSelect = false,
    this.initialSelectedItems,
  }) : super(key: key);

  static Future<T?> showSingle<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) itemAsString,
    VoidCallback? onAddPressed,
    T? selectedItem,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SearchableBottomSheet<T>(
          title: title,
          items: items,
          itemAsString: itemAsString,
          onAddPressed: onAddPressed,
          selectedItem: selectedItem,
        ),
      ),
    );
  }

  static Future<List<T>?> showMulti<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) itemAsString,
    VoidCallback? onAddPressed,
    List<T>? initialSelectedItems,
  }) {
    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SearchableBottomSheet<T>(
          title: title,
          items: items,
          itemAsString: itemAsString,
          onAddPressed: onAddPressed,
          isMultiSelect: true,
          initialSelectedItems: initialSelectedItems,
        ),
      ),
    );
  }

  @override
  State<SearchableBottomSheet<T>> createState() => _SearchableBottomSheetState<T>();
}

class _SearchableBottomSheetState<T> extends State<SearchableBottomSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];
  final Set<T> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    if (widget.isMultiSelect && widget.initialSelectedItems != null) {
      _selectedItems.addAll(widget.initialSelectedItems!);
    }
  }

  @override
  void didUpdateWidget(covariant SearchableBottomSheet<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _applyFilter(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          if (widget.filterFn != null) return widget.filterFn!(item, query);
          return widget.itemAsString(item).toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.onAddPressed != null)
                TextButton.icon(
                  onPressed: widget.onAddPressed,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              const CloseButton(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            onChanged: _applyFilter,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredItems.isEmpty
              ? const Center(child: Text('No items found.'))
              : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final isSelected = widget.isMultiSelect 
                        ? _selectedItems.contains(item) 
                        : item == widget.selectedItem;

                    if (widget.itemBuilder != null) {
                      return InkWell(
                        onTap: () => _handleItemTap(item),
                        child: widget.itemBuilder!(context, item, isSelected),
                      );
                    }

                    return ListTile(
                      title: Text(widget.itemAsString(item)),
                      trailing: widget.isMultiSelect
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                _handleItemTap(item);
                              },
                            )
                          : isSelected 
                              ? const Icon(Icons.check, color: Colors.blue) 
                              : null,
                      onTap: () => _handleItemTap(item),
                    );
                  },
                ),
        ),
        if (widget.isMultiSelect)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, _selectedItems.toList()),
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
      ],
    );
  }

  void _handleItemTap(T item) {
    if (widget.isMultiSelect) {
      setState(() {
        if (_selectedItems.contains(item)) {
          _selectedItems.remove(item);
        } else {
          _selectedItems.add(item);
        }
      });
    } else {
      Navigator.pop(context, item);
    }
  }
}
