import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'category_detail_page.dart';

class CategoriesPage extends StatefulWidget {
  final List<Expense> expenses;

  const CategoriesPage({required this.expenses});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Set<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = widget.expenses.map((e) => e.category).toSet();
  }

  void _showAddCategoryDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Category'),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Add'),
            onPressed: () {
              final newCategory = _controller.text.trim();
              if (newCategory.isNotEmpty && !_categories.contains(newCategory)) {
                setState(() {
                  _categories.add(newCategory);
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Categories'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _categories.isEmpty
          ? Center(child: Text('No categories yet. Add some expenses!'))
          : ListView(
              children: _categories.map((category) {
                final categoryExpenses = widget.expenses
                    .where((e) => e.category == category)
                    .toList();
                final total = categoryExpenses.fold(
                    0.0, (sum, e) => sum + e.amount);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.label, color: Colors.blueAccent),
                    title: Text(category),
                    subtitle: Text('Total: Rs.${total.toStringAsFixed(2)}'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryDetailPage(
                            category: category,
                            expenses: categoryExpenses,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.lightBlueAccent,
        child: Icon(Icons.add),
        tooltip: 'Add New Category',
      ),
    );
  }
}
