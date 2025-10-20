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
  bool _isEditingBudget = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _accountBalanceController = TextEditingController();
  final TextEditingController _monthlyBudgetController = TextEditingController();

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
          _accountBalanceController.text = accountBalance.toStringAsFixed(2);
          _monthlyBudgetController.text = monthlyBudget.toStringAsFixed(2);
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

  Future<void> _saveBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      double? newAccountBalance = double.tryParse(_accountBalanceController.text.trim());
      double? newMonthlyBudget = double.tryParse(_monthlyBudgetController.text.trim());
      if (newAccountBalance == null || newMonthlyBudget == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid numbers.")),
        );
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'amount_in_account': newAccountBalance,
        'monthly_budget': newMonthlyBudget,
      });
      setState(() {
        accountBalance = newAccountBalance;
        monthlyBudget = newMonthlyBudget;
        _isEditingBudget = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account & Budget updated successfully!")),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
  final confirmation = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Account"),
      content: const Text(
          "Are you sure you want to permanently delete your account? This action cannot be undone."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
      ],
    ),
  );

    if (confirmation == true) {
      _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Try deleting directly
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LogInPage()),
      );
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      // Need re-authentication
      final user = FirebaseAuth.instance.currentUser!;
      final email = user.email!;

      String? password = await _showPasswordDialog(); // ask user again
      if (password != null && password.isNotEmpty) {
        try {
          AuthCredential credential =
              EmailAuthProvider.credential(email: email, password: password);

          // Reauthenticate
          await user.reauthenticateWithCredential(credential);

          // Delete Firestore doc and account again
          await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
          await user.delete();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account deleted successfully.")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LogInPage()),
          );
        } catch (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Re-authentication failed: $err")),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
    }
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
  }
}

Future<String?> _showPasswordDialog() async {
  final controller = TextEditingController();
  return await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Re-enter your password"),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(hintText: "Password"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel")),
        TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Confirm")),
      ],
    ),
  );
}

/*This is for sign in with google*/

// final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
// final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
// final credential = GoogleAuthProvider.credential(
//   accessToken: googleAuth.accessToken,
//   idToken: googleAuth.idToken,
// );
// await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
// await FirebaseAuth.instance.currentUser?.delete();



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
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      centerTitle: true,
      title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      elevation: 1,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient Profile Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                children: [
                  // CircleAvatar(
                  //   radius: 40,
                  //   backgroundImage: _profileImage != null
                  //       ? FileImage(_profileImage!)
                  //       : null,
                  //   backgroundColor: Theme.of(context).colorScheme.primary,
                  //   child: _profileImage == null
                  //       ? Text(
                  //           userName.isNotEmpty ? userName[0] : '',
                  //           style: const TextStyle(
                  //             fontSize: 36,
                  //             fontWeight: FontWeight.bold,
                  //             color: Colors.white,
                  //           ),
                  //         )
                  //       : null,
                  // ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: _profileImage == null
                          ? const Icon(Icons.camera_alt, color: Colors.white, size: 35)
                          : null,
                    ),
                  ),

                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(userEmail,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account and Budget Info Cards
            Card(
  elevation: 3,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Financial Overview",
            style: Theme.of(context).textTheme.titleMedium),
        const Divider(),

        // Editable Account Balance
        Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _accountBalanceController,
                enabled: _isEditingBudget,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Account Balance (₹)",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            IconButton(
              icon: Icon(
                _isEditingBudget ? Icons.save : Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                if (_isEditingBudget) {
                  _saveBudget();
                } else {
                  setState(() {
                    _isEditingBudget = true;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Editable Monthly Budget
        Row(
          children: [
            const Icon(Icons.pie_chart_outline_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _monthlyBudgetController,
                enabled: _isEditingBudget,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Monthly Budget (₹)",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            IconButton(
              icon: Icon(
                _isEditingBudget ? Icons.save : Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                if (_isEditingBudget) {
                  _saveBudget();
                } else {
                  setState(() {
                    _isEditingBudget = true;
                  });
                }
              },
            ),
          ],
        ),
      ],
    ),
  ),
),

            const SizedBox(height: 20),

            // Feedback & Support
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.star_rate_outlined),
                    title: const Text("Rate BudgetBuddy"),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text("Contact Support"),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                    title: const Text(
                      "Delete Account",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                    onTap: _confirmDeleteAccount,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            

            // Logout button
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LogInPage()),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text("Log out",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.redAccent)),
              ),
            ),
          ],
        ),
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
