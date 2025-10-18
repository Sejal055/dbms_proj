import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// --- COLORS ---
const Color primaryColor = Color(0xFF7BAFFC); // Header, tabs, FAB
const Color secondaryColor = Color(0xFFD6A8FF); // Accent / unread / read ticks
const Color incomeColor = Color(0xFF5F97F2); // Optional: settlements "you get"
const Color expenseColor = Color(0xFFB77BFF); // Optional: settlements "you owe"
const Color progressFill = Color(0xFF5F97F2); // Optional: progress bars
const Color unreadCountColor = secondaryColor; // Unread bubble
const Color deliveredColor = Colors.grey;
const Color readColor = secondaryColor;
const Color iconWhite = Colors.white;

// --- DUMMY DATA FOR DEMO USER IMAGES ---
const Map<String, String> dummyUsers = {
  'oluvatobi_sam': 'https://i.pravatar.cc/150?img=1',
  'sarah_rollins': 'https://i.pravatar.cc/150?img=2',
  'malcom_eddie': 'https://i.pravatar.cc/150?img=3',
  'zoey_dev': 'https://i.pravatar.cc/150?img=4',
  'jamie_dev': 'https://i.pravatar.cc/150?img=5',
  'helen_k': 'https://i.pravatar.cc/150?img=6',
  'steve_j': 'https://i.pravatar.cc/150?img=7',
};

// --- CHAT LIST SCREEN ---
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isAuthReady = false;
  int _selectedTabIndex = 0; // 0 - Chats, 1 - Group, 2 - Overall

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      await _auth.signInAnonymously();
      _currentUser = _auth.currentUser;
    } catch (e) {
      print("Auth Error: $e");
    } finally {
      setState(() {
        _isAuthReady = true;
      });
    }
  }

  Widget _buildTopTabs() {
    const tabNames = ['Chats', 'Group', 'Overall'];
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
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(tabNames.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
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
                  // Line Indicator
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

  Widget _buildChatList() {
    if (!_isAuthReady) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    // Dummy chat data
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
        message: "You: Yes, you can send it to john, he'll see it.",
        time: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        status: MessageStatus.delivered,
        isUnread: false,
        userId: 'sarah_rollins',
      ),
      ChatTileData(
        name: 'Malcom Eddie',
        message: 'You: Too good bro, this is awesome',
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

    // Here, we can switch between Chats / Group / Overall based on _selectedTabIndex
    // Currently dummy implementation
    final content = _selectedTabIndex == 0
        ? dummyChatData // Chats
        : _selectedTabIndex == 1
            ? dummyChatData // Group chats placeholder
            : dummyChatData; // Overall placeholder

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final chat = content[index];
        return ChatTile(data: chat);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor.withOpacity(0.1),
      body: Stack(
        children: [
          // Top header background
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.9), secondaryColor.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildTopTabs(),
                // Chat list container
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
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
                    child: _buildChatList(),
                  ),
                ),
              ],
            ),
          ),
          // Floating Action Button
          Positioned(
            bottom: 25,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => print("Add people to chat"),
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
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
            children: const [
              Icon(Icons.search, color: iconWhite, size: 26),
              SizedBox(width: 15),
              Icon(Icons.menu, color: iconWhite, size: 26),
            ],
          ),
        ],
      ),
    );
  }
}

// --- ENUMS AND MODELS ---
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

// --- CHAT TILE WIDGET ---
class ChatTile extends StatelessWidget {
  final ChatTileData data;
  const ChatTile({super.key, required this.data});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      if (diff.inMinutes < 1) return 'just now';
      return DateFormat('h:mm a').format(time);
    }
    if (diff.inDays == 1 && now.day != time.day) return 'Yesterday';
    return DateFormat('M/d/yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: NetworkImage(
                  dummyUsers[data.userId] ?? dummyUsers['zoey_dev']!),
            ),
            if (data.isUnread && data.unreadCount > 0)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: unreadCountColor,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: Text(
                    '${data.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          data.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          data.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: data.isUnread ? Colors.black : Colors.grey[600],
            fontWeight: data.isUnread ? FontWeight.w500 : FontWeight.normal,
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
                fontWeight: data.isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            if (data.status != MessageStatus.justNow)
              Icon(
                data.status == MessageStatus.read ? Icons.done_all : Icons.done,
                size: 16,
                color: data.status == MessageStatus.read
                    ? readColor
                    : deliveredColor,
              ),
          ],
        ),
      ),
    );
  }
}
