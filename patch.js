const fs = require('fs');
let code = fs.readFileSync('lib/core/widgets/searchable_item_dropdown.dart', 'utf8');

code = code.replace(
  'final bool isFixedAsset;\r\n\r\n  const SearchableItemDropdown({\r\n    Key? key,\r\n    required this.items,\r\n    required this.onSelected,\r\n    this.labelText = \'Search and add component...\',\r\n    this.isFixedAsset = false,\r\n  })',
  'final bool isFixedAsset;\r\n  final bool autofocus;\r\n\r\n  const SearchableItemDropdown({\r\n    Key? key,\r\n    required this.items,\r\n    required this.onSelected,\r\n    this.labelText = \'Search and add component...\',\r\n    this.isFixedAsset = false,\r\n    this.autofocus = false,\r\n  })'
).replace(
  'final bool isFixedAsset;\n\n  const SearchableItemDropdown({\n    Key? key,\n    required this.items,\n    required this.onSelected,\n    this.labelText = \'Search and add component...\',\n    this.isFixedAsset = false,\n  })',
  'final bool isFixedAsset;\n  final bool autofocus;\n\n  const SearchableItemDropdown({\n    Key? key,\n    required this.items,\n    required this.onSelected,\n    this.labelText = \'Search and add component...\',\n    this.isFixedAsset = false,\n    this.autofocus = false,\n  })'
);

code = code.replace(
  'focusNode: focusNode,\r\n',
  'focusNode: focusNode,\r\n          autofocus: widget.autofocus,\r\n'
).replace(
  'focusNode: focusNode,\n',
  'focusNode: focusNode,\n          autofocus: widget.autofocus,\n'
);

const oldListView = 'child: ListView.builder(';
const newListView = child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        final query = _controller.text.trim();
                        FocusScope.of(context).unfocus();
                        _controller.clear();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => widget.isFixedAsset ? AddEditFixedAssetScreen(
                            prefilledName: query.isNotEmpty ? query : null,
                          ) : AddEditItemScreen(
                            prefilledItem: query.isNotEmpty ? (Item()..itemName = query) : null,
                          )),
                        );
                      },
                      icon: const Icon(Icons.add_circle, size: 18),
                      label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(;

code = code.replace(oldListView, newListView);

const oldNewAction = 'if (item.uuid == \'NEW_ACTION\') {';
const newNewAction = oldNewAction + '\n                    return const SizedBox.shrink(); /*';
const endNewAction = 'onSelected(item),\n                      ),\n                    );';
const endNewActionRepl = endNewAction + '*/';

code = code.replace(oldNewAction, newNewAction).replace(endNewAction, endNewActionRepl);

code = code.replace('},\r\n              ),', '},\r\n                    ),\r\n                  ),\r\n                ],\r\n              ),').replace('},\n              ),', '},\n                    ),\n                  ),\n                ],\n              ),');

fs.writeFileSync('lib/core/widgets/searchable_item_dropdown.dart', code);
console.log('Done');
