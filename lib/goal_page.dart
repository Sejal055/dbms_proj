// GoalPage.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Theme Colors (Keep consistent with BudgetPage) ---
const Color primaryColor = Color(0xFFD0E3FF); // Light blue
const Color secondaryColor = Color(0xFFE9D5F8); // Light purple
const Color incomeColor = Color(0xFF5A96F0); // Main action blue
const Color expenseColor = Color(0xFFB47BE8); // Main header/accent purple
const Color headerTextColor = Colors.black87;
const Color bodyTextColor = Colors.black54;
const Color progressFill = Color(0xFF5A96F0);

// --- Goal Data Model ---
enum GoalStatus { active, paused, reached }

// Predefined Goal Options for the Bottom Sheet
final List<Map<String, dynamic>> predefinedGoals = [
  {'name': 'New Vehicle', 'icon': Icons.directions_car, 'color': Colors.blue},
  {'name': 'New Home', 'icon': Icons.home, 'color': Colors.orange},
  {'name': 'Holiday Trip', 'icon': Icons.flight_takeoff, 'color': Colors.green},
  {'name': 'Education', 'icon': Icons.school, 'color': Colors.blueAccent},
  {'name': 'Emergency Fund', 'icon': Icons.local_hospital, 'color': Colors.purple},
  {'name': 'Health Care', 'icon': Icons.medical_services, 'color': Colors.red},
  {'name': 'Party', 'icon': Icons.celebration, 'color': Colors.amber},
  {'name': 'Kids Spoiling', 'icon': Icons.child_care, 'color': Colors.pinkAccent},
];

/// Helper function that can be called from your Budget page when you compute leftover monthly budget.
/// Usage (from your Budget logic):
/// await transferLeftoverToGoals(userId, leftoverAmount);
///
/// Behavior:
/// - Fetches active goals for the user.
/// - Distributes leftover equally among all active goals (if any).
/// - Updates each goal's current_amount and status (mark reached if target met).
/// - Decrements users/{userId}.amount_in_account by the total transferred.
/// - If no active goals exist, leaves leftover in the user's account.
Future<void> transferLeftoverToGoals(String userId, double leftoverAmount) async {
  if (leftoverAmount <= 0) return;

  final goalsSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('goals')
      .where('status', isEqualTo: 'active')
      .get();

  final activeDocs = goalsSnap.docs;
  if (activeDocs.isEmpty) {
    // No active goals: do nothing to goals (leftover remains in account)
    return;
  }

  final perGoal = leftoverAmount / activeDocs.length;
  final batch = FirebaseFirestore.instance.batch();

  double totalTransferred = 0.0;

  for (var doc in activeDocs) {
    final data = doc.data();
    final target = (data['target_amount'] ?? 0).toDouble();
    final current = (data['current_amount'] ?? 0).toDouble();
    final newCurrent = current + perGoal;
    totalTransferred += perGoal;

    final newStatus = newCurrent >= target ? 'reached' : 'active';

    batch.update(doc.reference, {
      'current_amount': newCurrent,
      'status': newStatus,
    });
  }

  // Decrement user's amount_in_account
  final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
  batch.update(userRef, {
    'amount_in_account': FieldValue.increment(-totalTransferred),
  });

  await batch.commit();
}

