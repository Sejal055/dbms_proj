import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryColor = Color(0xFF7BAFFC);
const Color secondaryColor = Color(0xFFD6A8FF);
const Color unreadCountColor = secondaryColor; 
const Color deliveredColor = Colors.grey;
const Color readColor = secondaryColor;
const Color iconWhite = Colors.white;

const Map<String, String> dummyUsers = {
  'oluvatobi_sam': 'https://i.pravatar.cc/150?img=1',
  'sarah_rollins': 'https://i.pravatar.cc/150?img=2',
  'malcom_eddie': 'https://i.pravatar.cc/150?img=3',
  'zoey_dev': 'https://i.pravatar.cc/150?img=4',
  'jamie_dev': 'https://i.pravatar.cc/150?img=5',
  'helen_k': 'https://i.pravatar.cc/150?img=6',
  'steve_j': 'https://i.pravatar.cc/150?img=7',
};

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isAuthReady = false;
  int _selectedTabIndex = 0;

  List<Contact> _deviceContacts = [];
  List<Map<String, dynamic>> _matchedUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _syncDeviceContacts();
  }

  Future<void> _initializeAuth() async {
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

  Future<List<Contact>> _loadContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) return [];
    return await FlutterContacts.getContacts(withProperties: true);
  }

  String normalizePhoneNumber(String phone) {
    String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (normalized.startsWith('0')) normalized = normalized.substring(1);
    if (!normalized.startsWith('91')) normalized = '91$normalized';
    return '+$normalized';
  }

  Future<void> _syncDeviceContacts() async {
    final contacts = await _loadContacts();
    setState(() {
      _deviceContacts = contacts;
    });

    final phones = <String>[];
    for (var c in contacts) {
      for (var p in c.phones) {
        phones.add(normalizePhoneNumber(p.number));
      }
    }

    if (phones.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batchSize = 10;
    final matchedUsersTemp = <Map<String, dynamic>>[];

    for (int i = 0; i < phones.length; i += batchSize) {
      final batchPhones = phones.sublist(
          i, (i + batchSize) > phones.length ? phones.length : i + batchSize);
      final querySnapshot = await firestore
          .collection('users')
          .where('phone', whereIn: batchPhones)
          .get();
      matchedUsersTemp.addAll(querySnapshot.docs.map((d) => d.data()));
    }

    setState(() {
      _matchedUsers = matchedUsersTemp;
    });

    // Now you have _matchedUsers ready to show in your UI or use for chat/groups
  }

  Widget _buildTopTabs() {
    const tabNames = ['Chats', 'Group', 'Overall'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0x0D000000), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(tabNames.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(tabNames[index], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? primaryColor : Colors.grey[600])),
                  const SizedBox(height: 6),
                  Container(height: 3, width: 40, decoration: BoxDecoration(color: isSelected ? primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(3))),
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
    if (!_isAuthReady) return const Center(child: CircularProgressIndicator(color: primaryColor));

    final content = _selectedTabIndex == 0 ? _matchedUsers : [];

    // Show placeholder if no matched users found
    if (content.isEmpty) {
      return const Center(child: Text('No contacts found in app.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final user = content[index];
        final userName = user['name'] ?? 'Unknown';
        final userId = user['userId'] ?? user['id'] ?? 'unknown_id';
        final lastMessage = user['lastMessage'] ?? 'Tap to chat';
        final isUnread = user['unread'] ?? false;

        return ChatTile(
          data: ChatTileData(
            name: userName,
            message: lastMessage,
            time: DateTime.now(), // You can store last message time in Firestore for real use
            status: MessageStatus.delivered,
            isUnread: isUnread,
            unreadCount: 0,
            userId: userId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x1AD6A8FF),
      body: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xE67BAFFC), const Color(0xE6D6A8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildTopTabs(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                    ),
                    child: _buildChatList(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 25,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => print("Add people to chat"),
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: iconWhite, size: 26)),
        const Text('Chats', style: TextStyle(color: iconWhite, fontSize: 22, fontWeight: FontWeight.bold)),
        Row(children: const [Icon(Icons.search, color: iconWhite, size: 26), SizedBox(width: 15), Icon(Icons.menu, color: iconWhite, size: 26)]),
      ]),
    );
  }
}

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
              backgroundColor: const Color(0x1A7BAFFC),
              backgroundImage:
                  NetworkImage(dummyUsers[data.userId] ?? dummyUsers['zoey_dev']!),
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
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                  ),
                  child: Text(
                    '${data.unreadCount}',
                    style:
                        const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          data.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Text(
          data.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: data.isUnread ? Colors.black : Colors.grey[600],
              fontWeight: data.isUnread ? FontWeight.w500 : FontWeight.normal),
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
                  fontWeight: data.isUnread ? FontWeight.bold : FontWeight.normal),
            ),
            const SizedBox(height: 4),
            if (data.status != MessageStatus.justNow)
              Icon(
                data.status == MessageStatus.read ? Icons.done_all : Icons.done,
                size: 16,
                color: data.status == MessageStatus.read ? readColor : deliveredColor,
              ),
          ],
        ),
      ),
    );
  }
}
