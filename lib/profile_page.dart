import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// REQUIRED for image upload
import 'package:firebase_storage/firebase_storage.dart';
import 'auth/login_page.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String userEmail = '';
  String profileImageUrl = '';
  double monthlyBudget = 0;
  double accountBalance = 0;
  // --- MODIFIED: Renamed _isEditing to be more specific ---
  bool _isEditingProfile = false;
  // --- END MODIFICATION ---
  bool _isEditingBudget = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _accountBalanceController =
      TextEditingController();
  final TextEditingController _monthlyBudgetController =
      TextEditingController();

  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = data['name'] ?? '';
          userEmail = data['email'] ?? '';
          profileImageUrl = data['profile_image_url'] ?? '';
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

  // --- START: MODIFIED IMAGE UPLOAD LOGIC ---
  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // --- REMOVED: The check for _isEditing. Now it just picks an image. ---
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      final File imageFile = File(image.path);

      // 1. Upload file to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${user.uid}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Save the download URL to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profile_image_url': downloadUrl});

      // 3. Update local state
      setState(() {
        _profileImage = imageFile; // Keep this for immediate display
        profileImageUrl = downloadUrl; // Store the URL for persistent display
        // --- REMOVED: No longer need to set _isEditing = false ---
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture uploaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    }
  }
  // --- END: MODIFIED IMAGE UPLOAD LOGIC ---

  // --- MODIFIED: This function now saves *only* the name ---
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'name': _nameController.text.trim(),
          // We don't update email here, as it's more complex (requires re-auth)
          // and wasn't requested.
        },
      );
      setState(() {
        userName = _nameController.text.trim();
        _isEditingProfile = false; // Use the new variable
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    }
  }
  // --- END MODIFICATION ---

  Future<void> _saveBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      double? newAccountBalance = double.tryParse(
        _accountBalanceController.text.trim(),
      );
      double? newMonthlyBudget = double.tryParse(
        _monthlyBudgetController.text.trim(),
      );
      if (newAccountBalance == null || newMonthlyBudget == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid numbers.")),
        );
        return;
      }

      // 1. Update the main document (Your existing code)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'amount_in_account': newAccountBalance,
          'monthly_budget': newMonthlyBudget,
        },
      );

      // 2. Also update the *current month's* budget subcollection
      final now = DateTime.now();
      final currentMonthKey = DateFormat('yyyy-MM').format(now);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(currentMonthKey)
          .set({
        'total_budget': newMonthlyBudget,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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
          "Are you sure you want to permanently delete your account? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
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
        final user = FirebaseAuth.instance.currentUser!;
        final email = user.email!;

        String? password = await _showPasswordDialog();
        if (password != null && password.isNotEmpty) {
          try {
            AuthCredential credential = EmailAuthProvider.credential(
              email: email,
              password: password,
            );

            await user.reauthenticateWithCredential(credential);
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .delete();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
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
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  // ⭐ STAR RATING DIALOG
  void _showRatingDialog() {
    double rating = 0;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Rate BudgetBuddy"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() => rating = index + 1.0);
                      },
                    );
                  }),
                ),
                TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    hintText: "Write your feedback (optional)",
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (rating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a rating.")),
                    );
                    return;
                  }
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance
                      .collection('app_feedback')
                      .add({
                    'user_id': user?.uid,
                    'email': user?.email,
                    'rating': rating,
                    'feedback': feedbackController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thanks for your feedback!")),
                  );
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  // 📩 CONTACT SUPPORT FORM
  void _showSupportForm() {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contact Support"),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            hintText: "Describe your issue or suggestion",
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a message.")),
                );
                return;
              }
              await FirebaseFirestore.instance
                  .collection('support_messages')
                  .add({
                'user_id': user?.uid,
                'email': user?.email,
                'message': messageController.text.trim(),
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Your message has been sent!")),
              );
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the image provider based on available data
    ImageProvider? imageProvider;
    if (_profileImage != null) {
      // Use the newly picked image for immediate display
      imageProvider = FileImage(_profileImage!);
    } else if (profileImageUrl.isNotEmpty) {
      // Use the URL from Firestore (persisted image)
      imageProvider = NetworkImage(profileImageUrl);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
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
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickAndUploadImage, // Calls the new upload function
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: imageProvider,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: imageProvider == null
                            ? const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 35,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- MODIFIED: Editable Name Field ---
                          TextField(
                            controller: _nameController,
                            enabled: _isEditingProfile,
                            style: Theme.of(context).textTheme.titleLarge,
                            decoration: InputDecoration(
                              // Show a border only when editing
                              border: _isEditingProfile
                                  ? const UnderlineInputBorder()
                                  : InputBorder.none,
                              isDense: true,
                              // Adjust padding to align text
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                            ),
                          ),
                          // --- END MODIFICATION ---
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    // --- ADDED: Edit/Save Button for Profile ---
                    IconButton(
                      icon: Icon(
                        _isEditingProfile ? Icons.save : Icons.edit,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        if (_isEditingProfile) {
                          _saveProfile();
                        } else {
                          setState(() => _isEditingProfile = true);
                        }
                      },
                    ),
                    // --- END ADDITION ---
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Financial Overview
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Financial Overview",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      _buildEditableField(
                        icon: Icons.account_balance_wallet_outlined,
                        controller: _accountBalanceController,
                        label: "Account Balance (₹)",
                      ),
                      const SizedBox(height: 10),
                      _buildEditableField(
                        icon: Icons.pie_chart_outline_rounded,
                        controller: _monthlyBudgetController,
                        label: "Monthly Budget (₹)",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Feedback & Support
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.star_rate_outlined),
                      title: const Text("Rate BudgetBuddy"),
                      onTap: _showRatingDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.support_agent_outlined),
                      title: const Text("Contact Support"),
                      onTap: _showSupportForm,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        "Delete Account",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: _confirmDeleteAccount,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                  label: const Text(
                    "Log out",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required TextEditingController controller,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: _isEditingBudget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
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
              setState(() => _isEditingBudget = true);
            }
          },
        ),
      ],
    );
  }
}