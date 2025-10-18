// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_expense_page.dart';
import 'profile_page.dart';
import 'history.dart';
import 'stats_page.dart' as stats;
import 'notification_page.dart';
import 'chat/chat_page.dart';
import 'category_page.dart';
import 'category_detail_page.dart'; // ✅ Added import

List<Map<String, dynamic>> notifications = []; //low budget notifications

final urgentPayments = [
  {'title': 'Library Fine', 'due': 'Due in 2 days', 'amount': '₹250', 'status': 'Overdue'},
  {'title': 'Mess Fee', 'due': 'Due in 5 days', 'amount': '₹3100', 'status': 'Upcoming'},
];

final categories = [
  {'title': 'Food & Dining', 'icon': Icons.restaurant, 'color': Color(0xFFFDF5E6)},
  {'title': 'Transportation', 'icon': Icons.directions_bus, 'color': Color(0xFFEAF6FA)},
  {'title': 'Education', 'icon': Icons.school, 'color': Color(0xFFF3EDF9)},
  {'title': 'Entertainment', 'icon': Icons.movie, 'color': Color(0xFFF7E6ED)},
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = 'User';
  double totalIncome = 0;
  double totalExpense = 0;
  double monthlyBudget = 15000;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadTotals();
    _loadNotifications();  
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? 'User';
        });
      }
    }
  }

//For loading notifications
  Future<void> _loadNotifications() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .get();

  setState(() {
    notifications = snapshot.docs.map((doc) => doc.data()).toList();
  });
}

  // ✅ Fetch all transactions and calculate totals
  Future<void> _loadTotals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .get();

    double income = 0;
    double expense = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['expense_amount'] ?? 0).toDouble();
      final type = data['expense_type'] ?? '';

      if (type == 'Income') {
        income += amount;
      } else if (type == 'Expense') {
        expense += amount;
      }
    }

    if (mounted) {
      setState(() {
        totalIncome = income;
        totalExpense = expense;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double amountLeft = totalIncome - totalExpense;
    double usedPercent = (totalExpense / monthlyBudget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE3F0FF), Color(0xFFF8EFFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Name + Profile + Notification)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, $userName! 👋',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ready to track your expenses today?',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    // Notification Icon
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 26),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationPage()),
                        );
                      },
                    ),
                    const SizedBox(width: 5),
                    // Profile Avatar
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfilePage()));
                      },
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage("https://i.pravatar.cc/60"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Finance News Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.article_outlined, color: Color(0xFF0077B6), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Finance News: RBI launches new digital currency policy to boost cashless transactions!',
                          style: TextStyle(
                            color: Color(0xFF005678),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // ✅ Dynamic Budget Summary
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Expanded(child: Text("Amount Left", style: TextStyle(fontWeight: FontWeight.w500))),
                          Text("Monthly Budget", style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "₹${amountLeft.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          Text(
                            "₹${monthlyBudget.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: usedPercent,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: const Color(0xFF7BAFFC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${(usedPercent * 100).toStringAsFixed(1)}% of budget used",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Categories and Urgent Payments
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 12),
                // ✅ Categories Header with View All button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CategoriesPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF7BAFFC),
                        ),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 15,
                    runSpacing: 14,
                    children: categories.map((cat) {
                      return GestureDetector(
                        onTap: () {
                          // ✅ Opens Category Detail Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailPage(category: cat['title'] as String),
                            ),
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2.3,
                          padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 14),
                          decoration: BoxDecoration(
                            color: cat['color'] as Color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(cat['icon'] as IconData, size: 26, color: Colors.black87),
                              const SizedBox(width: 13),
                              Expanded(child: Text(cat['title'] as String, style: const TextStyle(fontSize: 15))),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Text('Urgent Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 8),
                ...urgentPayments.map(
                  (item) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E5),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                              const SizedBox(height: 5),
                              Text(item['due']!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(item['amount']!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            Text(item['status']!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 55),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7BAFFC),
        onPressed: () {},
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.home_rounded, color: Color(0xFF7BAFFC)),
                Text('Home', style: TextStyle(fontSize: 11, color: Color(0xFF7BAFFC))),
              ]),
              // History
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, color: Colors.grey),
                    Text('History', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              // Add Expense Button
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8A5FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFB8A5FF).withOpacity(0.22), blurRadius: 8),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddExpensePopup(onCancel: () => Navigator.of(context).pop()),
                    );
                  },
                ),
              ),
              // Stats
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => stats.AnalysisScreen()));
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, color: Colors.grey[600]),
                    Text('Stats', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
              // Chat
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListScreen()));
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_rounded, color: Colors.grey[600]),
                    Text('Chat', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
