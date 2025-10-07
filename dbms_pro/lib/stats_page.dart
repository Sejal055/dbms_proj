import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// --- Darker Theme Colors ---
const Color primaryColor = Color(0xFFD0E3FF); // Slightly darker blue
const Color secondaryColor = Color(0xFFE9D5F8); // Slightly darker pink
const Color incomeColor = Color(0xFF5A96F0); // Darker blue for income
const Color expenseColor = Color(0xFFB47BE8); // Darker purple for expense
const Color progressFill = Color(0xFF5A96F0); // Progress bar color

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final user = FirebaseAuth.instance.currentUser;

  double totalBalance = 0;
  double totalIncome = 0;
  double totalExpense = 0;
  double monthlyBudget = 0;
  double amountInAccount = 0;

  Map<String, List<double>> chartData = {}; // {label: [income, expense]}
  Map<String, double> categoryData = {}; // {category: expenseAmount}

  String _selectedPeriod = 'Daily';

  final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTransactionData();
  }

  void fetchUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      setState(() {
        monthlyBudget = (doc.data()?['monthly_budget'] ?? 0).toDouble();
        amountInAccount = (doc.data()?['amount_in_account'] ?? 0).toDouble();
      });
    }
  }

  void fetchTransactionData() async {
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('expenses')
        .get();

    double income = 0;
    double expense = 0;
    Map<String, List<double>> tempChartData = {};
    Map<String, double> tempCategoryData = {};

    DateTime now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['expense_type'] ?? 'Expense';
      final amount = (data['expense_amount'] ?? 0).toDouble();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final category = (data['category'] ?? 'Others').toString();

      String label = '';

      if (_selectedPeriod == 'Daily') {
        label = DateFormat('EEE').format(timestamp); // Mon–Sun
      } else if (_selectedPeriod == 'Weekly') {
        int weekOfMonth = ((timestamp.day - 1) ~/ 7) + 1;
        label = 'Week $weekOfMonth';
      } else if (_selectedPeriod == 'Monthly') {
        label = DateFormat('MMM').format(timestamp); // Jan–Dec
      } else if (_selectedPeriod == 'Year') {
        label = DateFormat('yyyy').format(timestamp);
      }

      if (!tempChartData.containsKey(label)) {
        tempChartData[label] = [0, 0];
      }

      if (type == 'Income') {
        income += amount;
        tempChartData[label]![0] += amount;
      } else {
        expense += amount;
        tempChartData[label]![1] += amount;

        // Category-wise aggregation
        if (!tempCategoryData.containsKey(category)) {
          tempCategoryData[category] = 0;
        }
        tempCategoryData[category] = tempCategoryData[category]! + amount;
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      totalBalance = amountInAccount + totalIncome - totalExpense; // ✅ Fixed
      chartData = tempChartData;
      categoryData = tempCategoryData;
    });
  }

  void _fetchDataForPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      fetchTransactionData();
    });
  }

  @override
  Widget build(BuildContext context) {
    double expensePercentage = monthlyBudget == 0 ? 0 : (totalExpense / monthlyBudget);
    String percentageText = '${(expensePercentage * 100).toStringAsFixed(0)}%';

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analysis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [secondaryColor, primaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  _buildBalanceAndExpenseCard(percentageText, expensePercentage),
                  const SizedBox(height: 20),
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  _buildChartCard(),
                  const SizedBox(height: 20),
                  _buildIncomeExpenseTotals(),
                  const SizedBox(height: 20),
                  const Text('Category-wise Spending',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildCategoryProgress(),
                  const SizedBox(height: 20),
                  const Text('My Targets',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceAndExpenseCard(String percentageText, double expensePercentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Total Balance', totalBalance, true, Icons.account_balance_wallet_outlined, incomeColor),
              Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.5)),
              _buildMetric('Total Expense', totalExpense, false, Icons.remove_circle_outline, expenseColor),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(percentageText, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: expensePercentage.clamp(0, 1),
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(progressFill),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('₹${monthlyBudget.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, double value, bool isPositive, IconData icon, Color iconColor) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPositive ? incomeColor : expenseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    List<String> periods = ['Daily', 'Weekly', 'Monthly', 'Year'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: periods.map((period) {
          bool selected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => _fetchDataForPeriod(period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? incomeColor : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  period,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartCard() {
    List<String> labels;
    if (_selectedPeriod == 'Daily') {
      labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    } else if (_selectedPeriod == 'Weekly') {
      labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
    } else if (_selectedPeriod == 'Monthly') {
      labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    } else {
      labels = chartData.keys.toList()..sort();
    }

    List<BarChartGroupData> bars = [];
    int i = 0;

    for (var label in labels) {
      final values = chartData[label] ?? [0, 0];
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
              toY: values[0], color: incomeColor, width: 10, borderRadius: BorderRadius.circular(2)),
          BarChartRodData(
              toY: values[1], color: expenseColor, width: 10, borderRadius: BorderRadius.circular(2)),
        ],
      ));
      i++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text('Income & Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 15000,
                barGroups: bars,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= labels.length) return const SizedBox();
                      return Text(labels[index], style: const TextStyle(fontSize: 12));
                    }),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseTotals() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTotalMetric(Icons.arrow_upward, incomeColor, 'Income', totalIncome, Colors.black),
        _buildTotalMetric(Icons.arrow_downward, expenseColor, 'Expense', totalExpense, expenseColor),
      ],
    );
  }

  Widget _buildTotalMetric(IconData icon, Color iconColor, String label, double value, Color valueColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 4),
        Text('₹${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildCategoryProgress() {
    List<String> categories = ['Food & Dining', 'Education', 'Entertainment', 'Others'];
    return Column(
      children: categories.map((cat) {
        double catExpense = categoryData[cat] ?? 0;
        double catPercent = monthlyBudget == 0 ? 0 : (catExpense / monthlyBudget);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: catPercent.clamp(0, 1),
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(expenseColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('₹${catExpense.toStringAsFixed(2)}'),
            ],
          ),
        );
      }).toList(),
    );
  }
}
