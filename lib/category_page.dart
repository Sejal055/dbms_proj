// lib/category_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'category_detail_page.dart'; // ✅ Added import

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  IconData? selectedIcon;

  // Default categories
  final List<Map<String, dynamic>> defaultCategories = [
    {
      'name': 'Food & Dining',
      'icon': Icons.restaurant_menu,
      'color': const Color(0xFFFFF4E5)
    },
    {
      'name': 'Transportation',
      'icon': Icons.directions_bus,
      'color': const Color(0xFFE6F5FF)
    },
    {
      'name': 'Education',
      'icon': Icons.school,
      'color': const Color(0xFFF5E6FF)
    },
    {
      'name': 'Entertainment',
      'icon': Icons.movie_creation_outlined,
      'color': const Color(0xFFFFE6E6)
    },
  ];

  // Fixed set of icons for user to choose while adding
  final List<IconData> fixedIcons = [
    Icons.shopping_bag_outlined,
    Icons.fastfood_outlined,
    Icons.directions_car_outlined,
    Icons.home_outlined,
    Icons.work_outline,
    Icons.favorite_outline,
  ];

  Future<void> _addCategory(String name, IconData icon) async {
    if (user == null) return;
    final random = Random();
    final colors = [
      const Color(0xFFFFF4E5),
      const Color(0xFFE6F5FF),
      const Color(0xFFF5E6FF),
      const Color(0xFFE6FFE6),
      const Color(0xFFFFE6F0),
    ];
    final color = colors[random.nextInt(colors.length)];

    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('categories')
        .add({
      'name': name,
      'icon_code_point': icon.codePoint,
      'color': color.value,
    });
  }

  Future<void> _editCategory(String docId, String newName) async {
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('categories')
        .doc(docId)
        .update({'name': newName});
  }

  Future<void> _deleteCategory(String docId) async {
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('categories')
        .doc(docId)
        .delete();
  }

  void _showAddCategoryDialog() {
    final TextEditingController controller = TextEditingController();
    selectedIcon = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter category name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            const Text("Choose an icon (optional):",
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: fixedIcons.map((icon) {
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedIcon = icon);
                    Navigator.pop(context);
                    _showAddCategoryDialog(); // reopen dialog to reflect selected icon
                  },
                  child: CircleAvatar(
                    backgroundColor: selectedIcon == icon
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                    child: Icon(icon,
                        color: selectedIcon == icon
                            ? Colors.blueAccent
                            : Colors.black54),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _addCategory(
                    controller.text.trim(), selectedIcon ?? Icons.category);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(String docId, String currentName) {
    final TextEditingController controller =
        TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Category Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _editCategory(docId, controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color gradientEnd = Color(0xFFF8EFFB);

    return Scaffold(
      backgroundColor: gradientEnd,
      body: Column(
        children: [
          _buildTopSection(),
          Expanded(child: _buildCategoryGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7BAFFC),
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7BAFFC), Color(0xFFD6A8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Added back arrow
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Go back to previous (Home) page
              },
              child: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 22),
            ),
          ),
          const Spacer(),
          const Text(
            "Categories",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (user == null) return const Center(child: Text("No user found"));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('categories')
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> categories = List.from(defaultCategories);

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            categories.add({
              'id': doc.id,
              'name': data['name'] ?? '',
              'icon': IconData(
                data['icon_code_point'] ?? Icons.category.codePoint,
                fontFamily: 'MaterialIcons',
              ),
              'color': Color(data['color'] ?? 0xFFE0E0E0),
            });
          }
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 80,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryItem(
              category['name'],
              category['icon'],
              category['color'],
              category['id'],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryItem(
      String name, IconData icon, Color color, String? docId) {
    return GestureDetector(
      // ✅ Added navigation to CategoryDetailPage
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailPage(category: name),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(icon, size: 18, color: Colors.black87),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (docId != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: Colors.black54, size: 18),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditCategoryDialog(docId, name);
                  } else if (value == 'delete') {
                    _deleteCategory(docId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}
