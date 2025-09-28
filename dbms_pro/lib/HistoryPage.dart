import 'package:flutter/material.dart';
import 'models/expense.dart';

class HistoryPage extends StatelessWidget {
  final List<Expense> expenses;

  const HistoryPage({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: expenses.isEmpty
          ? const Center(child: Text("No expenses yet"))
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ListTile(
                  title: Text(expense.name),
                  subtitle: Text("Amount: ₹${expense.amount}"),
                );
              },
            ),
    );
  }
}
