import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'auth/login_page.dart'; // ✅ Make sure you have this page in your project

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String userEmail = '';
  double monthlyBudget = 0;
  double accountBalance = 0;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = data['name'] ?? '';
          userEmail = data['email'] ?? '';
          monthlyBudget = (data['monthly_budget'] ?? 0).toDouble();
          accountBalance = (data['amount_in_account'] ?? 0).toDouble();
          _nameController.text = userName;
          _emailController.text = userEmail;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });
      setState(() {
        userName = _nameController.text.trim();
        userEmail = _emailController.text.trim();
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return; // ✅ Allow picking image only in edit mode
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F0FF),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 🔹 Profile Info Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F0FF), Color(0xFFF8EFFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF86E3CE),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                            child: _profileImage == null
                                ? Text(
                                    userName.isNotEmpty ? userName[0] : '',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _emailController,
                          enabled: _isEditing,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ],
                    ),
                  ),
                  // 🔹 Single Edit Icon for all (name, email, image)
                  IconButton(
                    icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.black54),
                    onPressed: () {
                      if (_isEditing) {
                        _saveProfile();
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Account & Budget Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Account & Budget",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Account Balance: ₹ $accountBalance",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    "Monthly Budget: ₹ $monthlyBudget",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Activity Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F0FF), Color(0xFFF8EFFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Activity",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'All your expenses and actions will appear here.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Feedback Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F0FF), Color(0xFFF8EFFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Feedback",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildListItem(
                    icon: Icons.star_border,
                    title: "Rate BudgetBuddy",
                    onTap: () {},
                  ),
                  _buildListItem(
                    icon: Icons.help_outline,
                    title: "Contact BudgetBuddy support",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 🔹 Logout Button
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.logout, color: Colors.red.shade400),
                label: const Text(
                  "Log out",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // ✅ Redirect to SignIn page after logout
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LogInPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
      onTap: onTap,
    );
  }
}
