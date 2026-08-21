import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';
import 'package:business_sahaj_erp/features/parties/presentation/screens/add_edit_party_screen.dart';

class SearchablePartyDropdown extends StatefulWidget {
  final List<Party> parties;
  final Party? selectedParty;
  final ValueChanged<Party?> onChanged;
  final String labelText;

  const SearchablePartyDropdown({
    Key? key,
    required this.parties,
    required this.selectedParty,
    required this.onChanged,
    this.labelText = 'Select Party',
  }) : super(key: key);

  @override
  State<SearchablePartyDropdown> createState() => _SearchablePartyDropdownState();
}

class _SearchablePartyDropdownState extends State<SearchablePartyDropdown> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedParty?.partyName ?? '');
  }

  @override
  void didUpdateWidget(covariant SearchablePartyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedParty != oldWidget.selectedParty) {
      _controller.text = widget.selectedParty?.partyName ?? '';
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
    return RawAutocomplete<Party>(
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (party) => party.uuid == 'NEW_ACTION' ? '' : (party.partyName ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        List<Party> filtered = [];
        if (query.isEmpty) {
          filtered = widget.parties;
        } else {
          filtered = widget.parties.where((p) {
            final name = p.partyName?.toLowerCase() ?? '';
            final phone = p.mobileNumber?.toLowerCase() ?? '';
            return name.contains(query) || phone.contains(query);
          }).toList();
        }

        final createActionParty = Party()
          ..uuid = 'NEW_ACTION'
          ..partyName = query.isNotEmpty
              ? '+ Create New Party "$query"'
              : '+ Create New Party Account';

        return [...filtered, createActionParty];
      },
      onSelected: (party) {
        if (party.uuid == 'NEW_ACTION') {
          final query = _controller.text.trim();
          FocusScope.of(context).unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditPartyScreen(initialName: query.isNotEmpty ? query : null)),
          );
          return;
        }
        widget.onChanged(party);
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
              constraints: const BoxConstraints(maxHeight: 240),
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
                  final party = options.elementAt(index);
                  if (party.uuid == 'NEW_ACTION') {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.12),
                        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.person_add_alt_1_rounded, color: theme.colorScheme.primary, size: 18),
                        title: Text(
                          party.partyName ?? '+ Create New Party Account',
                          style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 12.5),
                        ),
                        onTap: () => onSelected(party),
                      ),
                    );
                  }

                  final double bal = party.outstandingBalance ?? 0.0;
                  final Color balColor = bal > 0 ? Colors.green : (bal < 0 ? Colors.red : Colors.grey);
                  final String balText = bal > 0 
                      ? 'Receivable: ₹${bal.toStringAsFixed(2)}' 
                      : (bal < 0 ? 'Payable: ₹${bal.abs().toStringAsFixed(2)}' : 'Balance: ₹0.00');

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    title: Text(party.partyName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text(
                      balText,
                      style: TextStyle(color: balColor, fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                    onTap: () => onSelected(party),
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
            prefixIcon: const Icon(Icons.person_outline),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      widget.onChanged(null);
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }
}