// --- Main Widget ---
class GoalPage extends StatefulWidget {
  const GoalPage({Key? key}) : super(key: key);

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> with SingleTickerProviderStateMixin {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Goals loaded from Firestore
  List<Map<String, dynamic>> _goals = [];

  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();
  final TextEditingController _currentAmountController = TextEditingController();
  String _selectedGoalName = '';
  IconData _selectedGoalIcon = Icons.stars;
  Color _selectedGoalColor = expenseColor;

  @override
  void initState() {
    super.initState();
    _fetchGoalsFromDB();
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  // --- Firestore CRUD Operations ---

  Future<void> _fetchGoalsFromDB() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('goals')
        .orderBy('timestamp', descending: true)
        .get();

    final goals = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'targetAmount': (data['target_amount'] ?? 0).toDouble(),
        'currentAmount': (data['current_amount'] ?? 0).toDouble(),
        'icon': data['icon'] != null ? IconData(data['icon'], fontFamily: 'MaterialIcons') : Icons.stars,
        'color': data['color'] != null
            ? // stored previously as string like '429083123' (Color.value.toString())
            Color(int.tryParse(data['color']) ?? expenseColor.value)
            : expenseColor,
        'status': data['status'] == 'active'
            ? GoalStatus.active
            : data['status'] == 'paused'
                ? GoalStatus.paused
                : GoalStatus.reached,
      };
    }).toList();

    setState(() {
      _goals = goals;
    });
  }

  Future<void> _saveNewGoal() async {
    final name = _goalNameController.text.isEmpty ? _selectedGoalName : _goalNameController.text;
    final targetAmount = double.tryParse(_goalAmountController.text) ?? 0.0;
    final currentAmount = double.tryParse(_currentAmountController.text) ?? 0.0;

    if (name.isNotEmpty && targetAmount > 0) {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('goals')
          .add({
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'icon': _selectedGoalIcon.codePoint,
        'color': _selectedGoalColor.value.toString(),
        'status': currentAmount >= targetAmount ? 'reached' : 'active',
        'timestamp': DateTime.now(),
      });

      setState(() {
        _goals.insert(0, {
          'id': docRef.id,
          'name': name,
          'targetAmount': targetAmount,
          'currentAmount': currentAmount,
          'icon': _selectedGoalIcon,
          'color': _selectedGoalColor,
          'status': currentAmount >= targetAmount ? GoalStatus.reached : GoalStatus.active,
        });
      });

      Navigator.pop(context);
      _resetModalFields();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name goal created!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name and target amount.')),
      );
    }
  }

  Future<void> _updateGoalStatus(Map<String, dynamic> goal, GoalStatus newStatus) async {
    final goalId = goal['id'];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .update({'status': newStatus.name});

    setState(() {
      final originalIndex = _goals.indexWhere((g) => g['id'] == goalId);
      if (originalIndex != -1) {
        _goals[originalIndex]['status'] = newStatus;
      }
    });
  }

  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final goalId = goal['id'];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId)
        .delete();

    setState(() {
      _goals.removeWhere((g) => g['id'] == goalId);
    });
  }

  void _resetModalFields() {
    _goalNameController.clear();
    _goalAmountController.clear();
    _currentAmountController.clear();
    _selectedGoalName = '';
    _selectedGoalIcon = Icons.stars;
    _selectedGoalColor = expenseColor;
  }

  void _openGoalSheet() {
    _resetModalFields(); // Clear previous state

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
                height: MediaQuery.of(context).size.height * 0.80,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
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
                      const Text(
                        "What are you saving for? 💸",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: expenseColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _goalNameController,
                        decoration: InputDecoration(
                          labelText: 'Your goal\'s name (or select below)',
                          prefixIcon: Icon(_selectedGoalIcon, color: _selectedGoalColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Some things people save for:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: bodyTextColor),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: predefinedGoals.length,
                        itemBuilder: (context, index) {
                          final goal = predefinedGoals[index];
                          final isSelected = _selectedGoalName == goal['name'] && _goalNameController.text.isEmpty;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _selectedGoalName = goal['name'];
                                _selectedGoalIcon = goal['icon'];
                                _selectedGoalColor = goal['color'];
                                _goalNameController.clear();
                              });
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: goal['color'].withOpacity(0.2),
                                  child: Icon(goal['icon'], color: goal['color'], size: 25),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  goal['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? expenseColor : bodyTextColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _goalAmountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'Target Amount (₹)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _currentAmountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'Current Savings (₹)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
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
                          onPressed: _saveNewGoal,
                          child: const Text(
                            "CREATE GOAL",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      )
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

  // --- ADD SAVINGS FEATURE ---
  Future<void> _showAddSavingsDialog(Map<String, dynamic> goal) async {
    final TextEditingController amtController = TextEditingController();
    final goalName = goal['name'] ?? 'Goal';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add Savings to "$goalName"'),
          content: TextField(
            controller: amtController,
            keyboardType: TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              hintText: 'Enter amount to add',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: incomeColor),
              onPressed: () async {
                final entered = double.tryParse(amtController.text);
                Navigator.pop(ctx);

                if (entered == null || entered <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
                  return;
                }

                await _addSavingsToGoal(goal, entered);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSavingsToGoal(Map<String, dynamic> goal, double amountToAdd) async {
    final goalId = goal['id'] as String;
    final goalRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId);
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Fetch fresh values to avoid race conditions
    final goalSnap = await goalRef.get();
    final userSnap = await userRef.get();

    if (!goalSnap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal not found.')));
      return;
    }

    final currentAmount = (goalSnap.data()?['current_amount'] ?? 0).toDouble();
    final targetAmount = (goalSnap.data()?['target_amount'] ?? 0).toDouble();
    final availableInAccount = (userSnap.data()?['amount_in_account'] ?? 0).toDouble();

    // If user's account doesn't have enough funds, still allow (but notify)
    if (availableInAccount < amountToAdd) {
      // Optionally: prevent the operation. But here we allow and set account to negative
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warning: insufficient balance in account; proceeding will make your account negative.')));
    }

    final newCurrent = currentAmount + amountToAdd;
    final newStatus = newCurrent >= targetAmount ? 'reached' : 'active';

    final batch = FirebaseFirestore.instance.batch();
    batch.update(goalRef, {
      'current_amount': newCurrent,
      'status': newStatus,
    });

    // decrement user's amount_in_account
    batch.update(userRef, {
      'amount_in_account': FieldValue.increment(-amountToAdd),
    });

    await batch.commit();

    // update local state
    setState(() {
      final index = _goals.indexWhere((g) => g['id'] == goalId);
      if (index != -1) {
        _goals[index]['currentAmount'] = newCurrent;
        _goals[index]['status'] = newStatus == 'reached' ? GoalStatus.reached : GoalStatus.active;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₹${amountToAdd.toStringAsFixed(0)} added to "${goal['name']}"')));
  }

  @override
  Widget build(BuildContext context) {
    final activeGoals = _goals.where((g) => g['status'] == GoalStatus.active).toList();
    final pausedGoals = _goals.where((g) => g['status'] == GoalStatus.paused).toList();
    final reachedGoals = _goals.where((g) => g['status'] == GoalStatus.reached).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Goals', style: TextStyle(color: headerTextColor, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: headerTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48.0),
            child: TabBar(
              labelColor: expenseColor,
              unselectedLabelColor: bodyTextColor,
              indicatorColor: expenseColor,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: 'ACTIVE'),
                Tab(text: 'PAUSED'),
                Tab(text: 'REACHED'),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: expenseColor,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: _openGoalSheet,
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
            bottom: false,
            child: TabBarView(
              children: [
                _GoalList(
                  goals: activeGoals,
                  status: GoalStatus.active,
                  onUpdateStatus: _updateGoalStatus,
                  onDeleteGoal: _deleteGoal,
                  onAddSavings: _showAddSavingsDialog,
                ),
                _GoalList(
                  goals: pausedGoals,
                  status: GoalStatus.paused,
                  onUpdateStatus: _updateGoalStatus,
                  onDeleteGoal: _deleteGoal,
                  onAddSavings: _showAddSavingsDialog,
                ),
                _GoalList(
                  goals: reachedGoals,
                  status: GoalStatus.reached,
                  onUpdateStatus: _updateGoalStatus,
                  onDeleteGoal: _deleteGoal,
                  onAddSavings: _showAddSavingsDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Goal List Widget ---
class _GoalList extends StatelessWidget {
  final List<Map<String, dynamic>> goals;
  final GoalStatus status;
  final Function(Map<String, dynamic>, GoalStatus) onUpdateStatus;
  final Function(Map<String, dynamic>) onDeleteGoal;
  final Function(Map<String, dynamic>) onAddSavings;

  const _GoalList({
    required this.goals,
    required this.status,
    required this.onUpdateStatus,
    required this.onDeleteGoal,
    required this.onAddSavings,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == GoalStatus.active ? Icons.track_changes :
              status == GoalStatus.paused ? Icons.pause_circle_outline : Icons.celebration,
              size: 60,
              color: bodyTextColor,
            ),
            const SizedBox(height: 10),
            Text(
              status == GoalStatus.active
                  ? "Start saving! Tap '+' to create your first goal."
                  : status == GoalStatus.paused
                      ? "No temporarily paused goals."
                      : "You haven't reached any goals yet. Keep going!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: bodyTextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        final target = goal['targetAmount'] as double;
        final current = goal['currentAmount'] as double;
        final progress = (target > 0) ? (current / target).clamp(0.0, 1.0) : 0.0;
        final remaining = (target - current).clamp(0.0, double.infinity);

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black26.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (goal['color'] as Color).withOpacity(0.1),
                    radius: 18,
                    child: Icon(goal['icon'] as IconData, size: 20, color: goal['color'] as Color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal['name'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDeleteGoal(goal),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Target: ₹${NumberFormat.compactSimpleCurrency(locale: 'en_IN', decimalDigits: 0).format(target)}",
                    style: const TextStyle(fontSize: 14, color: bodyTextColor),
                  ),
                  Text(
                    progress < 1.0 ? "Need: ₹${NumberFormat.compactSimpleCurrency(locale: 'en_IN', decimalDigits: 0).format(remaining)}" : "Reached!",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: progress < 1.0 ? expenseColor : incomeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: progressFill,
                minHeight: 10,
                // borderRadius is not a parameter on LinearProgressIndicator in Flutter stable.
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Saved: ₹${NumberFormat.compactSimpleCurrency(locale: 'en_IN', decimalDigits: 0).format(current)}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    "${(progress * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (status != GoalStatus.reached)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline, color: incomeColor),
                      label: const Text('Add Savings'),
                      onPressed: () => onAddSavings(goal),
                    ),
                    if (status == GoalStatus.active)
                      TextButton.icon(
                        icon: const Icon(Icons.pause, color: expenseColor),
                        label: const Text('Pause'),
                        onPressed: () => onUpdateStatus(goal, GoalStatus.paused),
                      ),
                    if (status == GoalStatus.paused)
                      TextButton.icon(
                        icon: const Icon(Icons.play_arrow, color: incomeColor),
                        label: const Text('Activate'),
                        onPressed: () => onUpdateStatus(goal, GoalStatus.active),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
