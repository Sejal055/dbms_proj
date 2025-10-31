import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart'; // New dependency

import 'individual_chat_page.dart';
import 'group_chat_page.dart';
import 'add_people_page.dart';

// --- COLORS ---
const Color primaryColor = Color(0xFF7BAFFC);
const Color secondaryColor = Color(0xFFD6A8FF);
const Color incomeColor = Color(0xFF5F97F2);
const Color expenseColor = Color(0xFFB77BFF);
const Color progressFill = Color(0xFF5F97F2);
const Color unreadCountColor = secondaryColor;
const Color deliveredColor = Colors.grey;
const Color readColor = secondaryColor;
const Color iconWhite = Colors.white;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _selectedTabIndex = 0;
  bool _showSearch = false;
  String _searchQuery = '';
  bool _showMenu = false;

  // Updated type to Contact from flutter_contacts
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];

  // Dummy data for other tabs
  final List<GroupData> dummyGroupData = [
    GroupData(name: "Flutter Devs", members: 12),
    GroupData(name: "Goa College", members: 25),
    GroupData(name: "Movie Fans", members: 8),
    GroupData(name: "Food Lovers", members: 15),
  ];

  final List<Settlement> dummyOverallData = [
    Settlement(
      personName: 'Sarah Rollins',
      amount: 500,
      youOwe: true,
      date: DateTime.now().subtract(const Duration(days: 1)),
      imageUrl: 'https://i.pravatar.cc/150?img=3',
    ),
    Settlement(
      personName: 'John Doe',
      amount: 200,
      youOwe: false,
      date: DateTime.now().subtract(const Duration(days: 3)),
      imageUrl: 'https://i.pravatar.cc/150?img=4',
    ),
    Settlement(
      personName: 'Priya Sharma',
      amount: 120,
      youOwe: false,
      date: DateTime.now().subtract(const Duration(days: 5)),
      imageUrl: 'https://i.pravatar.cc/150?img=7',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  // --- UPDATED CONTACT FETCHING LOGIC ---
  Future<void> _fetchContacts() async {
    // Request permission using flutter_contacts, no need for permission_handler
    if (!await FlutterContacts.requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
      }
      return;
    }

    // Load contacts, requesting only necessary properties (display name and photo)
    try {
      List<Contact> allContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      // Sort contacts alphabetically
      allContacts.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (mounted) {
        setState(() {
          contacts = allContacts;
          filteredContacts = contacts;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  void _filterContacts(String query) {
    query = query.toLowerCase();
    setState(() {
      _searchQuery = query;
      filteredContacts = contacts.where((contact) {
        final name = contact.displayName; // displayName is non-null with getContacts
        return name.toLowerCase().contains(query);
      }).toList();
    });
  }

  // --- UPDATED AVATAR WIDGET ---
  Widget _buildContactAvatar(Contact contact) {
    // flutter_contacts uses 'photo' instead of 'avatar'
    if (contact.photo != null) {
      return CircleAvatar(
        backgroundImage: MemoryImage(contact.photo!),
        radius: 28,
      );
    }
    
    // Fallback to initials
    final names = contact.displayName.split(' ');
    String initials = '';
    if (names.isNotEmpty) {
      initials = names.map((n) => n.isEmpty ? '' : n[0]).take(2).join();
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: primaryColor,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTopTabs() {
    const tabNames = ['Chats', 'Groups', 'Overall'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(13, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: List.generate(tabNames.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _selectedTabIndex = index);
                // Reset search when switching tabs
                setState(() {
                  _searchQuery = '';
                  if (index == 0) {
                    filteredContacts = contacts;
                  }
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    tabNames[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 3,
                    width: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  List<T> _filterData<T>(List<T> data) {
    if (_searchQuery.isEmpty) return data;
    if (T == GroupData) {
      return data
          .where((item) =>
              (item as GroupData).name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    } else if (T == Settlement) {
      return data
          .where((item) =>
              (item as Settlement).personName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return data;
  }

  Widget _buildContent() {
    if (_selectedTabIndex == 0) {
      if (filteredContacts.isEmpty) {
        return Center(
            child:
                Text(_searchQuery.isEmpty ? "No contacts found." : "No matching contacts."));
      }
      return ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        itemCount: filteredContacts.length,
        itemBuilder: (context, index) {
          final contact = filteredContacts[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            leading: _buildContactAvatar(contact),
            title: Text(contact.displayName), // displayName is non-null
            subtitle: (contact.phones.isNotEmpty) 
                ? Text(contact.phones.first.number) 
                : const Text('Tap to chat'), // show phone number if available
            trailing: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chat started with ${contact.displayName}')),
                );
                // Implement chat start logic here
              },
              icon: const Icon(Icons.chat_bubble),
              label: const Text("Chat"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IndividualChatPage(
                    name: contact.displayName,
                    imageUrl: '',
                  ),
                ),
              );
            },
          );
        },
      );
    } else if (_selectedTabIndex == 1) {
      final filtered = _filterData<GroupData>(dummyGroupData);
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: const Icon(Icons.group, color: primaryColor, size: 36),
            title: _highlightText(filtered[index].name, _searchQuery),
            subtitle: Text("${filtered[index].members} members"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupChatPage(
                    groupName: filtered[index].name,
                    groupImageUrl: 'https://i.pravatar.cc/150?img=5',
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      final filtered = _filterData<Settlement>(dummyOverallData);
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color.fromARGB(25, 123, 175, 252),
              backgroundImage: NetworkImage(filtered[index].imageUrl),
            ),
            title: _highlightText(filtered[index].personName, _searchQuery),
            subtitle: Text(filtered[index].youOwe
                ? "You owe ₹${filtered[index].amount.toStringAsFixed(0)}"
                : "${filtered[index].personName} owes you ₹${filtered[index].amount.toStringAsFixed(0)}"),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  if (value == 'Mark Paid') {
                    // Update state correctly
                    final updatedSettlement = filtered[index].copyWith(youOwe: false);
                    final originalIndex = dummyOverallData.indexOf(filtered[index]);
                    if (originalIndex != -1) {
                      dummyOverallData[originalIndex] = updatedSettlement;
                      // Re-filter the list to update the UI
                      _filterData<Settlement>(dummyOverallData);
                    }
                  } else if (value == 'Delete') {
                    dummyOverallData.remove(filtered[index]);
                    // Re-filter the list to update the UI
                    _filterData<Settlement>(dummyOverallData);
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Mark Paid', child: Text('Mark as Paid')),
                const PopupMenuItem(value: 'Left to Pay', child: Text('Left to Pay')),
                const PopupMenuItem(value: 'Delete', child: Text('Delete')),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(filtered[index].date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Text _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);
    if (startIndex == -1) return Text(text);
    final endIndex = startIndex + query.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
              text: text.substring(startIndex, endIndex),
              style: const TextStyle(
                  backgroundColor: Colors.yellow, fontWeight: FontWeight.bold)),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('M/d/yyyy').format(date);
  }

  Widget _buildMenuBox() {
    return Positioned(
      top: 90,
      right: 15,
      child: Material(
        color: Colors.white,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _menuItem(Icons.lock, "Privacy"),
            _menuItem(Icons.chat, "Chats"),
            _menuItem(Icons.list, "List"),
            _menuItem(Icons.notifications, "Notifications"),
            _menuItem(Icons.accessibility_new, "Accessibility"),
          ]),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title) {
    return InkWell(
      onTap: () {
        // Toggle menu off when item is clicked
        setState(() => _showMenu = false); 
        print("$title clicked");
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: iconWhite, size: 26),
          ),
          const Text(
            'Chats',
            style: TextStyle(
              color: iconWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _showSearch = !_showSearch);
                },
                child: const Icon(Icons.search, color: iconWhite, size: 26),
              ),
              const SizedBox(width: 15),
              InkWell(
                onTap: () {
                  setState(() => _showMenu = !_showMenu);
                },
                child: const Icon(Icons.menu, color: iconWhite, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(25, 214, 168, 255),
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color.fromARGB(230, 123, 175, 252), secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search people or groups...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        if (_selectedTabIndex == 0) {
                          _filterContacts(v);
                        } else {
                          setState(() => _searchQuery = v);
                        }
                      },
                    ),
                  ),
                _buildTopTabs(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                    ),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
          if (_showMenu) _buildMenuBox(),
          Positioned(
            bottom: 25,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPeoplePage(),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

// MODELS

class GroupData {
  final String name;
  final int members;
  GroupData({required this.name, required this.members});
}

class Settlement {
  final String personName;
  final double amount;
  final bool youOwe;
  final DateTime date;
  final String imageUrl;

  Settlement({
    required this.personName,
    required this.amount,
    required this.youOwe,
    required this.date,
    required this.imageUrl,
  });

  Settlement copyWith({bool? youOwe}) {
    return Settlement(
      personName: personName,
      amount: amount,
      youOwe: youOwe ?? this.youOwe,
      date: date,
      imageUrl: imageUrl,
    );
  }
}