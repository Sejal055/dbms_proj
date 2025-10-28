// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:rxdart/rxdart.dart'; // ✅ for CombineLatestStream

// class HistoryPage extends StatefulWidget {
//   const HistoryPage({super.key});

//   @override
//   _HistoryPageState createState() => _HistoryPageState();
// }

// class _HistoryPageState extends State<HistoryPage> {
//   final user = FirebaseAuth.instance.currentUser;

//   double totalAmountInAccount = 0;
//   double monthlyBudget = 0;
//   double totalIncome = 0;
//   double totalExpense = 0;

//   bool _userDataLoaded = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }

//   Future<void> _fetchUserData() async {
//     if (user == null) return;
//     final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
//     if (doc.exists) {
//       setState(() {
//         final data = doc.data();
//         totalAmountInAccount = (data?['amount_in_account'] ?? 0).toDouble();
//         monthlyBudget = (data?['monthly_budget'] ?? 0).toDouble();
//         _userDataLoaded = true;
//       });
//     } else {
//       setState(() {
//         _userDataLoaded = true;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color gradientStart = Color(0xFFE3F0FF);
//     const Color gradientEnd = Color(0xFFF8EFFB);
//     const Color primaryBlue = Color(0xFF7BAFFC);
//     const Color accentPurple = Color(0xFFD6A8FF);

