import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_page.dart'; // adjust path if needed

class WelcomeDetailsPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  WelcomeDetailsPage({super.key});

  Future<void> _saveDetailsAndNavigate(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': nameController.text.trim(),
          'amount_in_account': int.tryParse(amountController.text.trim()) ?? 0,
          'monthly_budget': int.tryParse(budgetController.text.trim()) ?? 0,
        }, SetOptions(merge: true)); // create or update document

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in. Please sign in again.')),
        );
      }
    } catch (e) {
      print('Error saving user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F0FF), Color(0xFFF8EFFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFB3BFFA), Color(0xFFD8CFFD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: const Icon(Icons.account_balance_wallet_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to Budget Buddy!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Let's make budgeting simple and fun.",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: Text("What's your name?")),
                      const SizedBox(height: 7),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          filled: true,
                          fillColor: const Color(0xFFF6F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Align(alignment: Alignment.centerLeft, child: Text('Amount in Account (Rs.)')),
                      const SizedBox(height: 7),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: const Color(0xFFF6F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Align(alignment: Alignment.centerLeft, child: Text('Monthly Budget (Rs.)')),
                      const SizedBox(height: 7),
                      TextField(
                        controller: budgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: const Color(0xFFF6F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 290,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7BAFFC), Color(0xFFD6A8F8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                      onPressed: () => _saveDetailsAndNavigate(context),
                      child: const Text('Let\'s go!', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text('Made in Bot', style: TextStyle(fontSize: 11, color: Colors.black38)),
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
