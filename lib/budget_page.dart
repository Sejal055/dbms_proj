import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// --- Theme Colors ---
const Color primaryColor = Color(0xFFD0E3FF);
const Color secondaryColor = Color(0xFFE9D5F8);
const Color incomeColor = Color(0xFF5A96F0);
const Color expenseColor = Color(0xFFB47BE8);
const Color headerTextColor = Colors.black87;
const Color bodyTextColor = Colors.black54;

// --- Main Widget ---
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage>
    with SingleTickerProviderStateMixin {
  DateTime selectedMonth = DateTime.now();
  double totalMonthlyBudget = 0;
  Map<String, double> categoryBudgets = {};
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> budgetHistory = [];

  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    _loadCategories();
    _loadMonthlyBudget(selectedMonth);
    _fetchBudgetHistory();
  }

  // --- Data Loading Functions ---

  Future<void> _loadCategories() async {
    categories = [
      {'name': 'Food & Dining'},
      {'name': 'Education'},
      {'name': 'Transportation'},
      {'name': 'Entertainment'},
    ];

    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      categories.add({'name': doc.data()['name']});
    }

    setState(() {
      for (var cat in categories) {
        categoryBudgets[cat['name']] = 0;
      }
    });

    _loadMonthlyBudget(selectedMonth);
  }

  Future<void> _loadMonthlyBudget(DateTime month) async {
    final key = DateFormat('yyyy-MM').format(month);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(key)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final catBudgets = Map<String, double>.from(
        (data['category_budgets'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );

      setState(() {
        totalMonthlyBudget = (data['total_budget'] ?? 0).toDouble();
        for (var cat in categories) {
          categoryBudgets[cat['name']] = catBudgets[cat['name']] ?? 0;
        }
      });
    } else {
      setState(() {
        totalMonthlyBudget = 0;
        for (var cat in categories) {
          categoryBudgets[cat['name']] = 0;
        }
      });
    }
  }

  Future<void> _fetchBudgetHistory() async {
    final currentMonthKey = DateFormat('yyyy-MM').format(selectedMonth);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> history = [];

    for (var doc in snapshot.docs) {
      if (doc.id != currentMonthKey) {
        final data = doc.data();
        history.add({
          'month': doc.id,
          'total_budget': (data['total_budget'] ?? 0).toDouble(),
        });
      }
    }

    setState(() {
      budgetHistory = history;
    });
  }

  // --- Helper Getters ---
  double get sumOfCategoryBudgets =>
      categoryBudgets.values.fold(0, (a, b) => a + b);

  double get othersBudget => totalMonthlyBudget - sumOfCategoryBudgets >= 0
      ? totalMonthlyBudget - sumOfCategoryBudgets
      : 0;

  Future<void> _saveBudget() async {
    final key = DateFormat('yyyy-MM').format(selectedMonth);
    Map<String, double> finalCategoryBudgets = Map.from(categoryBudgets);
    finalCategoryBudgets['Others'] = othersBudget;

    // 1. Saves to the historical subcollection (Your existing code)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(key)
        .set({
          'total_budget': totalMonthlyBudget,
          'category_budgets': finalCategoryBudgets,
          'timestamp': DateTime.now(),
        });

    // --- ⬇️ START: THE FIX ⬇️ ---
    // 2. Also update the main user document (for the profile page)
    //    We only do this if the budget being saved is for the *current* month.

    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    // Check if the month being saved (key) is the current month (currentMonthKey)
    if (key == currentMonthKey) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        // This is the field name your ProfilePage reads
        'monthly_budget': totalMonthlyBudget,
      });
    }
    // --- ⬆️ END: THE FIX ⬆️ ---

    if (mounted) {
      Navigator.pop(context);
      _fetchBudgetHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Budget for ${DateFormat.yMMMM().format(selectedMonth)} saved successfully!',
          ),
        ),
      );
    }
  }

  Future<void> _selectMonthForCreation() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Month',
      selectableDayPredicate: (day) => day.day == 1,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: expenseColor,
              onPrimary: Colors.white,
              onSurface: headerTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newMonth = DateTime(picked.year, picked.month, 1);
      setState(() {
        selectedMonth = newMonth;
      });
      await _loadMonthlyBudget(newMonth);
    }
  }

  void _openBudgetSheet({bool isEdit = false}) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        isEdit ? "Edit Budget" : "Create New Budget",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: expenseColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          await _selectMonthForCreation();
                          setModalState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: primaryColor.withOpacity(0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat.yMMMM().format(selectedMonth),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: expenseColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        initialValue: totalMonthlyBudget == 0
                            ? ''
                            : totalMonthlyBudget.toStringAsFixed(0),
                        decoration: InputDecoration(
                          labelText: 'Total Monthly Budget',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            totalMonthlyBudget = double.tryParse(val) ?? 0;
                          });
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          ...categories.map((cat) {
                            final categoryName = cat['name'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(child: Text(categoryName)),
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        prefixText: '₹ ',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      initialValue:
                                          categoryBudgets[categoryName] == 0
                                          ? ''
                                          : categoryBudgets[categoryName]
                                                ?.toStringAsFixed(0),
                                      onChanged: (val) {
                                        setState(() {
                                          categoryBudgets[categoryName] =
                                              double.tryParse(val) ?? 0;
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Others/Remaining Budget: ₹${othersBudget.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: othersBudget > 0 ? incomeColor : expenseColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: incomeColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _saveBudget,
                          child: Text(
                            "Save Budget",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: FloatingActionButton(
          backgroundColor: expenseColor,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _openBudgetSheet(),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Back Button
                Padding(
                  padding: const EdgeInsets.only(
                    top: 10.0,
                    left: 20,
                    right: 20,
                    bottom: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back,
                              color: headerTextColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Budget',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: headerTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Tab Bar
                TabBar(
                  labelColor: expenseColor,
                  unselectedLabelColor: bodyTextColor,
                  indicatorColor: expenseColor,
                  indicatorWeight: 3.0,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'OVERVIEW'),
                    Tab(text: 'HISTORY'),
                  ],
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      _PeriodicOverview(
                        selectedMonth: selectedMonth,
                        totalMonthlyBudget: totalMonthlyBudget,
                        othersBudget: othersBudget,
                        categoryBudgets: categoryBudgets,
                        categories: categories,
                        onEdit: () => _openBudgetSheet(isEdit: true),
                      ),
                      _OneTimeHistory(history: budgetHistory),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Tab View Widgets ---

class _PeriodicOverview extends StatelessWidget {
  final DateTime selectedMonth;
  final double totalMonthlyBudget;
  final double othersBudget;
  final Map<String, double> categoryBudgets;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onEdit;

  const _PeriodicOverview({
    required this.selectedMonth,
    required this.totalMonthlyBudget,
    required this.othersBudget,
    required this.categoryBudgets,
    required this.categories,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final budgetItems = categories.map((cat) {
      final categoryName = cat['name'];
      return {
        'name': categoryName,
        'amount': categoryBudgets[categoryName] ?? 0,
      };
    }).toList();

    if (othersBudget > 0) {
      budgetItems.add({'name': 'Others/Remaining', 'amount': othersBudget});
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget for ${DateFormat.yMMMM().format(DateTime.now())}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: headerTextColor,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Monthly Budget",
                  style: const TextStyle(fontSize: 16, color: bodyTextColor),
                ),
                Text(
                  "₹${totalMonthlyBudget.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: expenseColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Unallocated (Others/Remaining): ₹${othersBudget.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 15,
                    color: othersBudget >= 0 ? incomeColor : expenseColor,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: incomeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text(
                      "Edit Budget",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Category Breakdown',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: headerTextColor,
            ),
          ),
          const SizedBox(height: 15),
          if (totalMonthlyBudget == 0)
            const Center(
              child: Text(
                "Tap '+' to create your first budget!",
                style: TextStyle(fontSize: 16, color: bodyTextColor),
              ),
            )
          else
            ...budgetItems.where((item) => item['amount'] > 0).map((item) {
              final amount = item['amount'] as double;
              final name = item['name'] as String;
              final percent = (amount / totalMonthlyBudget) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.grey[300],
                      color: name == 'Others/Remaining'
                          ? incomeColor
                          : expenseColor,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: bodyTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _OneTimeHistory extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const _OneTimeHistory({required this.history});

  @override
  Widget build(BuildContext context) {
    return history.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 60, color: bodyTextColor),
                const SizedBox(height: 10),
                const Text(
                  "No past budget history found.",
                  style: TextStyle(fontSize: 16, color: bodyTextColor),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final budget = history[index];
              final date = DateFormat('yyyy-MM').parse(budget['month']);
              final monthYear = DateFormat.yMMMM().format(date);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Icon(Icons.calendar_month, color: expenseColor),
                  ),
                  title: Text(
                    monthYear,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Total Budget: ₹${(budget['total_budget'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(color: bodyTextColor),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: expenseColor,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing budget for $monthYear')),
                    );
                  },
                ),
              );
            },
          );
  }
}
