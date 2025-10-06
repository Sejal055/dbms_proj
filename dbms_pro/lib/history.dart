import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final user = FirebaseAuth.instance.currentUser;

  double totalBalance = 0.0;
  double monthlyBudget = 0.0;
  double totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        totalBalance = (data['amount_in_account'] ?? 0).toDouble();
        monthlyBudget = (data['monthly_budget'] ?? 0).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F9),
      body: Column(
        children: [
          _buildTopSection(context),
          Expanded(
            child: _buildTransactionList(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    const Color primaryGreen = Color(0xFF57CC99);
    const Color primaryDarkBlue = Color(0xFF0F2C67);
    const Color primaryBackground = Color(0xFFB1E8CE);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: primaryBackground,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryGreen.withOpacity(0.9),
            primaryBackground,
          ],
        ),
      ),
      child: Column(
        children: [
          _buildAppBar(),
          const SizedBox(height: 10),
          _buildTotalBalanceCard(primaryDarkBlue),
          const SizedBox(height: 20),
          _buildSummaryBar(primaryGreen),
          const SizedBox(height: 10),
          _buildExpenseProgress(),
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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Text(
            'Transaction',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(Color darkColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              'Total Balance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '₹${(totalBalance - totalExpense).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: darkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(Color greenColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 20, color: greenColor),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Balance',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${(totalBalance - totalExpense).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withOpacity(0.5),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.monetization_on_outlined,
                    size: 20, color: greenColor),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Expense',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      '-₹${totalExpense.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade300),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseProgress() {
    double progressValue =
        monthlyBudget != 0 ? (totalExpense / monthlyBudget).clamp(0, 1) : 0;

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
                    value: progressValue,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F2C67)),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '₹${monthlyBudget.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progressValue * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const Text(
                'Of your monthly budget used',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (user == null) {
      return const Center(child: Text("No user found"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('expenses')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No history yet",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          );
        }

        final expenses = snapshot.data!.docs;

        totalExpense = 0.0;

        final List<TransactionItem> transactions = expenses.map((expense) {
          final data = expense.data() as Map<String, dynamic>;

          final name = data['expense_name'] ?? '';
          final amount = (data['expense_amount'] ?? 0).toDouble();
          final type = data['type'] ?? 'Expense';
          final category = data['category'] ?? '';
          final timestamp = data['timestamp'] as Timestamp?;
          final date = timestamp != null
              ? DateFormat('MMMM dd').format(timestamp.toDate())
              : '';
          final time = timestamp != null
              ? DateFormat('HH:mm').format(timestamp.toDate())
              : '';

          if (type != 'Income') {
            totalExpense += amount;
          } else {
            totalBalance += amount;
          }

          return TransactionItem(
            icon: type == 'Income' ? Icons.account_balance_wallet : Icons.money,
            name: name,
            time: time,
            date: date,
            category: category,
            amount: amount,
            isExpense: type != 'Income',
          );
        }).toList();

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
            Column(
              children: [
                Expanded(
                    child:
                        Container(width: 2, color: iconColor.withOpacity(0.3))),
                Container(
                    width: 2, height: 10, color: iconColor.withOpacity(0.7)),
                Expanded(
                    child:
                        Container(width: 2, color: iconColor.withOpacity(0.3))),
              ],
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
                        Text(
                          transaction.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2C67)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transaction.time} - ${transaction.date}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.category,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      amountText,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
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
      final month = transaction.date.split(' ')[0];
      if (!grouped.containsKey(month)) {
        grouped[month] = [];
      }
      grouped[month]!.add(transaction);
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

