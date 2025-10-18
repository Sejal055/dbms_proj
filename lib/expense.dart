import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpensesPage extends StatelessWidget {
  final String category;

  const ExpensesPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // Gradient AppBar background for branding and flow
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        title: Text(
          'Expenses - $category',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDEE6FB), Color(0xFFD6EAF8), Color(0xFFFDEBEE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('expenses')
              .where('category', isEqualTo: category)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading expenses'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;

            // Compute total expense and total income
            double totalExpense = 0, totalIncome = 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final type = (data['expense_type'] ?? 'Expense').toString().toLowerCase();
              final amount = (data['expense_amount'] is num)
                  ? (data['expense_amount'] as num).toDouble()
                  : 0.0;
              if (type == 'expense') {
                totalExpense += amount;
              } else if (type == 'income') {
                totalIncome += amount;
              }
            }

            return Column(
              children: [
                // Top summary card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black.withOpacity(0.08),
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(vertical: 22, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Summary',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.deepPurpleAccent,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Icon(Icons.money_off, color: Colors.redAccent, size: 26),
                                  SizedBox(height: 5),
                                  Text(
                                    'Total Expense',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '₹${totalExpense.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 44, color: Colors.grey[200]),
                            Expanded(
                              child: Column(
                                children: [
                                  Icon(Icons.attach_money, color: Colors.green, size: 26),
                                  SizedBox(height: 5),
                                  Text(
                                    'Total Income',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '₹${totalIncome.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                 ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (docs.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No expenses in "$category"',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = data['expense_name'] ?? 'Unnamed';
                    final type = data['expense_type'] ?? 'Expense';
                    final amount = (data['expense_amount'] is num)
                        ? (data['expense_amount'] as num).toDouble()
                        : 0.0;
                    final displayAmount = '₹${amount.toStringAsFixed(2)}';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            type.toString().toLowerCase() == 'income'
                                ? Icons.arrow_circle_up
                                : Icons.arrow_circle_down,
                            color: type.toString().toLowerCase() == 'income'
                            ? Colors.green
                                : Colors.redAccent,
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            type,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Text(
                            displayAmount,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: type.toString().toLowerCase() == 'income'
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    ),
  ),
);
}
}