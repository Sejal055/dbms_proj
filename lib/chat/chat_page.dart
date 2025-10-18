import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'individual_chat_page.dart';
import 'group_chat_page.dart';
import 'add_people_page.dart'; // ✅ Added this import for Add People navigation

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

// --- DUMMY USER DATA ---
const Map<String, String> dummyUsers = {
  'oluvatobi_sam': 'https://i.pravatar.cc/150?img=1',
  'sarah_rollins': 'https://i.pravatar.cc/150?img=2',
  'malcom_eddie': 'https://i.pravatar.cc/150?img=3',
  'zoey_dev': 'https://i.pravatar.cc/150?img=4',
};

// --- CHAT LIST SCREEN ---
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

  // --- DUMMY DATA ---
  final List<ChatTileData> dummyChatData = [
    ChatTileData(
      name: 'Oluwatobi Sam',
      message: 'Can we go see a movie?',
      time: DateTime.now(),
      status: MessageStatus.justNow,
      isUnread: true,
      unreadCount: 6,
      userId: 'oluvatobi_sam',
    ),
    ChatTileData(
      name: 'Sarah Rollins',
      message: "You: Sure, I’ll message John.",
      time: DateTime.now().subtract(const Duration(hours: 1)),
      status: MessageStatus.delivered,
      isUnread: false,
      userId: 'sarah_rollins',
    ),
    ChatTileData(
      name: 'Malcom Eddie',
      message: 'You: Too good bro!',
      time: DateTime.now().subtract(const Duration(days: 1)),
      status: MessageStatus.read,
      isUnread: false,
      userId: 'malcom_eddie',
    ),
    ChatTileData(
      name: 'Zoey',
      message: 'Hey man, drinks tonight?',
      time: DateTime.now().subtract(const Duration(days: 1)),
      status: MessageStatus.delivered,
      isUnread: true,
      unreadCount: 7,
      userId: 'zoey_dev',
    ),
  ];

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

  // --- TOP TABS ---
  Widget _buildTopTabs() {
    const tabNames = ['Chats', 'Groups', 'Overall'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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

  // --- SEARCH FILTER ---
  List<T> _filterData<T>(List<T> data) {
    if (_searchQuery.isEmpty) return data;
    if (T == ChatTileData) {
      return data
          .where((item) => (item as ChatTileData)
              .name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    } else if (T == GroupData) {
      return data
          .where((item) => (item as GroupData)
              .name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    } else if (T == Settlement) {
      return data
          .where((item) => (item as Settlement)
              .personName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return data;
  }

  // --- MAIN CONTENT ---
  Widget _buildContent() {
    if (_selectedTabIndex == 0) {
      final filtered = _filterData<ChatTileData>(dummyChatData);
      return ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IndividualChatPage(
                  name: filtered[index].name,
                  imageUrl: dummyUsers[filtered[index].userId] ??
                      dummyUsers.values.first,
                ),
              ),
            );
          },
          child: ChatTile(
            data: filtered[index],
            highlight: _searchQuery,
          ),
        ),
      );
    } else if (_selectedTabIndex == 1) {
      final filtered = _filterData<GroupData>(dummyGroupData);
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withOpacity(0.1),
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
                    filtered[index] =
                        filtered[index].copyWith(youOwe: false);
                  } else if (value == 'Delete') {
                    dummyOverallData.remove(filtered[index]);
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'Mark Paid', child: Text('Mark as Paid')),
                const PopupMenuItem(
                    value: 'Left to Pay', child: Text('Left to Pay')),
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

  // --- MENU BOX ---
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuItem(Icons.lock, "Privacy"),
              _menuItem(Icons.chat, "Chats"),
              _menuItem(Icons.list, "List"),
              _menuItem(Icons.notifications, "Notifications"),
              _menuItem(Icons.accessibility_new, "Accessibility"),
            ],
          ),
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
            Text(title,
                style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // --- APP BAR ---
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

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor.withOpacity(0.1),
      body: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.9), secondaryColor],
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search people or groups...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                _buildTopTabs(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -5))
                      ],
                    ),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
          if (_showMenu) _buildMenuBox(),

          // ✅ FloatingActionButton navigates to AddPeoplePage
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
                    builder: (context) => const AddPeoplePage(), // ✅ Working navigation
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

// --- MODELS ---
enum MessageStatus { justNow, delivered, read }

class ChatTileData {
  final String name;
  final String message;
  final DateTime time;
  final MessageStatus status;
  final bool isUnread;
  final int unreadCount;
  final String userId;

  ChatTileData({
    required this.name,
    required this.message,
    required this.time,
    required this.status,
    required this.isUnread,
    this.unreadCount = 0,
    required this.userId,
  });
}

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

// --- CHAT TILE ---
class ChatTile extends StatelessWidget {
  final ChatTileData data;
  final String highlight;
  const ChatTile({super.key, required this.data, this.highlight = ''});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      if (diff.inMinutes < 1) return 'just now';
      return DateFormat('h:mm a').format(time);
    }
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('M/d/yyyy').format(time);
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage:
            NetworkImage(dummyUsers[data.userId] ?? dummyUsers['zoey_dev']!),
      ),
      title: _highlightText(data.name, highlight),
      subtitle: Text(
        data.message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: data.isUnread ? Colors.black : Colors.grey[600],
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(data.time),
            style: TextStyle(
              fontSize: 12,
              color: data.isUnread ? unreadCountColor : Colors.grey[600],
              fontWeight:
                  data.isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (data.status != MessageStatus.justNow)
            Icon(
              data.status == MessageStatus.read
                  ? Icons.done_all
                  : Icons.done,
              size: 16,
              color: data.status == MessageStatus.read
                  ? readColor
                  : deliveredColor,
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IndividualChatPage(
              name: data.name,
              imageUrl:
                  dummyUsers[data.userId] ?? dummyUsers.values.first,
            ),
          ),
        );
      },
    );
  }
}
