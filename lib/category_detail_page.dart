// lib/category_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CategoryDetailPage extends StatefulWidget {
  final String category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final user = FirebaseAuth.instance.currentUser;

  double totalIncome = 0;
  double totalExpense = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌈 Soft gradient background (light purple + blue)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6E6FA), Color(0xFFE0F0FF)], // light purple + blue
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildSummaryBox(),
            Expanded(child: _buildTransactionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7BAFFC), Color(0xFFD6A8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox() {
    final netBalance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem("Income", totalIncome, Colors.green),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildSummaryItem("Expense", totalExpense, Colors.red),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildSummaryItem(
              "Net", netBalance, netBalance >= 0 ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('expenses')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              "No transactions yet.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // Filter transactions (by category)
        final transactions = widget.category == "All Categories"
            ? docs
            : docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final cat = (data['category'] ?? '').toString().toLowerCase();
                return cat == widget.category.toLowerCase();
              }).toList();

        if (transactions.isEmpty) {
          // Reset totals only once without flicker
          if (totalIncome != 0 || totalExpense != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  totalIncome = 0;
                  totalExpense = 0;
                });
              }
            });
          }

          return const Center(
            child: Text(
              "No transactions yet.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        // Calculate totals without calling setState repeatedly (no flicker)
        double income = 0;
        double expense = 0;
        for (var doc in transactions) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['expense_type'] ?? '';
          final amount = (data['expense_amount'] ?? 0).toDouble();

          if (type == 'Income') {
            income += amount;
          } else if (type == 'Expense') {
            expense += amount;
          }
        }

        // Update once after data fully loaded (avoid flicker)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              (income != totalIncome || expense != totalExpense)) {
            setState(() {
              totalIncome = income;
              totalExpense = expense;
            });
          }
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final data = transactions[index].data() as Map<String, dynamic>;
            final amount = data['expense_amount'] ?? 0;
            final type = data['expense_type'] ?? 'Expense';
            final name = data['expense_name'] ?? '';
            final category = data['category'] ?? 'Others';
            final timestamp = data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now();

            final formattedDate =
                DateFormat('MMM dd, yyyy – hh:mm a').format(timestamp);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : category,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                  // Right side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${type == 'Income' ? '+' : '-'}₹$amount",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              type == 'Income' ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          color: type == 'Income'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
