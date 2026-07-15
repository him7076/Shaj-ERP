import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:business_sahaj_erp/data/local/collections/expense_collection.dart';
import 'package:business_sahaj_erp/features/expenses/presentation/providers/expense_providers.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  const AddEditExpenseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedCategory = 'Office Expense';
  String _selectedPaymentMode = 'Cash';
  DateTime _expenseDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _saveExpense() async {
    if (_formKey.currentState?.validate() ?? false) {
      final amt = double.tryParse(_amountController.text) ?? 0.0;
      if (amt <= 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid expense amount.')),
        );
        return;
      }

      final expense = Expense()
        ..category = _selectedCategory
        ..amount = amt
        ..expenseDate = _expenseDate
        ..paymentMode = _selectedPaymentMode
        ..remarks = _remarksController.text.trim();

      final success = await ref
          .read(expenseNotifierProvider.notifier)
          .saveExpense(expense);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense logged successfully.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Record Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveExpense,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Category dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Expense Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                          DropdownMenuItem(value: 'Salaries', child: Text('Salaries')),
                          DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                          DropdownMenuItem(value: 'Tea & Snacks', child: Text('Tea & Snacks')),
                          DropdownMenuItem(value: 'Office Expense', child: Text('Office Expense')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Amount field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (INR)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter expense amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid decimal value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Payment Mode
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMode,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.payment_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                          DropdownMenuItem(value: 'Card', child: Text('Card')),
                          DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPaymentMode = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Expense Date
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _expenseDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) {
                            setState(() {
                              _expenseDate = d;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Expense Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_expenseDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Remarks
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Details',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveExpense,
                child: const Text('SAVE EXPENSE LOG'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
