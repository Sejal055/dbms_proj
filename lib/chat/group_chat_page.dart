import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'split_bill_popup.dart'; // Import the popup

class GroupChatPage extends StatefulWidget {
  final String groupName;
  final String groupImageUrl;

  const GroupChatPage({
    super.key,
    required this.groupName,
    required this.groupImageUrl,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hey everyone!',
      'isMe': false,
      'sender': 'Aditi',
      'time': DateTime.now().subtract(const Duration(minutes: 25))
    },
    {
      'text': 'Hi 👋 Ready for tomorrow’s trip?',
      'isMe': true,
      'sender': 'Me',
      'time': DateTime.now().subtract(const Duration(minutes: 20))
    },
    {
      'text': 'Almost! Need to finalize budget 😅',
      'isMe': false,
      'sender': 'Riya',
      'time': DateTime.now().subtract(const Duration(minutes: 12))
    },
  ];

  final List<Color> _gradientColors = const [
    Color(0xFFBEE6FF), // light blue
    Color(0xFFD6B8FF), // light purple
    Color(0xFFFFD6E8), // light pink
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'sender': 'Me',
        'time': DateTime.now(),
      });
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _openSplitBillPopup() {
    showDialog(
      context: context,
      // If you used the new class name
// Corrected line in lib/chat/group_chat_page.dart
builder: (_) => SplitBillPopup(),
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
                // App bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child:
                            const Icon(Icons.arrow_back, color: Colors.black),
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
                      IconButton(
                        icon: const Icon(Icons.receipt_long_outlined,
                            color: Colors.black),
                        onPressed: _openSplitBillPopup,
                        tooltip: 'Split Bill',
                      ),
                    ],
                  ),
                ),

                // Chat section
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
                      children: [
                        // Messages list
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _messages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Text(
                                        DateFormat('h:mm a')
                                            .format(DateTime.now()),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final msg = _messages[index - 1];
                                final isMe = msg['isMe'] as bool;
                                return _buildMessageBubble(
                                  msg['text'] as String,
                                  msg['time'] as DateTime,
                                  msg['sender'] as String,
                                  isMe,
                                  context,
                                );
                              },
                            ),
                          ),
                        ),
                        _buildMessageInput(),
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

  Widget _buildMessageBubble(String text, DateTime time, String sender,
      bool isMe, BuildContext context) {
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
          border: Border.all(color: Colors.black, width: 0.8),
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                sender,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 13,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 10),
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_none, size: 20),
          ),
          const SizedBox(width: 8),
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
}
