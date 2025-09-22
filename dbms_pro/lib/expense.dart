import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseForm extends StatefulWidget {
  @override
  _ExpenseFormState createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _monthBudgetController = TextEditingController();

  // Function to add expense to Firestore
  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('expenses').add({
          'name': _nameController.text.trim(),
          'amount': double.parse(_amountController.text.trim()),
          'month_budget': double.parse(_monthBudgetController.text.trim()),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense added successfully!")),
        );

        // Clear form after submit
        _nameController.clear();
        _amountController.clear();
        _monthBudgetController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Expense Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Expense Name"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter expense name" : null,
              ),

              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter amount" : null,
              ),

              const SizedBox(height: 16),

              // Month Budget
              TextFormField(
                controller: _monthBudgetController,
                decoration: const InputDecoration(labelText: "Month Budget"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter month budget" : null,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _addExpense,
                child: const Text("Add Expense"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
