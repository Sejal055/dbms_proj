// import 'package:flutter/material.dart';
// import 'add_expense_page.dart';
// import 'models/expense.dart';


// class HistoryPage extends StatelessWidget {
//   final List<Expense> expenses;

//   HistoryPage({required this.expenses});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Expense History'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: Colors.white,
//       body: expenses.isEmpty
//           ? Center(child: Text('No expenses added yet.'))
//           : ListView.builder(
//               itemCount: expenses.length,
//               itemBuilder: (context, index) {
//                 final expense = expenses[index];
//                 return Card(
//                   color: Colors.white,
//                   shadowColor: const Color.fromARGB(255, 211, 210, 210),
//                   surfaceTintColor: Colors.lightBlue,
//                   elevation: 2,
//                   child: ListTile(
//                     title: Text(expense.name),
//                     subtitle: Text(
//                       '${expense.category} - ${expense.date.toLocal().toString().split(" ")[0]}',
//                     ),
//                     trailing: Text('₹${expense.amount.toStringAsFixed(2)}'),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'models/expense.dart';
// import 'package:intl/intl.dart';

// class HistoryPage extends StatefulWidget {
//   final List<Expense> expenses;

//   HistoryPage({required this.expenses});

//   @override
//   _HistoryPageState createState() => _HistoryPageState();
// }

// class _HistoryPageState extends State<HistoryPage> {
//   String _searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     // Filtered expenses based on search query
//     List<Expense> filteredExpenses = widget.expenses.where((expense) {
//       return expense.name.toLowerCase().contains(_searchQuery.toLowerCase());
//     }).toList();

//     // Calculate total spending for the current month
//     DateTime now = DateTime.now();
//     double totalSpending = widget.expenses
//         .where((expense) =>
//             expense.date.year == now.year && expense.date.month == now.month)
//         .fold(0.0, (sum, item) => sum + item.amount);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Expense History'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // 🔍 Search Bar
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value;
//                 });
//               },
//               decoration: InputDecoration(
//                 hintText: 'Search expenses...',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//               ),
//             ),
//           ),

//           // 💰 Total Spending Bar
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.lightBlue[50],
//                 borderRadius: BorderRadius.circular(5),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Total Spent (${DateFormat('MMMM yyyy').format(now)}):',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   Text(
//                     '₹${totalSpending.toStringAsFixed(2)}',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.orange,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // 📋 Expenses List
//           Expanded(
//             child: filteredExpenses.isEmpty
//                 ? Center(child: Text('No expenses found.'))
//                 : ListView.builder(
//                     itemCount: filteredExpenses.length,
//                     itemBuilder: (context, index) {
//                       final expense = filteredExpenses[index];
//                       return Card(
//                         color: Colors.white,
//                         shadowColor:
//                             const Color.fromARGB(255, 211, 210, 210),
//                         surfaceTintColor: Colors.lightBlue,
//                         elevation: 2,
//                         margin: EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 6),
//                         child: ListTile(
//                           title: Text(expense.name),
//                           subtitle: Text(
//                             '${expense.category} - ${expense.date.toLocal().toString().split(" ")[0]}',
//                           ),
//                           trailing: Text(
//                             '₹${expense.amount.toStringAsFixed(2)}',
//                             style: TextStyle(fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'models/expense.dart';
// import 'package:intl/intl.dart';

// class HistoryPage extends StatefulWidget {
//   final List<Expense> expenses;

//   HistoryPage({required this.expenses});

//   @override
//   _HistoryPageState createState() => _HistoryPageState();
// }

// class _HistoryPageState extends State<HistoryPage> {
//   String _searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     // Filter based on search query
//     List<Expense> filteredExpenses = widget.expenses.where((expense) {
//       return expense.name.toLowerCase().contains(_searchQuery.toLowerCase());
//     }).toList();

