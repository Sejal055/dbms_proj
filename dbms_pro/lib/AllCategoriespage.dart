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
      'isDefault': true,
    },
    {
      'title': 'Transportation',
      'icon': Icons.directions_bus.codePoint,
      'color': 0xFFEAF8FB,
      'isDefault': true,
    },
    {
      'title': 'Education',
      'icon': Icons.school.codePoint,
      'color': 0xFFF6F2FA,
      'isDefault': true,
    },
    {
      'title': 'Entertainment',
      'icon': Icons.movie.codePoint,
      'color': 0xFFF6F2FA,
      'isDefault': true,
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
    final userCategories = snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['docId'] = doc.id;
          data['isDefault'] = false;
          return data;
        })
        .toList()
        .cast<Map<String, dynamic>>();

    // Merge default and user categories, avoiding title duplicates (case-insensitive)
    final titles = userCategories
        .map((e) => e['title'].toString().toLowerCase())
        .toSet();
    final merged = [
      ...defaultCategories.where((defaultCat) =>
          !titles.contains(defaultCat['title'].toString().toLowerCase())),
      ...userCategories
    ];

    setState(() {
      categoriesList = merged;
    });
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    if (cat['isDefault'] == true) return; // Default categories can't be deleted

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('categories')
        .doc(cat['docId'])
        .delete();
    await fetchCategories();
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.90),
        insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decorative Header 
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD6EAF8), Color(0xFFFDEBEE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category, color: Colors.deepPurple, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Add Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 21,
                        color: Colors.deepPurple[400],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22),
              // The Input
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF3F7FB),
                  hintText: "Category Name",
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.deepPurple[100]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 1.4),
                  ),
                ),
                style: TextStyle(fontSize: 17),
              ),
              SizedBox(height: 28),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontSize: 17)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      minimumSize: Size(80, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      elevation: 3
                    ),
                    child: Text('Add', style: TextStyle(fontSize: 17)),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Category'),
        content: Text('Are you sure you want to delete "${cat['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.deepPurple)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteCategory(cat);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('All Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.purple),
              tooltip: "Add Category",
              onPressed: _showAddCategoryDialog,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFDEE6FB),
              Color(0xFFD6EAF8),
              Color(0xFFFDEBEE),
              Color(0xFFF7E7FF),
            ],
            stops: [0, 0.5, 0.8, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40),
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: categoriesList.length,
            itemBuilder: (context, index) {
              final cat = categoriesList[index];

              return AnimatedContainer(
                duration: Duration(milliseconds: 400 + (index * 60)),
                curve: Curves.easeOutBack,
                margin: EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 8,
                  color: Colors.white.withOpacity(0.7),
                  shadowColor: Color(cat['color']).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(cat['color']).withOpacity(0.8),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        IconData(cat['icon'], fontFamily: 'MaterialIcons'),
                        color: Colors.deepPurple,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      cat['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    trailing: cat['isDefault'] == true
                        ? null
                        : IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent, size: 26),
                            tooltip: "Delete Category",
                            onPressed: () => _showDeleteConfirmationDialog(cat),
                          ),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
