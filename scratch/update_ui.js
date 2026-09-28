const fs = require('fs');

function updateOrderScreen() {
  let file = 'lib/features/orders/presentation/screens/add_edit_order_screen.dart';
  let c = fs.readFileSync(file, 'utf8');
  
  c = c.replace(/title: Text\(\s*widget\.orderUuid != null\s*\? 'Edit Sales Order \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}'\s*: 'Record Sales Order \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}',\s*\),/,
    "title: Text(\n            widget.orderUuid != null\n                ? 'Edit Sales Order ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}'\n                : 'Record Sales Order ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}',\n            style: const TextStyle(fontSize: 18),\n          ),");

  let salesmanOld = "Expanded(child: DropdownButtonFormField<String>(\n" +
"                                  isExpanded: true,\n" +
"                                  value: _salesmenList.contains(_selectedSalesman) ? _selectedSalesman : _salesmenList.first,\n" +
"                                  decoration: InputDecoration(\n" +
"                                    labelText: 'Salesman Name',\n" +
"                                    \n" +
"                                    isDense: true,\n" +
"                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),\n" +
"                                    prefixIcon: Icon(Icons.badge_outlined),\n" +
"                                  ),\n" +
"                                  items: _salesmenList.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),\n" +
"                                  onChanged: (val) {\n" +
"                                    if (val != null) setState(() => _selectedSalesman = val);\n" +
"                                  },\n" +
"                                ),\n" +
"                              ),\n" +
"                              const SizedBox(width: 8),\n" +
"                              IconButton.filledTonal(\n" +
"                                icon: const Icon(Icons.person_add_alt_1),\n" +
"                                tooltip: 'Add Salesman',\n" +
"                                onPressed: _showAddSalesmanDialog,\n" +
"                              ),";
  let salesmanNew = "Expanded(child: DropdownButtonFormField<String>(\n" +
"                                  isExpanded: true,\n" +
"                                  value: _salesmenList.contains(_selectedSalesman) ? _selectedSalesman : null,\n" +
"                                  hint: const Text('Select Salesman'),\n" +
"                                  icon: const SizedBox.shrink(),\n" +
"                                  decoration: InputDecoration(\n" +
"                                    labelText: 'Salesman Name',\n" +
"                                    isDense: true,\n" +
"                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),\n" +
"                                    prefixIcon: Icon(Icons.badge_outlined),\n" +
"                                    suffixIcon: Row(\n" +
"                                      mainAxisSize: MainAxisSize.min,\n" +
"                                      children: [\n" +
"                                        if (_selectedSalesman.isNotEmpty && _selectedSalesman != 'Default Salesman')\n" +
"                                          IconButton(\n" +
"                                            icon: const Icon(Icons.close, size: 16),\n" +
"                                            onPressed: () => setState(() => _selectedSalesman = ''),\n" +
"                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),\n" +
"                                            padding: EdgeInsets.zero,\n" +
"                                          ),\n" +
"                                        IconButton(\n" +
"                                          icon: const Icon(Icons.person_add, size: 18),\n" +
"                                          onPressed: _showAddSalesmanDialog,\n" +
"                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),\n" +
"                                          padding: EdgeInsets.zero,\n" +
"                                        ),\n" +
"                                        const Icon(Icons.arrow_drop_down, color: Colors.grey),\n" +
"                                        const SizedBox(width: 8),\n" +
"                                      ],\n" +
"                                    ),\n" +
"                                  ),\n" +
"                                  items: _salesmenList.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),\n" +
"                                  onChanged: (val) {\n" +
"                                    if (val != null) setState(() => _selectedSalesman = val);\n" +
"                                  },\n" +
"                                ),\n" +
"                              ),";
  
  c = c.replace(salesmanOld, salesmanNew);
  fs.writeFileSync(file, c);
}

