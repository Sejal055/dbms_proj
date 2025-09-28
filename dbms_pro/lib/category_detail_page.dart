import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'package:intl/intl.dart';

class CategoryDetailPage extends StatelessWidget {
  final String category;
  final List<Expense> expenses;

  const CategoryDetailPage({
    required this.category,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('$category Expenses'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: expenses.isEmpty
          ? Center(child: Text('No expenses for $category.'))
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.attach_money),
                    title: Text(expense.name),
                    subtitle: Text(formatter.format(expense.date)),
                    trailing: Text('Rs.${expense.amount.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
    );
  }
}
