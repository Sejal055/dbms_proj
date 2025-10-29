import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dbms_pro/add_expense_page.dart'; // make sure this path is correct

class IndividualChatPage extends StatefulWidget {
  final String name;
  final String imageUrl;

  const IndividualChatPage({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Free tonight? 👀',
      'isMe': false,
      'time': DateTime.now().subtract(const Duration(minutes: 20))
    },
    {
      'text': 'Yeah, I think so!',
      'isMe': true,
      'time': DateTime.now().subtract(const Duration(minutes: 18))
    },
    {
      'text': 'What you wanna do?',
      'isMe': true,
      'time': DateTime.now().subtract(const Duration(minutes: 16))
    },
    {
      'text': 'Hmm.. movies?',
      'isMe': false,
      'time': DateTime.now().subtract(const Duration(minutes: 10))
    },
  ];

  // Gradient colors (light blue -> purple -> pink)
  final List<Color> _gradientColors = const [
    Color(0xFFBEE6FF),
    Color(0xFFD6B8FF),
    Color(0xFFFFD6E8),
  ];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    var permissionStatus = await Permission.contacts.status;
    if (!permissionStatus.isGranted) {
      permissionStatus = await Permission.contacts.request();
      if (!permissionStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission denied')),
          );
        }
        return;
      }
    }

    Iterable<Contact> contactsIterable =
        await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      contacts = contactsIterable.toList();
      filteredContacts = contacts;
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': DateTime.now(),
      });
    });

    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openAddExpensePopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddExpensePopup(
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
    setState(() {
      _messages.add({
        'text': 'Expense entry added for ${widget.name}.',
        'isMe': true,
        'time': DateTime.now(),
        'isMeta': true,
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _openSendReminderDialog() async {
    final TextEditingController reminderController =
        TextEditingController(text: 'Reminder: Please pay back / check this.');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Reminder'),
          content: TextField(
            controller: reminderController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Type reminder message...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = reminderController.text.trim();
                if (text.isEmpty) return;
                setState(() {
                  _messages.add({
                    'text': 'Reminder to ${widget.name}: $text',
                    'isMe': true,
                    'time': DateTime.now(),
                    'isReminder': true,
                  });
                });
                Navigator.of(context).pop();
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder sent')),
                );
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(
      String text, DateTime time, bool isMe, BuildContext context,
      {Map<String, dynamic>? meta}) {
    final List<Color> bubbleGradient = isMe
        ? [
            const Color(0xFFDFF8FF),
            const Color(0xFFEBDCFF),
            const Color(0xFFFFEAF2),
          ]
        : [
            const Color(0xFFF3FBFF),
            const Color(0xFFF8EEFF),
            const Color(0xFFFFF0F6),
          ];

    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
    );

    final bool isReminder = meta?['isReminder'] == true;
    final bool isMeta = meta?['isMeta'] == true;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bubbleGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isReminder
                ? Colors.orange.shade700
                : (isMeta ? Colors.green.shade700 : Colors.black26),
            width: isReminder || isMeta ? 1.2 : 0.8,
          ),
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: isReminder ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('h:mm a').format(time),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _openAddExpensePopup,
            icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Message...',
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _openSendReminderDialog,
            icon: const Icon(Icons.alarm, color: Colors.orange),
          ),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Missing build() method added here
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.imageUrl),
            ),
            const SizedBox(width: 10),
            Text(widget.name),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(
                    msg['text'],
                    msg['time'],
                    msg['isMe'],
                    context,
                    meta: msg,
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
}