//     return Scaffold(
//       backgroundColor: gradientEnd,
//       body: Column(
//         children: [
//           _buildTopSection(context, primaryBlue, accentPurple),
//           Expanded(child: _buildTransactionList()),
//           const SizedBox(height: 10),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopSection(BuildContext context, Color primaryBlue, Color accentPurple) {
//     return Container(
//       padding: EdgeInsets.only(
//         top: MediaQuery.of(context).padding.top,
//         bottom: 20,
//       ),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [primaryBlue.withAlpha(230), accentPurple.withAlpha(204)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Column(
//         children: [
//           _buildAppBar(),
//           const SizedBox(height: 10),
//           _buildTotalBalanceCard(primaryBlue),
//           const SizedBox(height: 20),
//           _buildSummaryBar(primaryBlue),
//           const SizedBox(height: 10),
//           _buildExpenseProgress(primaryBlue),
//         ],
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const Text(
//             'History',
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//           IconButton(
//             icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
//             onPressed: () {},
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTotalBalanceCard(Color color) {
//     double displayedBalance = totalAmountInAccount + totalIncome - totalExpense;
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20),
//       padding: const EdgeInsets.symmetric(vertical: 15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(color: color.withAlpha(51), blurRadius: 10, offset: const Offset(0, 5)),
//         ],
//       ),
//       child: Center(
//         child: Column(
//           children: [
//             Text('Total Balance',
//                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
//             const SizedBox(height: 5),
//             Text('₹${displayedBalance.toStringAsFixed(2)}',
//                 style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryBar(Color color) {
//     double displayedBalance = totalAmountInAccount + totalIncome - totalExpense;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.white),
//                 const SizedBox(width: 5),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Total Balance', style: TextStyle(fontSize: 12, color: Colors.white)),
//                     const SizedBox(height: 2),
//                     Text('₹${displayedBalance.toStringAsFixed(2)}',
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Container(height: 40, width: 1, color: const Color.fromARGB(128, 255, 255, 255)),
//           Expanded(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 const Icon(Icons.monetization_on_outlined, size: 20, color: Colors.white),
//                 const SizedBox(width: 5),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Total Expense', style: TextStyle(fontSize: 12, color: Colors.white)),
//                     const SizedBox(height: 2),
//                     Text('-₹${totalExpense.toStringAsFixed(2)}',
//                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEE6C6C))),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildExpenseProgress(Color color) {
//     double usedPercentage = monthlyBudget == 0
//         ? 0
//         : (totalExpense / monthlyBudget).clamp(0, 1).toDouble();
//     int percent = (usedPercentage * 100).toInt();

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(10),
//                   child: LinearProgressIndicator(
//                     value: usedPercentage,
//                     backgroundColor: const Color.fromARGB(77, 255, 255, 255),
//                     valueColor: AlwaysStoppedAnimation<Color>(color),
//                     minHeight: 10,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Text('₹${monthlyBudget.toStringAsFixed(0)}',
//                   style: const TextStyle(color: Colors.white, fontSize: 14)),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('$percent%',
//                   style: const TextStyle(
//                       color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
//               Text('$percent% of your budget used',
//                   style: const TextStyle(color: Colors.white, fontSize: 14)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionList() {
//     if (user == null) return const Center(child: Text("No user found"));

//     final expensesStream = FirebaseFirestore.instance
//         .collection('users')
//         .doc(user!.uid)
//         .collection('expenses')
//         .orderBy('timestamp', descending: true)
//         .snapshots();

//     final historyStream = FirebaseFirestore.instance
//         .collection('users')
//         .doc(user!.uid)
//         .collection('history')
//         .orderBy('paid_on', descending: true)
//         .snapshots();

//     final combined = CombineLatestStream.list<QuerySnapshot>([
//       expensesStream,
//       historyStream,
//     ]);

//     return StreamBuilder<List<QuerySnapshot>>(
//       stream: combined,
//       builder: (context, snapshot) {
//         if (!_userDataLoaded) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(
//             child: Text("No history yet",
//                 style: TextStyle(color: Colors.black54, fontSize: 16)),
//           );
//         }

//         // ✅ Merge & deduplicate by title + amount
//         final seen = <String>{};
//         final allDocs = <QueryDocumentSnapshot>[];
//         for (var snap in snapshot.data!) {
//           for (var doc in snap.docs) {
//             final data = doc.data() as Map<String, dynamic>;
//             final key = "${data['title'] ?? data['expense_name'] ?? ''}_${data['amount'] ?? data['expense_amount'] ?? 0}";
//             if (!seen.contains(key)) {
//               seen.add(key);
//               allDocs.add(doc);
//             }
//           }
//         }

//         if (allDocs.isEmpty) {
//           return const Center(child: Text("No transactions yet"));
//         }

//         totalIncome = 0;
//         totalExpense = 0;

//         final List<TransactionItem> transactions = allDocs.map((expense) {
//           final data = expense.data() as Map<String, dynamic>;

//           final String name =
//               (data['title'] ?? data['expense_name'] ?? data['name'] ?? '').toString();
//           final String category = (data['category'] ?? '').toString();

//           DateTime? dateTime;
//           if (data['timestamp'] is Timestamp) {
//             dateTime = (data['timestamp'] as Timestamp).toDate();
//           } else if (data['paid_on'] is Timestamp) {
//             dateTime = (data['paid_on'] as Timestamp).toDate();
//           }

//           final String date =
//               dateTime != null ? DateFormat('MMMM dd').format(dateTime) : '';
//           final String time =
//               dateTime != null ? DateFormat('HH:mm').format(dateTime) : '';

//           final String type = (data['type'] ??
//                   data['expense_type'] ??
//                   (data['type'] == 'Pay' ? 'Expense' : 'Income'))
//               .toString();

//           final num rawAmount =
//               (data['amount'] ?? data['expense_amount'] ?? 0);
//           final double amount = (rawAmount is num) ? rawAmount.toDouble() : 0.0;

//           if (type == 'Income' || type == 'Receive') {
//             totalIncome += amount;
//           } else {
//             totalExpense += amount;
//           }

//           return TransactionItem(
//             icon: (type == 'Income' || type == 'Receive')
//                 ? Icons.account_balance_wallet
//                 : Icons.money_outlined,
//             name: name,
//             time: time,
//             date: date,
//             category: category,
//             amount: amount,
//             isExpense: !(type == 'Income' || type == 'Receive'),
//           );
//         }).toList();

//         final grouped = groupTransactionsByMonth(transactions);
//         final months = grouped.keys.toList();

//         return ListView.builder(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           itemCount: months.length,
//           itemBuilder: (context, monthIndex) {
//             final month = months[monthIndex];
//             final monthTransactions = grouped[month]!;

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(top: 20, bottom: 10),
//                   child: Text(
//                     month,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF0F2C67),
//                     ),
//                   ),
//                 ),
//                 ...monthTransactions.map((tx) => _buildTransactionItem(tx)),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildTransactionItem(TransactionItem transaction) {
//     final Color iconBackgroundColor =
//         transaction.isExpense ? Colors.red.shade100 : Colors.green.shade100;
//     final Color iconColor =
//         transaction.isExpense ? Colors.red.shade600 : Colors.green.shade600;
//     final Color amountColor =
//         transaction.isExpense ? Colors.red.shade600 : Colors.green.shade600;

//     final String amountText = transaction.isExpense
//         ? '-₹${transaction.amount.toStringAsFixed(2)}'
//         : '₹${transaction.amount.toStringAsFixed(2)}';

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: IntrinsicHeight(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 color: iconBackgroundColor,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Icon(transaction.icon, color: iconColor, size: 24),
//             ),
//             const SizedBox(width: 15),
//             Expanded(
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(transaction.name,
//                             style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF0F2C67))),
//                         const SizedBox(height: 4),
//                         Text(
//                           '${transaction.time} - ${transaction.date}',
//                           style: TextStyle(
//                               fontSize: 13, color: Colors.grey.shade600),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(transaction.category,
//                             style: TextStyle(
//                                 fontSize: 13, color: Colors.grey.shade600)),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text(amountText,
//                         textAlign: TextAlign.end,
//                         style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: amountColor)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Map<String, List<TransactionItem>> groupTransactionsByMonth(
//       List<TransactionItem> transactions) {
//     final Map<String, List<TransactionItem>> grouped = {};
//     for (var transaction in transactions) {
//       final parts = transaction.date.split(' ');
//       final month = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'Unknown';
//       grouped.putIfAbsent(month, () => []);
//       grouped[month]!.add(transaction);
//     }
//     return grouped;
//   }
// }

// class TransactionItem {
//   final IconData icon;
//   final String name;
//   final String time;
//   final String date;
//   final String category;
//   final double amount;
//   final bool isExpense;

//   TransactionItem({
//     required this.icon,
//     required this.name,
//     required this.time,
//     required this.date,
//     required this.category,
//     required this.amount,
//     required this.isExpense,
//   });
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final user = FirebaseAuth.instance.currentUser;

  double totalAmountInAccount = 0;
  double monthlyBudget = 0;
  double totalIncome = 0; // Will be updated by the StreamBuilder
  double totalExpense = 0; // Will be updated by the StreamBuilder

  bool _userDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      setState(() {
        final data = doc.data();
        totalAmountInAccount = (data?['amount_in_account'] ?? 0).toDouble();
        monthlyBudget = (data?['monthly_budget'] ?? 0).toDouble();
        _userDataLoaded = true;
      });
    } else {
      setState(() {
        _userDataLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gradientStart = Color(0xFFE3F0FF);
    const Color gradientEnd = Color(0xFFF8EFFB);
    const Color primaryBlue = Color(0xFF7BAFFC);
    const Color accentPurple = Color(0xFFD6A8FF);

    return Scaffold(
      backgroundColor: gradientEnd,
      body: Column(
        children: [
          _buildTopSection(context, primaryBlue, accentPurple),
          Expanded(child: _buildTransactionList()),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, Color primaryBlue, Color accentPurple) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue.withAlpha(230), accentPurple.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          _buildAppBar(),
          const SizedBox(height: 10),
          _buildTotalBalanceCard(primaryBlue),
          const SizedBox(height: 20),
          _buildSummaryBar(primaryBlue),
          const SizedBox(height: 10),
          _buildExpenseProgress(primaryBlue),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'History',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(Color color) {
    double displayedBalance = totalAmountInAccount + totalIncome - totalExpense;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: color.withAlpha(51), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Text('Total Balance',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Text('₹${displayedBalance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(Color color) {
    double displayedBalance = totalAmountInAccount + totalIncome - totalExpense;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.white),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Income', style: TextStyle(fontSize: 12, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('₹${totalIncome.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: const Color.fromARGB(128, 255, 255, 255)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.monetization_on_outlined, size: 20, color: Colors.white),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Expense', style: TextStyle(fontSize: 12, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('-₹${totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEE6C6C))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseProgress(Color color) {
    double usedPercentage = monthlyBudget == 0
        ? 0
        : (totalExpense / monthlyBudget).clamp(0, 1).toDouble();
    int percent = (usedPercentage * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: usedPercentage,
                    backgroundColor: const Color.fromARGB(77, 255, 255, 255),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('₹${monthlyBudget.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percent%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('$percent% of your budget used',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (user == null) return const Center(child: Text("No user found"));

    final expensesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('expenses')
        .orderBy('timestamp', descending: true)
        .snapshots();

    final historyStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('history')
        .orderBy('paid_on', descending: true)
        .snapshots();

    final combined = CombineLatestStream.list<QuerySnapshot>([
      expensesStream,
      historyStream,
    ]);

    return StreamBuilder<List<QuerySnapshot>>(
      stream: combined,
      builder: (context, snapshot) {
        if (!_userDataLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // If no data, ensure totals are reset for the UI.
          if (totalIncome != 0 || totalExpense != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                totalIncome = 0;
                totalExpense = 0;
              });
            });
          }
          return const Center(
            child: Text("No history yet",
                style: TextStyle(color: Colors.black54, fontSize: 16)),
          );
        }

        // Merge & deduplicate
        final seen = <String>{};
        final allDocs = <QueryDocumentSnapshot>[];
        for (var snap in snapshot.data!) {
          for (var doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final key = "${data['title'] ?? data['expense_name'] ?? ''}_${data['amount'] ?? data['expense_amount'] ?? 0}";
            if (!seen.contains(key)) {
              seen.add(key);
              allDocs.add(doc);
            }
          }
        }

        if (allDocs.isEmpty) {
          return const Center(child: Text("No transactions yet"));
        }

        // Use local variables for calculation before updating state
        double newTotalIncome = 0;
        double newTotalExpense = 0;

        final List<TransactionItem> transactions = allDocs.map((expense) {
          final data = expense.data() as Map<String, dynamic>;

          final String name =
              (data['title'] ?? data['expense_name'] ?? data['name'] ?? '').toString();
          final String category = (data['category'] ?? '').toString();

          DateTime? dateTime;
          if (data['timestamp'] is Timestamp) {
            dateTime = (data['timestamp'] as Timestamp).toDate();
          } else if (data['paid_on'] is Timestamp) {
            dateTime = (data['paid_on'] as Timestamp).toDate();
          }

          final String date =
              dateTime != null ? DateFormat('MMMM dd').format(dateTime) : '';
          final String time =
              dateTime != null ? DateFormat('HH:mm').format(dateTime) : '';

          final String type = (data['type'] ??
                      data['expense_type'] ??
                      (data['type'] == 'Pay' ? 'Expense' : 'Income'))
                  .toString();

          final num rawAmount =
              (data['amount'] ?? data['expense_amount'] ?? 0);
          final double amount = (rawAmount is num) ? rawAmount.toDouble() : 0.0;

          if (type == 'Income' || type == 'Receive') {
            newTotalIncome += amount;
          } else {
            newTotalExpense += amount;
          }

          return TransactionItem(
            icon: (type == 'Income' || type == 'Receive')
                ? Icons.account_balance_wallet
                : Icons.money_outlined,
            name: name,
            time: time,
            date: date,
            category: category,
            amount: amount,
            isExpense: !(type == 'Income' || type == 'Receive'),
          );
        }).toList();

        // ⭐ THE CRITICAL FIX: Update the parent widget's state with the new totals
        if (totalIncome != newTotalIncome || totalExpense != newTotalExpense) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              totalIncome = newTotalIncome;
              totalExpense = newTotalExpense;
            });
          });
        }

        final grouped = groupTransactionsByMonth(transactions);
        final months = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: months.length,
          itemBuilder: (context, monthIndex) {
            final month = months[monthIndex];
            final monthTransactions = grouped[month]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Text(
                    month,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2C67),
                    ),
                  ),
                ),
                ...monthTransactions.map((tx) => _buildTransactionItem(tx)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(TransactionItem transaction) {
    final Color iconBackgroundColor =
        transaction.isExpense ? Colors.red.shade100 : Colors.green.shade100;
    final Color iconColor =
        transaction.isExpense ? Colors.red.shade600 : Colors.green.shade600;
    final Color amountColor =
        transaction.isExpense ? Colors.red.shade600 : Colors.green.shade600;

    final String amountText = transaction.isExpense
        ? '-₹${transaction.amount.toStringAsFixed(2)}'
        : '₹${transaction.amount.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(transaction.icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(transaction.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2C67))),
                        const SizedBox(height: 4),
                        Text(
                          '${transaction.time} - ${transaction.date}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(transaction.category,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(amountText,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: amountColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<TransactionItem>> groupTransactionsByMonth(
      List<TransactionItem> transactions) {
    final Map<String, List<TransactionItem>> grouped = {};
    for (var transaction in transactions) {
      final parts = transaction.date.split(' ');
      // Grouping by month and year for accuracy
      final monthYear = parts.isNotEmpty && parts[0].isNotEmpty
          ? DateFormat('MMMM yyyy').format(DateFormat('MMMM dd').parse(transaction.date))
          : 'Unknown';
      grouped.putIfAbsent(monthYear, () => []);
      grouped[monthYear]!.add(transaction);
    }
    return grouped;
  }
}

class TransactionItem {
  final IconData icon;
  final String name;
  final String time;
  final String date;
  final String category;
  final double amount;
  final bool isExpense;

  TransactionItem({
    required this.icon,
    required this.name,
    required this.time,
    required this.date,
    required this.category,
    required this.amount,
    required this.isExpense,
  });
}