//     // Group by Month-Year
//     Map<String, List<Expense>> groupedExpenses = {};
//     for (var expense in filteredExpenses) {
//       String month = DateFormat('MMMM yyyy').format(expense.date);
//       if (!groupedExpenses.containsKey(month)) {
//         groupedExpenses[month] = [];
//       }
//       groupedExpenses[month]!.add(expense);
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('History', style: TextStyle(color: Colors.black)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.black),
//       ),
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // 🔍 Search Bar
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: TextField(
//               onChanged: (value) {
//                 setState(() {
//                   _searchQuery = value;
//                 });
//               },
//               decoration: InputDecoration(
//                 hintText: 'Search transactions',
//                 prefixIcon: Icon(Icons.arrow_back),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 contentPadding: EdgeInsets.symmetric(vertical: 0),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(25),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ),

//           // 🔘 Filter Chips
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 _buildFilterChip("Date"),
//                 _buildFilterChip("Amount"),
//                 _buildFilterChip("Category"),
//                 _buildFilterChip("Payment Method"),
//               ],
//             ),
//           ),

//           SizedBox(height: 10),

//           // 📅 Monthly Grouped Transactions
//           Expanded(
//             child: groupedExpenses.isEmpty
//                 ? Center(child: Text('No expenses found.'))
//                 : ListView(
//                     children: groupedExpenses.entries.map((entry) {
//                       final month = entry.key;
//                       final expenses = entry.value;
//                       double total = expenses.fold(
//                           0.0, (sum, item) => sum + item.amount);
//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Month Header
//                           Container(
//                             color: Colors.grey[200],
//                             width: double.infinity,
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 8),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(month,
//                                     style: TextStyle(
//                                         fontWeight: FontWeight.bold, fontSize: 19,letterSpacing: 2)),
//                                 Text("Rs. ${total.toStringAsFixed(0)}",
//                                     style: TextStyle(
//                                         fontWeight: FontWeight.bold, fontSize: 20)),
//                               ],
//                             ),
//                           ),

//                           // List of expenses
//                           ...expenses.map((expense) => ListTile(
//                                 leading: CircleAvatar(
//                                   backgroundColor: Colors.purple[100], // Add your asset
//                                 ),
//                                 title: Text(expense.name),
//                                 subtitle: Text(
//                                     DateFormat('dd MMMM').format(expense.date)),
//                                 trailing: Text(
//                                   'Rs. ${expense.amount.toStringAsFixed(0)}',
//                                   style: TextStyle(
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.bold,
//                                     color: expense.amount >= 0
//                                         ? Colors.orange
//                                         : Colors.green,
//                                   ),
//                                 ),
//                               )),
//                         ],
//                       );
//                     }).toList(),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip(String label) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 8.0),
//       child: Chip(
//         backgroundColor: Colors.lightBlue,
//         label: Text(label, style: TextStyle(color: Colors.white)),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class HistoryPage extends StatelessWidget {
//   const HistoryPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       return const Scaffold(
//         body: Center(child: Text("Not logged in")),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Expense History'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .collection('expenses')
//             .orderBy('createdAtLocal', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             print('Firestore Error: ${snapshot.error}');
//             return const Center(child: Text('Error loading history'));
//           }

//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final docs = snapshot.data!.docs;

//           if (docs.isEmpty) {
//             return const Center(child: Text('No expenses recorded yet.'));
//           }

//           return ListView.separated(
//             itemCount: docs.length,
//             separatorBuilder: (_, __) => const Divider(height: 0),
//             itemBuilder: (context, index) {
//               final data = docs[index].data() as Map<String, dynamic>;
//               final name = data['expense_name'] ?? 'Unnamed';
//               final type = data['expense_type'] ?? 'Expense';
//               final category = data['category'] ?? 'Unknown';
//               final amount = data['expense_amount'] ?? 0;

//               return ListTile(
//                 leading: Icon(
//                   type == 'Income' ? Icons.arrow_downward : Icons.arrow_upward,
//                   color: type == 'Income' ? Colors.green : Colors.red,
//                 ),
//                 title: Text(name),
//                 subtitle: Text('$type • $category'),
//                 trailing: Text(
//                   '₹${amount.toStringAsFixed(2)}',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Text("You are not logged in."),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading expenses"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text("No expenses found"),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final name = doc['expense_name'] ?? '';
              final amount = doc['expense_amount'] ?? 0.0;
              final type = doc['expense_type'] ?? 'Expense';
              final category = doc['category'] ?? 'Others';
              final timestamp = doc['timestamp'] as Timestamp?;
              final dateTime = timestamp?.toDate();

              return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      type == 'Income' ? Icons.arrow_downward : Icons.arrow_upward,
                      color: type == 'Income' ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          if (dateTime != null)
                            Text(
                              "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      (type == 'Income' ? '+₹' : '-₹') + amount.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: type == 'Income' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

