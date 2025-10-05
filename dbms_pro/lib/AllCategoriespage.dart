import 'package:flutter/material.dart';
import 'expense.dart';
import 'category_data.dart';
//import 'home_page.dart';
//import 'categories.dart'; // Adjust path if needed


class AllCategoriesPage extends StatefulWidget {
  @override
  _AllCategoriesPageState createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  List categoriesList = List.from(categories);

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Category'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: "Category Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  categoriesList.add({
                    'title': nameController.text.trim(),
                    'icon': Icons.category,
                    'color': Colors.grey.shade200,
                  });
                });
                Navigator.of(context).pop();
              }
            },
            child: Text('Add'),
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
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: ListView(
        children: categoriesList
            .map((cat) => ListTile(
                  leading: Icon(cat['icon'], color: Colors.black87),
                  title: Text(cat['title']),
                  tileColor: cat['color'],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ExpensesPage(category: cat['title']),
                    ));
                  },
                )).toList(),
      ),
    );
  }
}
