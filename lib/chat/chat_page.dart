import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- COLORS ---
const Color primaryColor = Color(0xFF7BAFFC);
const Color secondaryColor = Color(0xFFD6A8FF);
const Color incomeColor = Color(0xFF5F97F2);
const Color expenseColor = Color(0xFFB77BFF);
const Color progressFill = Color(0xFF5F97F2);
const Color iconWhite = Colors.white;

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({super.key});

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  bool _showSearch = false;
  String _searchQuery = '';
  bool _showMenu = false;

  // Settlement data
  final List<Settlement> settlements = [
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

  List<Settlement> _filterSettlements() {
    if (_searchQuery.isEmpty) return settlements;
    return settlements
        .where((item) =>
            item.personName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildContent() {
    final filtered = _filterSettlements();
    
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? "No settlements found." : "No matching settlements.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

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
          subtitle: Text(
            filtered[index].youOwe
                ? "You owe ₹${filtered[index].amount.toStringAsFixed(0)}"
                : "${filtered[index].personName} owes you ₹${filtered[index].amount.toStringAsFixed(0)}",
            style: TextStyle(
              color: filtered[index].youOwe ? Colors.red : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'Mark Paid') {
                  filtered[index] = filtered[index].copyWith(youOwe: false);
                } else if (value == 'Delete') {
                  settlements.remove(filtered[index]);
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDate(filtered[index].date),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.more_vert, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
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
      onTap: () => print("$title clicked"),
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
            'Settlements',
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
                        hintText: 'Search settlements...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                      ],
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
                // Add new settlement
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add settlement feature')),
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
