import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplitBillPopup extends StatefulWidget {
  const SplitBillPopup({super.key});

  @override
  State<SplitBillPopup> createState() => _SplitBillPopupState();
}

class _SplitBillPopupState extends State<SplitBillPopup> {
  final TextEditingController _billNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? selectedCategory;
  String splitType = 'Equally'; // Re-integrated
  List<String> selectedParticipants = []; // Re-integrated
  bool loading = false;

  // Define light color palette
  static const Color primaryLightColor = Color(0xFFE0BBE4); // Light Lavender (Background/Accent)
  static const Color secondaryLightColor = Color(0xFF957DAD); // Muted Purple (Text/Selection)
  static const Color buttonGradientStart = Color(0xFF957DAD); // Button color
  static const Color buttonGradientEnd = Color(0xFFD291BC); // Button color

  Future<void> submitBill() async {
    if (_billNameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        selectedCategory == null) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    setState(() => loading = true);

    await firestore.collection('split_bills').add({
      'bill_name': _billNameController.text.trim(),
      'category': selectedCategory,
      'amount': double.tryParse(_amountController.text.trim()) ?? 0,
      'split_type': splitType,
      'participants': selectedParticipants,
      'created_by': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  // A custom widget function to wrap TextFields and Dropdowns for the clean look
  Widget _buildCleanInput({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // Use white background for the clean look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Close Icon and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),
                const Text(
                  "Split Bill", // Reverted to Split Bill
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Bill Name Input
            _buildCleanInput(
              child: TextField(
                controller: _billNameController,
                decoration: const InputDecoration(
                  hintText: "Expense Name",
                  prefixIcon: Icon(Icons.edit_note, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 15),

            // Amount Input
            _buildCleanInput(
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Amount",
                  prefixIcon: Icon(Icons.currency_rupee, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 15),

            // Category dropdown
            _buildCleanInput(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text("Loading Categories..."),
                    );
                  }
                  final categories = snapshot.data!.docs
                      .map((doc) => doc['name'] as String)
                      .toList();

                  return DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedCategory = val),
                    decoration: const InputDecoration(
                      hintText: "Category",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Split Type (Equally/Manually)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Split Equally"),
                  selected: splitType == 'Equally',
                  selectedColor: primaryLightColor, // Light accent color
                  onSelected: (_) => setState(() => splitType = 'Equally'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Split Manually"),
                  selected: splitType == 'Manually',
                  selectedColor: primaryLightColor, // Light accent color
                  onSelected: (_) => setState(() => splitType = 'Manually'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Select Participants (Re-integrated)
            _buildCleanInput(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc('groupId') // replace with actual selected group ID
                    .collection('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final members = snapshot.data!.docs
                      .map((doc) => doc['name'] as String)
                      .toList();

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      hintText: "Select Participants",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    ),
                    items: members
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null && !selectedParticipants.contains(val)) {
                        setState(() => selectedParticipants.add(val));
                      }
                    },
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Save Button (with Gradient and Light Colors)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [buttonGradientStart, buttonGradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ElevatedButton(
                onPressed: loading ? null : submitBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Expense", // Changed to match your request
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}