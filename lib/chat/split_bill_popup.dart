import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 1. ADDED: Import for Flutter Contacts
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

// 2. UPDATED: Widget now accepts the list of contacts
class SplitBillPopup extends StatefulWidget {
  final List<fc.Contact> contacts;

  const SplitBillPopup({super.key, required this.contacts});

  @override
  State<SplitBillPopup> createState() => _SplitBillPopupState();
}

class _SplitBillPopupState extends State<SplitBillPopup> {
  final TextEditingController _billNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? selectedCategory;
  String splitType = 'Equally';
  bool loading = false;

  // 3. UPDATED: State variables to manage selected contacts and manual amounts
  List<fc.Contact> selectedParticipants = [];
  Map<String, TextEditingController> _manualAmountControllers = {};

  // Define light color palette
  static const Color primaryLightColor = Color(0xFFE0BBE4);
  static const Color secondaryLightColor = Color(0xFF957DAD);
  static const Color buttonGradientStart = Color(0xFF957DAD);
  static const Color buttonGradientEnd = Color(0xFFD291BC);

  // 4. UPDATED: Submit logic to handle manual amounts
  Future<void> submitBill() async {
    if (_billNameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    setState(() => loading = true);

    // Prepare data for Firestore
    final participantNames =
        selectedParticipants.map((c) => c.displayName).toList();
    Map<String, dynamic>? manualAmounts;

    if (splitType == 'Manually') {
      manualAmounts = {};
      for (var entry in _manualAmountControllers.entries) {
        manualAmounts[entry.key] =
            double.tryParse(entry.value.text.trim()) ?? 0;
      }
    }

    await firestore.collection('split_bills').add({
      'bill_name': _billNameController.text.trim(),
      'category': selectedCategory,
      'amount': double.tryParse(_amountController.text.trim()) ?? 0,
      'split_type': splitType,
      'participants': participantNames, // List of names
      'manual_amounts': manualAmounts, // Map of name -> amount
      'created_by': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  // 5. NEW: Function to show the multi-select contact picker dialog
  void _showParticipantSelector() {
    List<fc.Contact> tempList = List.from(selectedParticipants);
    List<fc.Contact> filteredList = List.from(widget.contacts);
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Participants"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.toLowerCase();
                          filteredList = widget.contacts
                              .where((c) => c.displayName
                                  .toLowerCase()
                                  .contains(searchQuery))
                              .toList();
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Search Contacts',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // List of contacts
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final contact = filteredList[index];
                          final isSelected = tempList.contains(contact);

                          return CheckboxListTile(
                            title: Text(contact.displayName),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempList.add(contact);
                                } else {
                                  tempList.remove(contact);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the main popup's state
                    setState(() {
                      selectedParticipants = tempList;
                      _updateManualControllers();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 6. NEW: Helper function to build avatar
  Widget _buildAvatar(fc.Contact contact) {
    final photo = contact.photo;
    if (photo != null) {
      return CircleAvatar(
        backgroundImage: MemoryImage(photo),
        radius: 12,
      );
    }
    return CircleAvatar(
      radius: 12,
      child: Text(contact.displayName.isNotEmpty ? contact.displayName[0] : ''),
    );
  }

  // 7. NEW: Function to manage TextControllers for manual split
  void _updateManualControllers() {
    Map<String, TextEditingController> newControllers = {};
    for (var participant in selectedParticipants) {
      newControllers[participant.displayName] =
          _manualAmountControllers[participant.displayName] ??
              TextEditingController();
    }
    // Dispose old controllers that are no longer needed
    _manualAmountControllers.forEach((key, controller) {
      if (!newControllers.containsKey(key)) {
        controller.dispose();
      }
    });
    _manualAmountControllers = newControllers;
  }

  // 8. NEW: Widget for manual amount text fields
  Widget _buildManualAmountFields() {
    if (splitType != 'Manually' || selectedParticipants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text(
          "Enter Amounts",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectedParticipants.length,
          itemBuilder: (context, index) {
            final contact = selectedParticipants[index];
            final controller = _manualAmountControllers[contact.displayName]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      contact.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: _buildCleanInput(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "₹ 0.00",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Disposing controllers
  @override
  void dispose() {
    _billNameController.dispose();
    _amountController.dispose();
    _manualAmountControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      // 9. UPDATED: Wrapped in SingleChildScrollView to prevent overflow
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  const Text(
                    "Split Bill",
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

              // Bill Name
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

              // Amount
              _buildCleanInput(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Amount",
                    prefixIcon:
                        Icon(Icons.currency_rupee, color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 15),

              // Category (This is unchanged)
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
                      value: selectedCategory, // Changed from initialValue
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.black54),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Split Type
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Split Equally"),
                    selected: splitType == 'Equally',
                    selectedColor: primaryLightColor,
                    onSelected: (_) => setState(() => splitType = 'Equally'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Split Manually"),
                    selected: splitType == 'Manually',
                    selectedColor: primaryLightColor,
                    onSelected: (_) => setState(() => splitType = 'Manually'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 10. REPLACED: Participant logic
              const Text(
                "Participants",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              // Button to open selector
              _buildCleanInput(
                child: TextButton(
                  onPressed: _showParticipantSelector,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add_outlined,
                          color: Colors.black54),
                      SizedBox(width: 10),
                      Text(
                        "Select Participants",
                        style: TextStyle(
                            color: Colors.black87, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Chips for selected participants
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: selectedParticipants.map((contact) {
                  return Chip(
                    avatar: _buildAvatar(contact),
                    label: Text(contact.displayName),
                    onDeleted: () {
                      setState(() {
                        selectedParticipants.remove(contact);
                        _updateManualControllers();
                      });
                    },
                  );
                }).toList(),
              ),

              // 11. ADDED: Manual amount fields
              _buildManualAmountFields(),

              const SizedBox(height: 30),

              // Save Button (Unchanged)
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Expense",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}