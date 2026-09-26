import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';
import 'package:business_sahaj_erp/presentation/providers/core_providers.dart';
import 'package:business_sahaj_erp/features/items/presentation/providers/item_providers.dart';

class VariantDropdownWidget extends ConsumerStatefulWidget {
  final Item item;
  final String? selectedSubItemUuid;
  final ValueChanged<SubItem?> onChanged;

  const VariantDropdownWidget({
    Key? key,
    required this.item,
    this.selectedSubItemUuid,
    required this.onChanged,
  }) : super(key: key);

  @override
  ConsumerState<VariantDropdownWidget> createState() => _VariantDropdownWidgetState();
}

class _VariantDropdownWidgetState extends ConsumerState<VariantDropdownWidget> {
  void _openSelectionDialog() async {
    final result = await showDialog<SubItem>(
      context: context,
      builder: (context) => _VariantSelectionDialog(item: widget.item),
    );

    if (result != null) {
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.hasSubItems) {
      return const SizedBox.shrink(); // Hide if no variants are enabled
    }

    final theme = Theme.of(context);
    SubItem? selected;
    if (widget.item.subItems != null && widget.selectedSubItemUuid != null) {
      try {
        selected = widget.item.subItems!.firstWhere((s) => s.uuid == widget.selectedSubItemUuid);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: InkWell(
        onTap: _openSelectionDialog,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          child: Row(
            children: [
              Icon(Icons.style_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected?.name ?? 'Select Variant...',
                  style: TextStyle(
                    fontSize: 13,
                    color: selected == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                    fontWeight: selected == null ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, size: 20, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantSelectionDialog extends ConsumerStatefulWidget {
  final Item item;
  const _VariantSelectionDialog({Key? key, required this.item}) : super(key: key);

  @override
  ConsumerState<_VariantSelectionDialog> createState() => _VariantSelectionDialogState();
}

class _VariantSelectionDialogState extends ConsumerState<_VariantSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Item _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createNewVariant(String name) async {
    final theme = Theme.of(context);
    final rateController = TextEditingController(text: (_currentItem.sellRate ?? 0.0).toString());
    
    final created = await showDialog<SubItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Variant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Variant Name', ),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (₹)', ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newSubItem = SubItem()
                ..uuid = const Uuid().v4()
                ..name = name
                ..sellPrice = double.tryParse(rateController.text) ?? 0.0
                ..buyPrice = double.tryParse(rateController.text) ?? 0.0;
              Navigator.pop(ctx, newSubItem);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != null && mounted) {
      // Save to database
      final updatedList = List<SubItem>.from(_currentItem.subItems ?? [])..add(created);
      _currentItem.subItems = updatedList;
      
      final repo = ref.read(itemRepositoryProvider);
      await repo.update(_currentItem);
      
      if (mounted) {
        Navigator.pop(context, created);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subItems = _currentItem.subItems ?? [];
    
    final filteredList = subItems.where((sub) {
      if (_searchQuery.isEmpty) return true;
      return (sub.name ?? '').toLowerCase().contains(_searchQuery);
    }).toList();

    final exactMatch = subItems.any((sub) => (sub.name ?? '').toLowerCase() == _searchQuery);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 450,
        height: 500,
        child: Column(
          children: [
            AppBar(
              title: Text('Variants for ${_currentItem.itemName}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search variants...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            if (_searchQuery.isNotEmpty && !exactMatch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Material(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: theme.colorScheme.primary, child: const Icon(Icons.add, color: Colors.white, size: 20)),
                    title: Text('Create Variant: "${_searchController.text.trim()}"', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    onTap: () => _createNewVariant(_searchController.text.trim()),
                  ),
                ),
              ),
            Expanded(
              child: filteredList.isEmpty 
                  ? Center(child: Text('No variants found.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sub = filteredList[index];
                        return ListTile(
                          title: Text(sub.name ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Price: ₹${(sub.sellPrice ?? _currentItem.sellRate ?? 0).toStringAsFixed(2)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, sub),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
