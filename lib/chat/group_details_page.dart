import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 1. UPDATED: Imports
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';

// 2. ADDED: Imports for the pages this page links to
import 'split_bill_popup.dart';
import 'add_people_page.dart'; // Make sure this file exists in your project

// 3. RENAMED: Class from GroupChatPage to GroupDetailsPage
class GroupDetailsPage extends StatefulWidget {
  final String groupName;
  final String groupImageUrl;

  const GroupDetailsPage({
    super.key,
    required this.groupName,
    required this.groupImageUrl,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  // State variables for all contacts (for popups)
  List<fc.Contact> contacts = [];
  
  // State variables for this group's members
  List<fc.Contact> groupMembers = [];

  // Demo data for expenses
  final List<Map<String, dynamic>> _expenses = [
    {
      'title': 'Dinner at BBQ Nation',
      'amount': 3200.0,
      'paidBy': 'You',
      'people': ['You', 'Aditi', 'Riya'],
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'title': 'Movie Tickets (Dune)',
      'amount': 750.0,
      'paidBy': 'Aditi',
      'people': ['Aditi', 'Riya'],
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'title': 'Cab Fare',
      'amount': 400.0,
      'paidBy': 'Riya',
      'people': ['You', 'Riya'],
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  // UI Colors
  final List<Color> _gradientColors = const [
    Color(0xFFBEE6FF), // light blue
    Color(0xFFD6B8FF), // light purple
    Color(0xFFFFD6E8), // light pink
  ];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  // 4. UPDATED: Fetches all contacts and populates a demo member list
  Future<void> _fetchContacts() async {
    // Check and request permission
    if (!await fc.FlutterContacts.requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
      }
      return;
    }

    // Get all contacts
    final contactsIterable =
        await fc.FlutterContacts.getContacts(withPhoto: true);
    setState(() {
      contacts = contactsIterable;
      
      // --- DEMO ---
      // In a real app, you would fetch members from Firestore.
      // Here, we just take the first 3 contacts as "members".
      groupMembers = contacts.take(3).toList();
      // --- END DEMO ---
    });
  }

  // 5. ADDED: This function opens the AddPeoplePage
  Future<void> _navigateToAddPeople() async {
    // Launch the AddPeoplePage and wait for a result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPeoplePage()),
    );

    // Check if the result is a contact
    if (result != null && result is fc.Contact) {
      final selectedContact = result;
      
      // Add the contact to your local list (prevent duplicates)
      setState(() {
        if (!groupMembers.any((c) => c.id == selectedContact.id)) {
          groupMembers.add(selectedContact);
        }
      });
      
      // TODO: Save this new member to your Firestore group
      // e.g., FirebaseFirestore.instance.collection('groups')
      //          .doc(YOUR_GROUP_ID).collection('members').add(...)

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${selectedContact.displayName} was added!")),
      );
    }
  }

  // 6. UPDATED: This opens the SplitBillPopup
  void _openSplitBillPopup() {
    showDialog(
      context: context,
      // Pass the *full* contact list to the popup
      builder: (_) => SplitBillPopup(contacts: contacts),
    );
  }

  // 7. UPDATED: Uses fc.Contact
  Widget _buildContactAvatar(fc.Contact contact, {double radius = 22}) {
    final photo = contact.photo;
    if (photo != null) {
      return CircleAvatar(
        backgroundImage: MemoryImage(photo),
        radius: radius,
      );
    }
    // Initials logic
    final names = (contact.displayName).split(' ');
    String initials = '';
    if (names.isNotEmpty) {
      initials = names.map((n) => n.isEmpty ? '' : n[0]).take(2).join();
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blueAccent.withOpacity(0.1),
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
            color: Colors.blueAccent, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 8. ADDED: New widget for expense cards
  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final String title = expense['title'];
    final double amount = expense['amount'];
    final String paidBy = expense['paidBy'];
    final List<String> people = expense['people'];
    final DateTime date = expense['date'];

    // Determine if you owe or are owed (simple logic for demo)
    final bool youPaid = paidBy == 'You';
    final String splitDetails =
        youPaid ? 'You paid ₹$amount' : '$paidBy paid ₹$amount';
    final Color amountColor = youPaid ? Colors.green : Colors.red;

    // Simplified calculation
    final double myShare = youPaid ? amount : -(amount / people.length);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Date Icon
            Column(
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd').format(date),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    splitDetails,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Split with: ${people.join(', ')}',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Amount
            Text(
              myShare > 0
                  ? '+₹${myShare.toInt()}'
                  : '-₹${myShare.abs().toInt()}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Top gradient background
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 9. UPDATED: App bar with "Add Expense" button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(widget.groupImageUrl),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.groupName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // "Add Expense" button
                      IconButton(
                        icon: const Icon(Icons.receipt_long_outlined,
                            color: Colors.black),
                        onPressed: _openSplitBillPopup,
                        tooltip: 'Add Expense',
                      ),
                    ],
                  ),
                ),

                // 10. REPLACED: Chat UI with Members + Expenses list
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 11. ADDED: Members horizontal list
                        const Padding(
                          padding: EdgeInsets.only(
                              top: 20, left: 16, right: 16, bottom: 10),
                          child: Text(
                            "Members",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            // Add 1 to the count for the "Add" button
                            itemCount: groupMembers.length + 1,
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                // This is the "Add Member" button
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: _navigateToAddPeople, // <-- Links to AddPeoplePage
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.grey.shade200,
                                      child: const Icon(Icons.add,
                                          color: Colors.black54),
                                    ),
                                  ),
                                );
                              }
                              // The other items are the member avatars
                              final contact = groupMembers[i - 1];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildContactAvatar(contact),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 20, indent: 16, endIndent: 16),

                        // 12. REPLACED: Messages list with Expenses list
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            // Add 1 to item count for a title
                            itemCount: _expenses.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // Title for the list
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    "Group Expenses",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                              // The actual expense card
                              final expense = _expenses[index - 1];
                              return _buildExpenseCard(expense);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}