import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/data/local/collections/item_collection.dart';

class SubItemPickerModal extends StatelessWidget {
  final Item item;

  const SubItemPickerModal({Key? key, required this.item}) : super(key: key);

  static Future<SubItem?> show(BuildContext context, Item item) {
    if (item.subItems == null || item.subItems!.isEmpty) {
      return Future.value(null);
    }
    
    return showDialog<SubItem>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 400,
          child: SubItemPickerModal(item: item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subItems = item.subItems ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: Text('Select Variant for ${item.itemName}'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: subItems.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final sub = subItems[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.style, color: theme.colorScheme.onPrimaryContainer),
                ),
                title: Text(
                  sub.name ?? 'Unnamed Variant',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Price: ₹${(sub.sellPrice ?? item.sellRate ?? 0).toStringAsFixed(2)}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Select'),
                  onPressed: () => Navigator.pop(context, sub),
                ),
                onTap: () => Navigator.pop(context, sub),
              );
            },
          ),
        ),
      ],
    );
  }
}
