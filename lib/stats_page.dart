import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// --- Darker Theme Colors ---
const Color primaryColor = Color(0xFFD0E3FF);
const Color secondaryColor = Color(0xFFE9D5F8);
const Color incomeColor = Color(0xFF5A96F0);
const Color expenseColor = Color(0xFFB47BE8);
const Color progressFill = Color(0xFF5A96F0);

/// ===============================================================
/// 🔹 MAIN STATISTICS PAGE (Top Tabs + Swipe Pages)
/// ===============================================================
class StatisticsMainPage extends StatefulWidget {
  const StatisticsMainPage({super.key});

  @override
  State<StatisticsMainPage> createState() => _StatisticsMainPageState();
}

class _StatisticsMainPageState extends State<StatisticsMainPage> {
  final PageController _pageController = PageController(initialPage: 0); // Start with Outlook
  int _currentPage = 0;

  final List<String> _tabs = [
    'OUTLOOK',
    'CASH-FLOW',
    'SPENDING',
    'REPORT',
  ];

  void _onTabSelected(int index) {
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [secondaryColor, primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Statistics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Top Tab Bar with Gradient Background ---
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [secondaryColor, primaryColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final selected = _currentPage == index;
                return GestureDetector(
                  onTap: () => _onTabSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected ? Colors.black87 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.black54,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // --- PageView for Swipe Navigation ---
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: const [
                OutlookPage(),
                CashFlowPage(),
                SpendingPage(),
                ReportPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// 🔹 OUTLOOK PAGE (Your Original Code, UNCHANGED except category-wise spending made dynamic)
/// ===============================================================
class OutlookPage extends StatefulWidget {
  const OutlookPage({super.key});

  @override
  State<OutlookPage> createState() => _OutlookPageState();
}

class _OutlookPageState extends State<OutlookPage> {
  final user = FirebaseAuth.instance.currentUser;

  double totalBalance = 0;
  double totalIncome = 0;
  double totalExpense = 0;
  double monthlyBudget = 0;
  double amountInAccount = 0;

  Map<String, List<double>> chartData = {};
  Map<String, double> categoryData = {};

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

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['expense_type'] ?? 'Expense';
      final amount = (data['expense_amount'] ?? 0).toDouble();
      final timestamp = _parseTimestamp(data['timestamp']);
      final category = (data['category'] ?? 'Others').toString();

      String label = '';
      if (_selectedPeriod == 'Daily') {
        label = DateFormat('EEE').format(timestamp);
      } else if (_selectedPeriod == 'Weekly') {
        int weekOfMonth = ((timestamp.day - 1) ~/ 7) + 1;
        label = 'Week $weekOfMonth';
      } else if (_selectedPeriod == 'Monthly') {
        label = DateFormat('MMM').format(timestamp);
      } else if (_selectedPeriod == 'Year') {
        label = DateFormat('yyyy').format(timestamp);
      }

      tempChartData.putIfAbsent(label, () => [0, 0]);

      if (type == 'Income') {
        income += amount;
        tempChartData[label]![0] += amount;
      } else {
        expense += amount;
        tempChartData[label]![1] += amount;

        tempCategoryData[category] = (tempCategoryData[category] ?? 0) + amount;
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      totalBalance = amountInAccount + totalIncome - totalExpense;
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

  DateTime _parseTimestamp(dynamic ts) {
    try {
      if (ts == null) return DateTime.now();
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      if (ts is String) {
        // try parse ISO or fallback to DateTime.now
        DateTime? dt = DateTime.tryParse(ts);
        if (dt != null) return dt;
        // maybe string like "October 20, 2025 at 12:23:09 PM UTC+5:30"
        // fallback: return now
        return DateTime.now();
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    double expensePercentage = monthlyBudget == 0 ? 0 : (totalExpense / monthlyBudget);
    String percentageText = '${(expensePercentage * 100).toStringAsFixed(0)}%';

    return Scaffold(
      backgroundColor: primaryColor,
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
            color: Color.fromARGB(77, 208, 227, 255), // primaryColor with 30% opacity
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
              Container(width: 1, height: 50, color: Color.fromARGB(128, 158, 158, 158)),
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
      labels = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
        'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
    } else {
      labels = chartData.keys.toList()..sort();
    }

    List<BarChartGroupData> bars = [];
    int i = 0;

    for (var label in labels) {
      final values = chartData[label] ?? [0, 0];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: values[0], color: incomeColor, width: 10),
            BarChartRodData(toY: values[1], color: expenseColor, width: 10),
          ],
        ),
      );
      i++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text('Income & Expenses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            color: iconColor.withAlpha(38), borderRadius: BorderRadius.circular(15),
          ),
          
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
    List<String> categories = categoryData.keys.toList();
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

/// ===============================================================
/// 🔹 CASHFLOW PAGE (unchanged)
/// ===============================================================
class CashFlowPage extends StatefulWidget {
  const CashFlowPage({super.key});

  @override
  State<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends State<CashFlowPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool loading = true;

  double totalIncome30 = 0;
  double totalExpense30 = 0;
  double net30 = 0;

  // For trend: map date-> income/expense
  Map<DateTime, double> incomeByDay = {};
  Map<DateTime, double> expenseByDay = {};

  // For period comparison
  double incomeThisMonth = 0;
  double expenseThisMonth = 0;
  double incomePrevMonth = 0;
  double expensePrevMonth = 0;
  double incomeThisYear = 0;
  double expenseThisYear = 0;
  double incomePrevYear = 0;
    double expensePrevYear = 0;

  @override
  void initState() {
    super.initState();
    _loadCashflowData();
  }

  DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _parseTimestamp(dynamic ts) {
    try {
      if (ts == null) return DateTime.now();
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      if (ts is String) {
        DateTime? dt = DateTime.tryParse(ts);
        if (dt != null) return dt;
        return DateTime.now();
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _loadCashflowData() async {
    if (user == null) return;
    final uid = user!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    DateTime now = DateTime.now();
    DateTime start30 = now.subtract(const Duration(days: 30));

    Map<DateTime, double> incomeMap = {};
    Map<DateTime, double> expenseMap = {};

    double inc30 = 0, exp30 = 0;

    // zero-fill last 30 days
    for (int i = 0; i <= 30; i++) {
      final d = _stripTime(start30.add(Duration(days: i)));
      incomeMap[d] = 0;
      expenseMap[d] = 0;
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = (data['expense_type'] ?? 'Expense').toString();
      final amount = (data['expense_amount'] ?? 0).toDouble();
      final ts = _parseTimestamp(data['timestamp']);
      final date = _stripTime(ts);

      // last 30 days totals & trend
      if (!date.isBefore(_stripTime(start30))) {
        if (type == 'Income') {
          inc30 += amount;
          incomeMap[date] = (incomeMap[date] ?? 0) + amount;
        } else {
          exp30 += amount;
          expenseMap[date] = (expenseMap[date] ?? 0) + amount;
        }
      }

      // monthly/yearly comparisons
      if (date.year == now.year && date.month == now.month) {
        if (type == 'Income') incomeThisMonth += amount;
        else expenseThisMonth += amount;
      }
      final prevMonth = DateTime(now.year, now.month - 1 < 1 ? 12 : now.month - 1,
          1); // rough prev-month check below
      if ((date.year == now.year && date.month == now.month - 1) ||
          (now.month == 1 && date.year == now.year - 1 && date.month == 12 && now.month - 1 < 1)) {
        if (type == 'Income') incomePrevMonth += amount;
        else expensePrevMonth += amount;
      }

      if (date.year == now.year) {
        if (type == 'Income') incomeThisYear += amount;
        else expenseThisYear += amount;
      }
      if (date.year == now.year - 1) {
        if (type == 'Income') incomePrevYear += amount;
        else expensePrevYear += amount;
      }
    }

    setState(() {
      incomeByDay = incomeMap;
      expenseByDay = expenseMap;
      totalIncome30 = inc30;
      totalExpense30 = exp30;
      net30 = inc30 - exp30;
      loading = false;
    });
  }

  List<FlSpot> _makeSpotsFromMap(Map<DateTime, double> map) {
    final sorted = map.keys.toList()..sort();
    List<FlSpot> spots = [];
    for (int i = 0; i < sorted.length; i++) {
      final d = sorted[i];
      spots.add(FlSpot(i.toDouble(), map[d]!.toDouble()));
    }
    return spots;
  }

  List<String> _makeLabelsFromMap(Map<DateTime, double> map) {
    final sorted = map.keys.toList()..sort();
    return sorted.map((d) => DateFormat('d MMM').format(d)).toList();
  }

  List<FlSpot> _makeCumulativeSpots(Map<DateTime, double> incomeMap, Map<DateTime, double> expenseMap) {
    final sorted = incomeMap.keys.toList()..sort();
    List<FlSpot> spots = [];
    double cum = 0;
    for (int i = 0; i < sorted.length; i++) {
      final d = sorted[i];
      final inc = incomeMap[d] ?? 0;
      final exp = expenseMap[d] ?? 0;
      cum += (inc - exp);
      spots.add(FlSpot(i.toDouble(), cum));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final incomeSpots = _makeSpotsFromMap(incomeByDay);
    final expenseSpots = _makeSpotsFromMap(expenseByDay);
    final cumSpots = _makeCumulativeSpots(incomeByDay, expenseByDay);
    final labels = _makeLabelsFromMap(incomeByDay);

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top summary card for last 30 days
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Income (30d)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('₹${totalIncome30.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Expense (30d)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('₹${totalExpense30.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Net (30d)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('₹${net30.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: net30 >= 0 ? incomeColor : expenseColor)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Trend + Cumulative Chart
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Cash Flow Trend (30 days)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= labels.length) return const SizedBox();
                                  // show only few labels to avoid crowding
                                  if (idx % 6 == 0 || idx == labels.length - 1) {
                                    return Text(labels[idx], style: const TextStyle(fontSize: 10));
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: incomeSpots,
                              isCurved: true,
                              barWidth: 2.5,
                              dotData: FlDotData(show: false),
                              color: incomeColor,
                            ),
                            LineChartBarData(
                              spots: expenseSpots,
                              isCurved: true,
                              barWidth: 2.5,
                              dotData: FlDotData(show: false),
                              color: expenseColor,
                            ),
                            LineChartBarData(
                              spots: cumSpots,
                              isCurved: true,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _legendDot(incomeColor, 'Income'),
                        _legendDot(expenseColor, 'Expense'),
                        _legendDot(Colors.black87, 'Cumulative'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Period-to-period comparisons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Period Comparison', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('This month vs Previous month'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          const Text('Income', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹${incomeThisMonth.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Prev: ₹${incomePrevMonth.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ]),
                        Column(children: [
                          const Text('Expense', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹${expenseThisMonth.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Prev: ₹${expensePrevMonth.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('This year vs Previous year'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          const Text('Income', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹${incomeThisYear.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Prev: ₹${incomePrevYear.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ]),
                        Column(children: [
                          const Text('Expense', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹${expenseThisYear.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Prev: ₹${expensePrevYear.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

/// ===============================================================
/// 🔹 SPENDING PAGE (modified: added color legend for pie, removed nature of spending, improved categories UI)
/// ===============================================================
class SpendingPage extends StatefulWidget {
  const SpendingPage({super.key});

  @override
  State<SpendingPage> createState() => _SpendingPageState();
}

class _SpendingPageState extends State<SpendingPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool loading = true;

  Map<String, double> categoryTotals = {}; // category -> total expense
  Map<DateTime, double> spendingByDay = {};
  double totalSpending = 0;

  // simple essentials list fallback (if no is_essential field present)
  final List<String> _essentialCategories = [
    'Food & Dining', 'Groceries', 'Rent', 'Utilities', 'Education', 'Transport'
  ];

  @override
  void initState() {
    super.initState();
    _loadSpendingData();
  }

  DateTime _strip(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _parseTimestamp(dynamic ts) {
    try {
      if (ts == null) return DateTime.now();
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      if (ts is String) {
        DateTime? dt = DateTime.tryParse(ts);
        if (dt != null) return dt;
        return DateTime.now();
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _loadSpendingData() async {
    if (user == null) return;
    final uid = user!.uid;
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('expenses').get();

    Map<String, double> catTotals = {};
    Map<DateTime, double> dayTotals = {};
    double tot = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = (data['expense_type'] ?? 'Expense').toString();
      final amount = (data['expense_amount'] ?? 0).toDouble();
      final ts = _parseTimestamp(data['timestamp']);
      final date = _strip(ts);
      final category = (data['category'] ?? 'Others').toString();

      if (type == 'Expense') {
        tot += amount;
        catTotals[category] = (catTotals[category] ?? 0) + amount;
        dayTotals[date] = (dayTotals[date] ?? 0) + amount;
      } else {
        // treat incomes separate; we don't add them to spending totals
      }
    }

    setState(() {
      categoryTotals = catTotals;
      spendingByDay = dayTotals;
      totalSpending = tot;
      loading = false;
    });
  }

  List<PieChartSectionData> _makePieSections() {
    final colors = [Colors.blueAccent, Colors.orangeAccent, Colors.green, Colors.purpleAccent, Colors.teal, Colors.amber];
    final cats = categoryTotals.keys.toList();
    if (cats.isEmpty) return [];

    double maxVal = categoryTotals.values.fold(0.0, (a, b) => a > b ? a : b);
    List<PieChartSectionData> sections = [];
    for (int i = 0; i < cats.length; i++) {
      final cat = cats[i];
      final val = categoryTotals[cat] ?? 0;
      final perc = totalSpending == 0 ? 0 : (val / totalSpending) * 100;
      sections.add(
        PieChartSectionData(
          value: val,
          title: '${perc.toStringAsFixed(0)}%',
          radius: maxVal == 0 ? 30 : (40 - (val / maxVal) * 20),
          showTitle: true,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          color: colors[i % colors.length],
        ),
      );
    }
    return sections;
  }

  List<FlSpot> _spendingSpots() {
    final sorted = spendingByDay.keys.toList()..sort();
    List<FlSpot> spots = [];
    for (int i = 0; i < sorted.length; i++) {
      final d = sorted[i];
      spots.add(FlSpot(i.toDouble(), spendingByDay[d]!.toDouble()));
    }
    return spots;
  }

  List<String> _spendingLabels() {
    final sorted = spendingByDay.keys.toList()..sort();
    return sorted.map((d) => DateFormat('d MMM').format(d)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final pieSections = _makePieSections();
    final spots = _spendingSpots();
    final labels = _spendingLabels();
    final colors = [Colors.blueAccent, Colors.orangeAccent, Colors.green, Colors.purpleAccent, Colors.teal, Colors.amber];
    final cats = categoryTotals.keys.toList();

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top: Pie chart + total + legend
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('Spending by Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: pieSections.isEmpty
                          ? const Center(child: Text('No spending data'))
                          : PieChart(PieChartData(sections: pieSections, sectionsSpace: 2, centerSpaceRadius: 30)),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Spending: ₹${totalSpending.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Legend for pie chart colors
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: List.generate(cats.length, (i) {
                        final cat = cats[i];
                        final color = colors[i % colors.length];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 6),
                            Text('$cat: ₹${categoryTotals[cat]?.toStringAsFixed(2) ?? '0.00'}'),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Trend
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Spending Trend', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: spots.isEmpty
                          ? const Center(child: Text('No trend data'))
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= labels.length) return const SizedBox();
                                        if (idx % 6 == 0 || idx == labels.length - 1) {
                                          return Text(labels[idx], style: const TextStyle(fontSize: 10));
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    dotData: FlDotData(show: false),
                                    color: expenseColor,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Categories (improved UI: grid or better layout)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3,
                      ),
                      itemCount: categoryTotals.length,
                      itemBuilder: (context, index) {
                        final cat = cats[index];
                        final amount = categoryTotals[cat] ?? 0;
                        return GestureDetector(
                          onTap: () {
                            // navigate to category detail
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailPage(category: cat)));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('₹${amount.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small category detail page (placeholder)
class CategoryDetailPage extends StatelessWidget {
  final String category;
  const CategoryDetailPage({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: Center(child: Text('Category detail for $category (replace with real page)')),
    );
  }
}

/// ===============================================================
/// 🔹 REPORT PAGE (modified: bill-style quick report with total transactions)
/// ===============================================================
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool loading = true;

  int countTransactions = 0;
  double totalIncome = 0;
  double totalExpense = 0;
  double avgPerTransaction = 0;
  double avgPerDay = 0;

  Map<String, double> categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  DateTime _parseTimestamp(dynamic ts) {
    try {
      if (ts == null) return DateTime.now();
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      if (ts is String) {
        DateTime? dt = DateTime.tryParse(ts);
        if (dt != null) return dt;
        return DateTime.now();
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _loadReport() async {
    if (user == null) return;
    final uid = user!.uid;
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('expenses').get();

    int count = 0;
    double inc = 0;
    double exp = 0;
    Map<String, double> catTotals = {};
    DateTime? earliest;
    DateTime? latest;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = (data['expense_type'] ?? 'Expense').toString();
      final amount = (data['expense_amount'] ?? 0).toDouble();
      final ts = _parseTimestamp(data['timestamp']);

      count++;
      if (type == 'Income') inc += amount;
      else exp += amount;

      final category = (data['category'] ?? 'Others').toString();
      if (type != 'Income') catTotals[category] = (catTotals[category] ?? 0) + amount;

      if (earliest == null || ts.isBefore(earliest)) earliest = ts;
      if (latest == null || ts.isAfter(latest)) latest = ts;
    }

    final days = (earliest == null || latest == null) ? 1 : latest.difference(earliest).inDays + 1;
    final avgTrans = count == 0 ? 0 : ((inc + exp) / count);
    final avgDay = days == 0 ? 0 : ((inc + exp) / days);

    setState(() {
      countTransactions = count;
      totalIncome = inc;
      totalExpense = exp;
      avgPerTransaction = avgTrans.toDouble();
      avgPerDay = avgDay.toDouble();
      categoryTotals = catTotals;
      loading = false;
    });
  }

  List<BarChartGroupData> _categoryBarGroups() {
    final cats = categoryTotals.keys.toList();
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < cats.length; i++) {
      final val = categoryTotals[cats[i]] ?? 0;
      groups.add(BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: val, color: expenseColor, width: 12)],
      ));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final catLabels = categoryTotals.keys.toList();

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Quick Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Bill-style summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expense Bill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Category Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...categoryTotals.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text('₹${entry.value.toStringAsFixed(2)}'),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Spent:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Income:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${(totalIncome - totalExpense).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Transactions:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$countTransactions', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Avg per Transaction:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${avgPerTransaction.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Avg per Day:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${avgPerDay.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Spending by Category bar chart (unchanged)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Spending by Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: categoryTotals.isEmpty
                          ? const Center(child: Text('No category data'))
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barGroups: _categoryBarGroups(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= catLabels.length) return const SizedBox();
                                        return SideTitleWidget(
                                          meta: meta,
                                          child: Text(catLabels[idx], style: const TextStyle(fontSize: 10)),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                                ),
                                gridData: FlGridData(show: true),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}