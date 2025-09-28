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

import 'package:flutter/material.dart';
import 'models/expense.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  final List<Expense> expenses;

  HistoryPage({required this.expenses});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Filter based on search query
    List<Expense> filteredExpenses = widget.expenses.where((expense) {
      return expense.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Group by Month-Year
    Map<String, List<Expense>> groupedExpenses = {};
    for (var expense in filteredExpenses) {
      String month = DateFormat('MMMM yyyy').format(expense.date);
      if (!groupedExpenses.containsKey(month)) {
        groupedExpenses[month] = [];
      }
      groupedExpenses[month]!.add(expense);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search transactions',
                prefixIcon: Icon(Icons.arrow_back),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🔘 Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip("Date"),
                _buildFilterChip("Amount"),
                _buildFilterChip("Category"),
                _buildFilterChip("Payment Method"),
              ],
            ),
          ),

          SizedBox(height: 10),

          // 📅 Monthly Grouped Transactions
          Expanded(
            child: groupedExpenses.isEmpty
                ? Center(child: Text('No expenses found.'))
                : ListView(
                    children: groupedExpenses.entries.map((entry) {
                      final month = entry.key;
                      final expenses = entry.value;
                      double total = expenses.fold(
                          0.0, (sum, item) => sum + item.amount);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month Header
                          Container(
                            color: Colors.grey[200],
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(month,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 19,letterSpacing: 2)),
                                Text("Rs. ${total.toStringAsFixed(0)}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 20)),
                              ],
                            ),
                          ),

                          // List of expenses
                          ...expenses.map((expense) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple[100], // Add your asset
                                ),
                                title: Text(expense.name),
                                subtitle: Text(
                                    DateFormat('dd MMMM').format(expense.date)),
                                trailing: Text(
                                  'Rs. ${expense.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: expense.amount >= 0
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        backgroundColor: Colors.lightBlue,
        label: Text(label, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
