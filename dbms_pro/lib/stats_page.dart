import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  double totalIncome = 0;
  double totalExpense = 0;

  Future<void> fetchData() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('transactions').get();

    double income = 0;
    double expense = 0;

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      double amount = data['amount']?.toDouble() ?? 0.0;
      String type = data['type'];
      if (type == 'income') {
        income += amount;
      } else if (type == 'expense') {
        expense += amount;
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    double balance = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: Color(0xFFF4F2FD),
      appBar: AppBar(
        backgroundColor: Color(0xFFF4F2FD),
        elevation: 0,
        centerTitle: true,
        title: Text('Statistic', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Balance', style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 6),
            Text('\$${balance.toStringAsFixed(2)}', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFBEB6D8)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text('Month', style: TextStyle(color: Color(0xFF8F7EF3))),
                      Icon(Icons.keyboard_arrow_down, color: Color(0xFF8F7EF3)),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 24),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text('Bar Chart Placeholder')), // Use a chart widget here
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Income',
                    amount: '\$${totalIncome.toStringAsFixed(2)}',
                    color: Color(0xFF24126A),
                    isExpense: false,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: _buildStatCard(
                    label: 'Expense',
                    amount: '\$${totalExpense.toStringAsFixed(2)}',
                    color: Color(0xFF8F7EF3),
                    isExpense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String label, required String amount, required Color color, required bool isExpense}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(8),
            child: Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(height: 30),
          Text(label, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
