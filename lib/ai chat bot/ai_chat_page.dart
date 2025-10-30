import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../home_page.dart'; 
// Use a relative path import for your home_page.dart.

// --- COLORS ---
const Color primaryColor = Color(0xFFD0E3FF);
const Color secondaryColor = Color(0xFFE9D5F8);
const Color incomeColor = Color(0xFF5A96F0);
const Color expenseColor = Color(0xFFB47BE8);

// --- GEMINI API CONFIG (Securely loaded via Dart Define) ---
// The key is retrieved from the '--dart-define=GEMINI_API_KEY="..."' argument
const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const String geminiModel = "gemini-2.5-flash"; // Fast and capable model for chat
// The key is integrated directly into the URL query parameters
const String geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiApiKey";

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  // We will store the conversation history to maintain context
  final List<Map<String, String>> _messages = [
    {"role": "ai", "text": "Hello 👋 I'm your **AI Financial Assistant**!"},
    {"role": "ai", "text": "Ask me anything about your budget or spending."},
  ];

  bool _isTyping = false;

  // --- SEND MESSAGE + AI RESPONSE ---
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Security Check: Ensure the API key was loaded from the environment
    if (geminiApiKey.isEmpty) {
      setState(() {
        _messages.add({"role": "ai", "text": "⚠️ **Error:** The API key is missing. Please run the app using the 'Secure Gemini Chat App' configuration in VS Code, or use the '--dart-define' flag."});
      });
      return;
    }

    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
      _isTyping = true;
    });

    try {
      final aiResponse = await _getAiResponse();
      setState(() {
        _messages.add({"role": "ai", "text": aiResponse});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": "❌ An unexpected error occurred: $e"});
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  // --- CALL GEMINI API ---
  Future<String> _getAiResponse() async {
    // 1. CONSTRUCT THE CONVERSATION HISTORY FOR GEMINI
    List<Map<String, dynamic>> contents = [];

    // Convert application-specific messages into Gemini-compatible format
    // Start from the beginning of the chat history (index 0)
    for (var msg in _messages) {
      // Only include user and model messages in the history
      if (msg['role'] == "user" || msg['role'] == "ai") {
        contents.add({
          "role": msg["role"] == "user" ? "user" : "model",
          "parts": [
            {"text": msg["text"]},
          ],
        });
      }
    }
    
    // 2. Define the System Instruction / Persona
    const systemInstruction = "You are a friendly financial assistant. Give concise and useful advice about budgeting, spending, and saving. Your responses should be helpful, encouraging, and easy to understand. Keep your replies under 100 words.";

    try {
      final response = await http.post(
        Uri.parse(geminiUrl), // Uses the URL with the securely loaded API key
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": contents, // Send the full conversation context
          "config": { // Use the config field to define the persona
            "systemInstruction": systemInstruction,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Safely extract the text response from the nested JSON structure
        // Added a check for 'candidates' being present
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          String responseText = data['candidates'][0]['content']['parts'][0]['text'] ?? "AI response was empty.";
          return responseText;
        } else {
          // Handle cases where the API call is successful but returns no content
          return "AI couldn't generate a response. This might happen with complex or disallowed prompts.";
        }
      } else {
        // Return a detailed error message for troubleshooting
        // Includes the body to help diagnose API errors (e.g., key invalid)
        return "⚠️ Sorry, I couldn’t connect. Status: ${response.statusCode}. Response: ${response.body}. Check API key.";
      }
    } catch (e) {
      return "❌ Network or Parsing Error: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- Use a Builder to get a context for scrolling to the end
      body: Builder(
        builder: (context) {
          // Find the ScrollController associated with the ListView, if needed.
          // For a simple reverse ListView, the framework often handles it, but
          // a ScrollController gives explicit control if necessary.
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // --- CURVED HEADER ---
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // --- Back Button ---
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: expenseColor),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomePage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.smart_toy_rounded,
                            size: 30, color: incomeColor),
                        const SizedBox(width: 10),
                        const Text(
                          "AI Financial Assistant",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: incomeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- CHAT AREA ---
                  Expanded(
                    child: ListView.builder(
                      // Scroll to the latest message whenever a new message is added
                      // Ensure the newest messages are visible first (bottom up)
                      reverse: true,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        final messageIndex = _messages.length - 1 - index;
                        
                        if (_isTyping && index == 0) { // Show "typing" indicator at the bottom
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                "AI is typing...",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        if (messageIndex < 0) return const SizedBox.shrink(); 

                        final msg = _messages[messageIndex];
                        final isUser = msg["role"] == "user";

                        return Align(
                          alignment:
                              isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                // Bubble tail styling
                                bottomLeft: Radius.circular(isUser ? 16 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 16),
                              ),
                              boxShadow: [
                                const BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              msg["text"]!,
                              style: TextStyle(
                                fontSize: 15.5,
                                color: isUser ? expenseColor : incomeColor,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // --- MESSAGE INPUT AREA ---
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(230, 255, 255, 255),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // TODO: Add image/file picker later (multimodality)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              color: expenseColor, size: 28),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Type your message...",
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: incomeColor, size: 26),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}