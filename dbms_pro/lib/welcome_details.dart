import 'package:flutter/material.dart';

void main() {
  runApp(BudgetBuddyApp());
}

class BudgetBuddyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BudgetBuddyPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BudgetBuddyPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove backgroundColor and use Container for gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F0FF), Color(0xFFF8EFFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular Icon
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFB3BFFA), Color(0xFFD8CFFD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.all(18),
                child: Icon(Icons.account_balance_wallet_rounded, size: 40, color: Colors.white),
              ),
              SizedBox(height: 20),
              // Title & Subtitle
              Text(
                'Welcome to Budget Buddy!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Let's make budgeting simple and fun.",
                style: TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              // Form Card
              Container(
                width: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  children: [
                    // Name field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("What's your name?"),
                    ),
                    SizedBox(height: 7),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        filled: true,
                        fillColor: Color(0xFFF6F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    // Amount field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Amount in Account (Rs.)'),
                    ),
                    SizedBox(height: 7),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        filled: true,
                        fillColor: Color(0xFFF6F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    // Monthly Budget field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Monthly Budget (Rs.)'),
                    ),
                    SizedBox(height: 7),
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        filled: true,
                        fillColor: Color(0xFFF6F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Button with gradient background using a container wrapper
              SizedBox(
                width: 290,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
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
                    onPressed: () {
                      // Add navigation/action as desired
                    },
                    child: Text('Let\'s go!', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
              SizedBox(height: 18),
              // Made in Bot label at bottom right
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text(
                    'Made in Bot',
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
