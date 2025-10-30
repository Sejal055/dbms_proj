import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Theme Colors ---
const Color primaryColor = Color(0xFFD0E3FF);
const Color secondaryColor = Color(0xFFE9D5F8);
const Color incomeColor = Color(0xFF5A96F0);
const Color expenseColor = Color(0xFFB47BE8);
const Color headerTextColor = Colors.black87;
const Color bodyTextColor = Colors.black54;
const Color appBarColor = Color(0xFF7BAFFC);

// --- Debt Data Model ---
enum DebtType { lent, borrowed }
enum DebtStatus { active, closed }

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _debts = [];

  DebtType _currentDebtType = DebtType.lent;
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['debts'] != null) {
        setState(() {
          _debts = List<Map<String, dynamic>>.from((data['debts'] as List).map((d) {
            return {
              'type': (d['type'] ?? 'lent') == 'lent' ? DebtType.lent : DebtType.borrowed,
              'person': d['person'] ?? '',
              'amount': (d['amount'] is num)
                  ? (d['amount'] as num).toDouble()
                  : double.tryParse('${d['amount']}') ?? 0.0,
              'dueDate': d['dueDate'] != null
                  ? (d['dueDate'] is Timestamp
                      ? (d['dueDate'] as Timestamp).toDate()
                      : (d['dueDate'] is DateTime ? d['dueDate'] as DateTime : null))
                  : null,
              'status':
                  (d['status'] ?? 'active') == 'active' ? DebtStatus.active : DebtStatus.closed,
            };
          }));
        });
      } else {
        setState(() => _debts = []);
      }
    } catch (e) {
      // print('Error loading debts: $e');
    }
  }

  void _resetModalFields() {
    _personController.clear();
    _amountController.clear();
    _selectedDueDate = null;
    _currentDebtType = DebtType.lent;
  }

  Future<void> _saveDebtsToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final debtData = _debts.map((d) {
      return {
        'type': d['type'] == DebtType.lent ? 'lent' : 'borrowed',
        'person': d['person'],
        'amount': d['amount'],
        'dueDate':
            d['dueDate'] != null ? Timestamp.fromDate(d['dueDate'] as DateTime) : null,
        'status': d['status'] == DebtStatus.active ? 'active' : 'closed',
      };
    }).toList();

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({'debts': debtData}, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save debts. Please try again.')),
        );
      }
    }
  }

  void _addDebt() {
    final person = _personController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (person.isNotEmpty && amount > 0) {
      setState(() {
        _debts.add({
          'type': _currentDebtType,
          'person': person,
          'amount': amount,
          'dueDate': _selectedDueDate,
          'status': DebtStatus.active,
        });
      });

      _saveDebtsToFirestore().then((_) {
        if (mounted) {
          Navigator.pop(context);
          _resetModalFields();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debt added for $person')),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name and amount.')),
      );
    }
  }

  void _updateDebtStatus(Map<String, dynamic> debt, DebtStatus newStatus) {
    setState(() {
      final originalIndex = _debts.indexOf(debt);
      if (originalIndex != -1) {
        _debts[originalIndex]['status'] = newStatus;
      }
    });
    _saveDebtsToFirestore();
  }

  Future<void> _selectDueDate(
      BuildContext context, StateSetter setModalState) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setModalState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _openAddDebtSheet() {
    _resetModalFields();
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, sheetScrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    return SingleChildScrollView(
                      controller: sheetScrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                            "Record a Debt/IOU",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: headerTextColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _TypeButton(
                                label: 'I Lent Money',
                                type: DebtType.lent,
                                currentType: _currentDebtType,
                                color: incomeColor,
                                onTap: (type) =>
                                    setModalState(() => _currentDebtType = type),
                              ),
                              _TypeButton(
                                label: 'I Borrowed Money',
                                type: DebtType.borrowed,
                                currentType: _currentDebtType,
                                color: expenseColor,
                                onTap: (type) =>
                                    setModalState(() => _currentDebtType = type),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                            ],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _currentDebtType == DebtType.lent
                                  ? incomeColor
                                  : expenseColor,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount (₹)',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _currentDebtType == DebtType.lent
                                        ? incomeColor
                                        : expenseColor,
                                    width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _currentDebtType == DebtType.lent
                                        ? incomeColor
                                        : expenseColor,
                                    width: 3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _personController,
                            decoration: InputDecoration(
                              labelText: _currentDebtType == DebtType.lent
                                  ? 'Lent to (Person/Reason)'
                                  : 'Borrowed from (Person/Reason)',
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: bodyTextColor),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side:
                                  const BorderSide(color: Colors.grey, width: 1),
                            ),
                            leading: Icon(Icons.calendar_today,
                                color: _currentDebtType == DebtType.lent
                                    ? incomeColor
                                    : expenseColor),
                            title: Text(
                              _selectedDueDate == null
                                  ? 'Select Due Date (Optional)'
                                  : 'Due Date: ${DateFormat('dd MMM yyyy').format(_selectedDueDate!)}',
                              style: TextStyle(
                                  color: _selectedDueDate == null
                                      ? bodyTextColor
                                      : headerTextColor),
                            ),
                            trailing:
                                const Icon(Icons.edit, color: bodyTextColor),
                            onTap: () => _selectDueDate(context, setModalState),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: Text(
                                _currentDebtType == DebtType.lent
                                    ? "Record IOU (Lent)"
                                    : "Record Debt (Borrowed)",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentDebtType == DebtType.lent
                                    ? incomeColor
                                    : expenseColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _addDebt,
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom + 8),
                        ],
                      ),
                    );
                  },
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
    final activeDebts =
        _debts.where((d) => d['status'] == DebtStatus.active).toList();
    final closedDebts =
        _debts.where((d) => d['status'] == DebtStatus.closed).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: appBarColor,
          elevation: 0,
          title: const Text('Debts',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicatorColor: Colors.white,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'ACTIVE'),
                Tab(text: 'CLOSED'),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: incomeColor,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: _openAddDebtSheet,
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
            top: true, // ✅ Fix: Allow top padding under AppBar
            child: TabBarView(
              children: [
                _DebtList(
                  debts: activeDebts,
                  status: DebtStatus.active,
                  onUpdateStatus: _updateDebtStatus,
                ),
                _DebtList(
                  debts: closedDebts,
                  status: DebtStatus.closed,
                  onUpdateStatus: _updateDebtStatus,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Type Button ---
class _TypeButton extends StatelessWidget {
  final String label;
  final DebtType type;
  final DebtType currentType;
  final Color color;
  final ValueChanged<DebtType> onTap;

  const _TypeButton({
    required this.label,
    required this.type,
    required this.currentType,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == currentType;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.40,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              type == DebtType.lent ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : bodyTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Debt List ---
class _DebtList extends StatelessWidget {
  final List<Map<String, dynamic>> debts;
  final DebtStatus status;
  final Function(Map<String, dynamic>, DebtStatus) onUpdateStatus;

  const _DebtList({
    required this.debts,
    required this.status,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == DebtStatus.active ? Icons.handshake : Icons.done_all,
              size: 60,
              color: bodyTextColor,
            ),
            const SizedBox(height: 10),
            Text(
              status == DebtStatus.active
                  ? "Track what you lent and borrowed here."
                  : "Completed debts and IOUs will show up here.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: bodyTextColor),
            ),
          ],
        ),
      );
    }

    final sortedDebts = debts.toList();
    if (status == DebtStatus.active) {
      sortedDebts.sort((a, b) {
        final aDue = a['dueDate'] as DateTime?;
        final bDue = b['dueDate'] as DateTime?;
        final aIsOverdue = aDue != null && aDue.isBefore(DateTime.now());
        final bIsOverdue = bDue != null && bDue.isBefore(DateTime.now());
        if (aIsOverdue && !bIsOverdue) return -1;
        if (!aIsOverdue && bIsOverdue) return 1;
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      });
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedDebts.length,
      itemBuilder: (context, index) {
        final debt = sortedDebts[index];
        final isLent = debt['type'] == DebtType.lent;
        final amountColor = isLent ? incomeColor : expenseColor;
        final dueDate = debt['dueDate'] as DateTime?;
        final isOverdue =
            dueDate != null && dueDate.isBefore(DateTime.now()) && status == DebtStatus.active;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  isOverdue ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isOverdue
                    ? Colors.red.withOpacity(0.2)
                    : Colors.black26.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isLent ? 'LENT' : 'BORROWED',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isLent ? incomeColor : expenseColor,
                    ),
                  ),
                  Text(
                    "₹${NumberFormat('#,##0.00').format(debt['amount'])}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                debt['person'],
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: headerTextColor),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.error_outline : Icons.calendar_today,
                        size: 16,
                        color: isOverdue ? Colors.red : bodyTextColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dueDate == null
                            ? 'No Due Date'
                            : 'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isOverdue ? Colors.red : bodyTextColor,
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (status == DebtStatus.active)
                    TextButton.icon(
                      icon:
                          const Icon(Icons.check_circle, size: 20, color: incomeColor),
                      label: const Text('Mark Paid'),
                      onPressed: () => onUpdateStatus(debt, DebtStatus.closed),
                    ),
                  if (status == DebtStatus.closed)
                    TextButton.icon(
                      icon:
                          const Icon(Icons.undo, size: 20, color: bodyTextColor),
                      label: const Text('Re-open'),
                      onPressed: () => onUpdateStatus(debt, DebtStatus.active),
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
