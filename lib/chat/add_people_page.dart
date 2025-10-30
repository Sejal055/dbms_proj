import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart'; // Replaced contacts_service

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

  // Updated type to Contact from flutter_contacts
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];

  String searchQuery = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  // --- UPDATED CONTACT FETCHING LOGIC ---
  Future<void> _fetchContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      // Permission denied, handle gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied. Please grant access in settings.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Load all contacts, only fetching displayName and photo (avatar) for efficiency.
    try {
      List<Contact> allContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      // Sort contacts alphabetically by display name
      allContacts.sort((a, b) => (a.displayName).compareTo(b.displayName));

      if (mounted) {
        setState(() {
          contacts = allContacts;
          filteredContacts = allContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterContacts(String query) {
    query = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredContacts = contacts.where((contact) {
        final name = contact.displayName;
        return name.toLowerCase().contains(query);
      }).toList();
    });
  }

  // --- UPDATED AVATAR WIDGET ---
  Widget _buildContactAvatar(Contact contact) {
    // flutter_contacts uses 'photo' instead of 'avatar' and returns a Uint8List.
    if (contact.photo != null) {
      return CircleAvatar(
        backgroundImage: MemoryImage(contact.photo!),
        radius: 26,
      );
    } else {
      // If no photo, show initials
      String initials = "";
      final names = (contact.displayName).split(" ");
      if (names.isNotEmpty) {
        // Take the first character of the first two names
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
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(38, 158, 158, 158),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: Offset(0, 3),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : filteredContacts.isEmpty
                    ? Center(child: Text(searchQuery.isEmpty ? "No contacts found." : "No match for \"$searchQuery\"", style: const TextStyle(color: textSecondaryColor)))
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
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(31, 158, 158, 158),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: _buildContactAvatar(contact),
                              title: Text(
                                contact.displayName, // displayName is non-null with flutter_contacts
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: textPrimaryColor,
                                ),
                              ),
                              // Display the first phone number if available
                              subtitle: (contact.phones.isNotEmpty) 
                                  ? Text(
                                      contact.phones.first.number,
                                      style: const TextStyle(color: textSecondaryColor),
                                    )
                                  : null,
                              trailing: ElevatedButton.icon(
                                onPressed: () {
                                  // Example action: use the phone number or ID of the contact
                                  String detail = contact.phones.isNotEmpty 
                                      ? contact.phones.first.number
                                      : contact.id;
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Added ${contact.displayName} ($detail) to group!"),
                                      duration: const Duration(seconds: 2),
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