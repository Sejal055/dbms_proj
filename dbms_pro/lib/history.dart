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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE9E4F5), // light purple
              Color(0xFFF7F7F7), // near white
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildTransactionList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=${DateTime.now().millisecondsSinceEpoch % 70}'),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hi, User!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 26),
            onPressed: () {},
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final name = expense['expense_name'] ?? '';
            final amount = expense['expense_amount'] ?? 0;
            final type = expense['expense_type'] ?? 'Expense';
            final category = expense['category'] ?? '';
            final timestamp = expense['timestamp'] as Timestamp?;
            final date = timestamp != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                : '';

            bool isDebit = type != 'Income';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDebit
                          ? Colors.pink.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isDebit ? Colors.pink : Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${isDebit ? '-' : ''}₹$amount",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDebit ? Colors.pink.shade400 : Colors.green,
                    ),
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
