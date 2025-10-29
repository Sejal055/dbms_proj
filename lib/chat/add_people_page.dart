import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

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

  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    // Request permission
    var permissionStatus = await Permission.contacts.status;
    if (!permissionStatus.isGranted) {
      permissionStatus = await Permission.contacts.request();
      if (!permissionStatus.isGranted) {
        // Permission denied, handle gracefully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
        return;
      }
    }

    // Load contacts
    Iterable<Contact> contactsIterable = await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      contacts = contactsIterable.toList();
      filteredContacts = contacts;
    });
  }

  void _filterContacts(String query) {
    query = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredContacts = contacts.where((contact) {
        final name = contact.displayName ?? "";
        return name.toLowerCase().contains(query);
      }).toList();
    });
  }

  Widget _buildContactAvatar(Contact contact) {
    if (contact.avatar != null && contact.avatar!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: MemoryImage(contact.avatar!),
        radius: 26,
      );
    } else {
      // If no avatar, show initials
      String initials = "";
      final names = (contact.displayName ?? "").split(" ");
      if (names.isNotEmpty) {
        initials = names.map((n) => n.isEmpty ? "" : n[0]).take(2).join();
      }
      return CircleAvatar(
        backgroundColor: primaryColor,
        radius: 26,
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Color.fromARGB(38, 158, 158, 158),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: _filterContacts,
            ),
          ),

          // List
          Expanded(
            child: filteredContacts.isEmpty
                ? Center(child: Text(searchQuery.isEmpty ? "No contacts found." : "No match for \"$searchQuery\""))
                : ListView.builder(
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
                              color: Color.fromARGB(31, 158, 158, 158),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: _buildContactAvatar(contact),
                          title: Text(
                            contact.displayName ?? "",
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
                                  content: Text("${contact.displayName} added to group!"),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text("Add"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
