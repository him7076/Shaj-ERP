import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/features/bank/presentation/screens/add_edit_bank_account_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchablePaymentModeDropdown extends ConsumerStatefulWidget {
  final List<String> paymentModes;
  final String? selectedMode;
  final ValueChanged<String?> onChanged;
  final String labelText;

  const SearchablePaymentModeDropdown({
    Key? key,
    required this.paymentModes,
    required this.selectedMode,
    required this.onChanged,
    this.labelText = 'Select Payment Mode',
  }) : super(key: key);

  @override
  ConsumerState<SearchablePaymentModeDropdown> createState() => _SearchablePaymentModeDropdownState();
}

class _SearchablePaymentModeDropdownState extends ConsumerState<SearchablePaymentModeDropdown> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedMode ?? '');
  }

  @override
  void didUpdateWidget(covariant SearchablePaymentModeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMode != oldWidget.selectedMode) {
      _controller.text = widget.selectedMode ?? '';
    }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (mode) => mode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) {
              return widget.paymentModes;
            } else {
              return widget.paymentModes.where((p) => p.toLowerCase().contains(query)).toList();
            }
          },
          onSelected: (mode) {
            widget.onChanged(mode);
            FocusScope.of(context).unfocus();
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 12,
                shadowColor: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Modes',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                FocusScope.of(context).unfocus();
                                await showDialog(context: context, builder: (context) => const AddEditBankAccountDialog());
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add New',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.2))),
                                ),
                                child: Text(
                                  option,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.labelText,
                isDense: true,
                suffixIcon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
              ),
            );
          },
        );
      },
    );
  }
}
