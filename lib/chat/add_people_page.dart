// lib/chat/add_people_page.dart

import 'package:flutter/material.dart';

// --- COLORS (from chat_list_screen.dart) ---
const Color primaryColor = Color(0xFF7BAFFC);
const Color secondaryColor = Color(0xFFD6A8FF);
const Color accentColor = Color(0xFFEAEFFF);
const Color textPrimaryColor = Color(0xFF1A1A1A);
const Color textSecondaryColor = Color(0xFF6B6B6B);

class AddPeoplePage extends StatefulWidget {
  const AddPeoplePage({super.key});

  @override
  State<AddPeoplePage> createState() => _AddPeoplePageState();
}

class _AddPeoplePageState extends State<AddPeoplePage> {
  final TextEditingController _searchController = TextEditingController();

  // Mock contact list
  final List<Map<String, String>> contacts = [
    {
      "name": "Sejal",
      "image": "https://i.pravatar.cc/150?img=5",
    },
    {
      "name": "Aarav",
      "image": "https://i.pravatar.cc/150?img=6",
    },
    {
      "name": "Priya",
      "image": "https://i.pravatar.cc/150?img=7",
    },
    {
      "name": "Rohan",
      "image": "https://i.pravatar.cc/150?img=8",
    },
    {
      "name": "Ananya",
      "image": "https://i.pravatar.cc/150?img=9",
    },
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredContacts = contacts
        .where((c) => c["name"]!
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              "Add People",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),

      // Body
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search contacts...",
                prefixIcon: Icon(Icons.search, color: textSecondaryColor),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = filteredContacts[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(contact["image"] ?? ""),
                      radius: 26,
                    ),
                    title: Text(
                      contact["name"] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textPrimaryColor,
                      ),
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text("${contact["name"]} added to group!"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text("Add"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
