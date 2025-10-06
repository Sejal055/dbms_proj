import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'expense.dart'; // Update this import if needed for ExpensesPage

class AllCategoriesPage extends StatefulWidget {
  @override
  _AllCategoriesPageState createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  List<Map<String, dynamic>> categoriesList = [];

  // These are always displayed, unless a user creates one with the same title (case-insensitive)
  final List<Map<String, dynamic>> defaultCategories = [
    {
      'title': 'Food & Dining',
      'icon': Icons.restaurant.codePoint,
      'color': 0xFFFFF7E3,
    },
    {
      'title': 'Transportation',
      'icon': Icons.directions_bus.codePoint,
      'color': 0xFFEAF8FB,
    },
    {
      'title': 'Education',
      'icon': Icons.school.codePoint,
      'color': 0xFFF6F2FA,
    },
    {
      'title': 'Entertainment',
      'icon': Icons.movie.codePoint,
      'color': 0xFFFDEBEE,
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('categories')
        .get();
    final userCategories = snapshot.docs.map((doc) => doc.data()).toList().cast<Map<String, dynamic>>();

    // Merge default and user categories, avoiding title duplicates (case-insensitive)
    final titles = userCategories.map((e) => e['title'].toString().toLowerCase()).toSet();
    final merged = [
      ...defaultCategories.where((defaultCat) =>
        !titles.contains(defaultCat['title'].toString().toLowerCase())),
      ...userCategories
    ];

    setState(() {
      categoriesList = merged;
    });
  }

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
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                var newCategory = {
                  'title': nameController.text.trim(),
                  'icon': Icons.category.codePoint,
                  'color': Colors.grey.shade200.value,
                };
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('categories')
                    .add(newCategory);
                await fetchCategories();
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: categoriesList.length,
          itemBuilder: (context, index) {
            final cat = categoriesList[index];
            return Card(
              color: Color(cat['color']),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(
                  IconData(cat['icon'], fontFamily: 'MaterialIcons'),
                  color: Colors.black87,
                ),
                title: Text(cat['title']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ExpensesPage(category: cat['title']),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
