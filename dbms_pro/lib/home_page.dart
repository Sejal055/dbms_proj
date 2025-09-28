import 'package:flutter/material.dart';
import 'add_expense_page.dart'; // Adjust path accordingly

// Dummy data for demonstration
final urgentPayments = [
  {
    'title': 'Library Fine',
    'due': 'Due in 2 days',
    'amount': '₹250',
    'status': 'Overdue',
  },
  {
    'title': 'Mess Fee',
    'due': 'Due in 5 days',
    'amount': '₹3100',
    'status': 'Upcoming',
  },
];

final categories = [
  {
    'title': 'Food & Dining',
    'icon': Icons.restaurant,
    'color': Color(0xFFFDF5E6),
  },
  {
    'title': 'Transportation',
    'icon': Icons.directions_bus,
    'color': Color(0xFFEAF6FA),
  },
  {'title': 'Education', 'icon': Icons.school, 'color': Color(0xFFF3EDF9)},
  {'title': 'Entertainment', 'icon': Icons.movie, 'color': Color(0xFFF7E6ED)},
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Top greeting section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE3F0FF), Color(0xFFF8EFFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, Alex! 👋',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ready to track your expenses today?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/60"),
                    ), // Avatar
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0DE),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Color(0xFFFFA447), size: 17),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Tip: Try to save 20% of your monthly budget for emergencies!',
                          style: TextStyle(
                            color: Color(0xFF7D5A29),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Amount Left",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            "Monthly Budget",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "₹11,970",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          Text(
                            "₹15,000",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: 0.202,
                        minHeight: 8,
                        backgroundColor: Color(0xFFE5E7EB),
                        color: Color(0xFF7BAFFC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "20.2% of budget used",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Categories Section
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 15,
                    runSpacing: 14,
                    children: categories
                        .map(
                          (cat) => Container(
                            width: MediaQuery.of(context).size.width / 2.3,
                            padding: EdgeInsets.symmetric(
                              vertical: 19,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: cat['color'] as Color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  cat['icon'] as IconData,
                                  size: 26,
                                  color: Colors.black87,
                                ),
                                SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    cat['title'] as String,
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                SizedBox(height: 18),
                // Urgent Payments Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'Urgent Payments',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                SizedBox(height: 8),
                ...urgentPayments.map(
                  (item) => Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
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
                              Text(
                                item['title']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                item['due']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item['amount']!,
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item['status']!,
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 55),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, color: Color(0xFF7BAFFC)),
                  Text(
                    'Home',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7BAFFC)),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, color: Colors.grey[600]),
                  Text(
                    'History',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
             Container(
  margin: const EdgeInsets.only(bottom: 8),
  decoration: BoxDecoration(
    color: Color(0xFFB8A5FF),
    shape: BoxShape.circle,
    boxShadow: [BoxShadow(color: Color(0xFFB8A5FF).withOpacity(0.22), blurRadius: 8)],
  ),
  child: IconButton(
    icon: Icon(Icons.add, color: Colors.white),
    onPressed: () {
      showDialog(
        context: context,
        builder: (context) {
          return AddExpensePopup(
            onCancel: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
    },
  ),
),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded, color: Colors.grey[600]),
                  Text(
                    'Stats',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_rounded, color: Colors.grey[600]),
                  Text(
                    'Menu',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
