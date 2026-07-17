import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';

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
      displayStringForOption: (party) => party.partyName ?? '',
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return widget.parties;
        }
        final query = textEditingValue.text.toLowerCase();
        return widget.parties.where((p) {
          final name = p.partyName?.toLowerCase() ?? '';
          final phone = p.mobileNumber?.toLowerCase() ?? '';
          return name.contains(query) || phone.contains(query);
        });
      },
      onSelected: (party) {
        widget.onChanged(party);
        FocusScope.of(context).unfocus();
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, maxWidth: 450),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final party = options.elementAt(index);
                  final double bal = party.outstandingBalance ?? 0.0;
                  final Color balColor = bal > 0 ? Colors.green : (bal < 0 ? Colors.red : Colors.grey);
                  final String balText = bal > 0 
                      ? 'Receivable: ₹${bal.toStringAsFixed(2)}' 
                      : (bal < 0 ? 'Payable: ₹${bal.abs().toStringAsFixed(2)}' : 'Balance: ₹0.00');

                  return ListTile(
                    title: Text(party.partyName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      balText,
                      style: TextStyle(color: balColor, fontWeight: FontWeight.w600, fontSize: 12),
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