function updateInvoiceScreen() {
  let file = 'lib/features/sales/presentation/screens/add_edit_invoice_screen.dart';
  let c = fs.readFileSync(file, 'utf8');
  
  c = c.replace(/title: Text\(\s*widget\.invoiceUuid != null\s*\? 'Edit Sales Invoice \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}'\s*: 'Direct Tax Invoice \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}',\s*\),/,
    "title: Text(\n            widget.invoiceUuid != null\n                ? 'Edit Sales Invoice ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}'\n                : 'Direct Tax Invoice ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}',\n            style: const TextStyle(fontSize: 18),\n          ),");

  let oldSalesmanRaw = "RawAutocomplete<String>(\n" +
"                                  textEditingController: TextEditingController(text: _selectedSalesman),\n" +
"                                  focusNode: FocusNode(),\n" +
"                                  optionsBuilder: (TextEditingValue textEditingValue) {\n" +
"                                    final query = textEditingValue.text.trim().toLowerCase();\n" +
"                                    if (query.isEmpty) return _salesmenList;\n" +
"                                    return _salesmenList.where((s) => s.toLowerCase().contains(query)).toList();\n" +
"                                  },\n" +
"                                  onSelected: (String s) {\n" +
"                                    setState(() { _selectedSalesman = s; });\n" +
"                                    FocusScope.of(context).unfocus();\n" +
"                                  },\n" +
"                                  optionsViewBuilder: (context, onSelected, options) {\n" +
"                                    return Align(\n" +
"                                      alignment: Alignment.topLeft,\n" +
"                                      child: Material(\n" +
"                                        elevation: 4,\n" +
"                                        borderRadius: BorderRadius.circular(8),\n" +
"                                        child: Container(\n" +
"                                          width: 250,\n" +
"                                          constraints: const BoxConstraints(maxHeight: 250),\n" +
"                                          child: ListView.builder(\n" +
"                                            padding: EdgeInsets.zero,\n" +
"                                            shrinkWrap: true,\n" +
"                                            itemCount: options.length,\n" +
"                                            itemBuilder: (context, index) {\n" +
"                                              final option = options.elementAt(index);\n" +
"                                              return ListTile(\n" +
"                                                dense: true,\n" +
"                                                title: Text(option, style: const TextStyle(fontSize: 13)),\n" +
"                                                onTap: () => onSelected(option),\n" +
"                                              );\n" +
"                                            },\n" +
"                                          ),\n" +
"                                        ),\n" +
"                                      ),\n" +
"                                    );\n" +
"                                  },\n" +
"                                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {\n" +
"                                    return TextFormField(\n" +
"                                      controller: controller,\n" +
"                                      focusNode: focusNode,\n" +
"                                      style: const TextStyle(fontSize: 13),\n" +
"                                      decoration: InputDecoration(\n" +
"                                        labelText: 'Salesman',\n" +
"                                        isDense: true,\n" +
"                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),\n" +
"                                        prefixIcon: const Icon(Icons.badge_outlined, size: 18),\n" +
"                                        suffixIcon: IconButton(\n" +
"                                          icon: const Icon(Icons.add_circle, color: Colors.blue, size: 20),\n" +
"                                          padding: EdgeInsets.zero,\n" +
"                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),\n" +
"                                          onPressed: _showAddSalesmanDialog,\n" +
"                                        ),\n" +
"                                      ),\n" +
"                                    );\n" +
"                                  },\n" +
"                                )";
                                
  let newSalesman = "DropdownButtonFormField<String>(\n" +
"                                  isExpanded: true,\n" +
"                                  value: _salesmenList.contains(_selectedSalesman) ? _selectedSalesman : null,\n" +
"                                  hint: const Text('Select Salesman', style: TextStyle(fontSize: 13)),\n" +
"                                  icon: const SizedBox.shrink(),\n" +
"                                  decoration: InputDecoration(\n" +
"                                    labelText: 'Salesman Name',\n" +
"                                    isDense: true,\n" +
"                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),\n" +
"                                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),\n" +
"                                    suffixIcon: Row(\n" +
"                                      mainAxisSize: MainAxisSize.min,\n" +
"                                      children: [\n" +
"                                        if (_selectedSalesman.isNotEmpty && _selectedSalesman != 'Default Salesman')\n" +
"                                          IconButton(\n" +
"                                            icon: const Icon(Icons.close, size: 16),\n" +
"                                            onPressed: () => setState(() => _selectedSalesman = ''),\n" +
"                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),\n" +
"                                            padding: EdgeInsets.zero,\n" +
"                                          ),\n" +
"                                        IconButton(\n" +
"                                          icon: const Icon(Icons.person_add, size: 18),\n" +
"                                          onPressed: _showAddSalesmanDialog,\n" +
"                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),\n" +
"                                          padding: EdgeInsets.zero,\n" +
"                                        ),\n" +
"                                        const Icon(Icons.arrow_drop_down, color: Colors.grey),\n" +
"                                        const SizedBox(width: 8),\n" +
"                                      ],\n" +
"                                    ),\n" +
"                                  ),\n" +
"                                  items: _salesmenList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),\n" +
"                                  onChanged: (val) {\n" +
"                                    if (val != null) setState(() => _selectedSalesman = val);\n" +
"                                  },\n" +
"                                )";

  if (c.includes(oldSalesmanRaw)) {
    c = c.replace(oldSalesmanRaw, newSalesman);
  }
  fs.writeFileSync(file, c);
}

function updateAppBarOnly(file, titleRegex, replacement) {
  let c = fs.readFileSync(file, 'utf8');
  c = c.replace(titleRegex, replacement);
  fs.writeFileSync(file, c);
}

updateOrderScreen();
updateInvoiceScreen();
updateAppBarOnly('lib/features/purchases/presentation/screens/add_edit_purchase_screen.dart', 
  /title: Text\(\s*widget\.purchaseUuid != null\s*\? 'Edit Purchase \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}'\s*: 'Record Purchase \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}',\s*\),/,
  "title: Text(\n            widget.purchaseUuid != null\n                ? 'Edit Purchase ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}'\n                : 'Record Purchase ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}',\n            style: const TextStyle(fontSize: 18),\n          ),");
updateAppBarOnly('lib/features/transactions/presentation/screens/add_edit_credit_note_screen.dart', 
  /title: Text\(\s*widget\.creditNoteUuid != null\s*\? 'Edit CreditNote \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}'\s*: 'Record CreditNote \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}',\s*\),/,
  "title: Text(\n            widget.creditNoteUuid != null\n                ? 'Edit CreditNote ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}'\n                : 'Record CreditNote ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}',\n            style: const TextStyle(fontSize: 18),\n          ),");
updateAppBarOnly('lib/features/transactions/presentation/screens/add_edit_debit_note_screen.dart', 
  /title: Text\(\s*widget\.debitNoteUuid != null\s*\? 'Edit DebitNote \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}'\s*: 'Record DebitNote \${_voucherNumberDisplay\.isNotEmpty \? "\(#\$_voucherNumberDisplay\)" : ""}',\s*\),/,
  "title: Text(\n            widget.debitNoteUuid != null\n                ? 'Edit DebitNote ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}'\n                : 'Record DebitNote ${_voucherNumberDisplay.isNotEmpty ? \"(#${_voucherNumberDisplay})\" : \"\"}',\n            style: const TextStyle(fontSize: 18),\n          ),");

