import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_chat_page.dart';

// --- COLORS ---
const Color primaryColor = Color(0xFFD0E3FF);
const Color secondaryColor = Color(0xFFE9D5F8);
const Color incomeColor = Color(0xFF5A96F0);
const Color expenseColor = Color(0xFFB47BE8);
const Color progressFill = Color(0xFF5A96F0);

class AiIntroInfoPage extends StatelessWidget {
  const AiIntroInfoPage({super.key});

  Future<void> _completeIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_intro_shown', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AiChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Logo/Icon ---
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      size: 60,
                      color: progressFill,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- Title ---
                const Text(
                  "Your AI Financial Advisor",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: incomeColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // --- Description ---
                const Text(
                  "Hi! I’m your personal AI assistant — trained to help you understand your spending, analyze your budgets, and answer any financial questions about your monthly progress.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 50),

                // --- Continue Button ---
                ElevatedButton(
                  onPressed: () => _completeIntro(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: incomeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
