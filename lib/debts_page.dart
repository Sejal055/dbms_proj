import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer'; // For log function

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
    if (user == null) {
      log('Firestore Error: User is not signed in. Cannot load debts.');
      return;
    }
    
    // --- DATABASE STRUCTURE CHECK ---
    // Confirmed path: users/{user.email}/TAPT/{debt_id}
    final debtCollectionPath = 'users/${user.email}/TAPT';
    log('Attempting to load debts from: $debtCollectionPath');

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.email)
          .collection('TAPT')
          .orderBy('createdAt', descending: true)
          .get();

      final loadedDebts = querySnapshot.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'type': d['type'] == 'lent' ? DebtType.lent : DebtType.borrowed,
          'person': d['person'],
          // Ensure amount is handled correctly
          'amount': (d['amount'] as num).toDouble(), 
          'dueDate': d['dueDate'] != null ? (d['dueDate'] as Timestamp).toDate() : null,
          'status': d['status'] == 'active' ? DebtStatus.active : DebtStatus.closed,
        };
      }).toList();

      setState(() => _debts = loadedDebts);
      log('Successfully loaded ${loadedDebts.length} debts.');
    } catch (e) {
      log('Firestore Load Error: $e');
      // Show error message to user (optional but helpful)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data. Check console for error.')),
        );
      }
    }
  }

  void _resetModalFields() {
    _personController.clear();
    _amountController.clear();
    _selectedDueDate = null;
    _currentDebtType = DebtType.lent;
  }

  Future<void> _saveDebtToFirestore(Map<String, dynamic> debt) async {
    final user = _auth.currentUser;
    if (user == null) {
      log('Firestore Error: User is not signed in. Cannot save debt.');
      return;
    }
    
    try {
      // --- SAVING DATA TO FIREBASE ---
      final docRef = await _firestore
          .collection('users')
          .doc(user.email)
          .collection('TAPT')
          .add({
        'type': debt['type'] == DebtType.lent ? 'lent' : 'borrowed',
        'person': debt['person'],
        // CRITICAL FIX: Ensure amount is saved as a number type
        'amount': debt['amount'], 
        'dueDate': debt['dueDate'],
        'status': 'active', // New debts are always 'active'
        'createdAt': FieldValue.serverTimestamp(),
      });
      log('Debt saved successfully with ID: ${docRef.id}');
      
    } catch (e) {
      log('Firestore Save Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data. Check internet/permissions.')),
        );
      }
    }
  }

  Future<void> _updateDebtStatus(Map<String, dynamic> debt, DebtStatus newStatus) async {
    final user = _auth.currentUser;
    if (user == null || debt['id'] == null) {
      log('Firestore Error: Cannot update debt status (User: $user, Debt ID: ${debt['id']})');
      _loadDebts(); // Try to refresh if ID is missing
      return;
    }

    // Optimistic UI update
    setState(() {
      final index = _debts.indexWhere((d) => d['id'] == debt['id']); 
      if (index != -1) {
        _debts[index]['status'] = newStatus;
      }
    });
    
    try {
      // Update Firestore record
      await _firestore
          .collection('users')
          .doc(user.email)
          .collection('TAPT')
          .doc(debt['id'])
          .update({'status': newStatus == DebtStatus.active ? 'active' : 'closed'});
      log('Debt status updated to ${newStatus.name} for ID: ${debt['id']}');

    } catch (e) {
      log('Firestore Update Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status.')),
        );
        _loadDebts(); // Revert UI changes by reloading the correct data
      }
    }
  }

  void _addDebt() async {
    final person = _personController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (person.isNotEmpty && amount > 0) {
      final newDebt = {
        'type': _currentDebtType,
        'person': person,
        'amount': amount,
        'dueDate': _selectedDueDate,
        'status': DebtStatus.active,
      };

      Navigator.pop(context);
      _resetModalFields();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording debt/IOU for $person...')),
      );

      await _saveDebtToFirestore(newDebt);
      await _loadDebts(); // Reload to get the new data and Firestore ID

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debt added for $person successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name and amount.')),
      );
    }
  }

  Future<void> _selectDueDate(BuildContext context, StateSetter setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: appBarColor,
            colorScheme: const ColorScheme.light(primary: appBarColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setModalState(() => _selectedDueDate = picked);
    }
  }

  void _openAddDebtSheet() {
    _resetModalFields();
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => SingleChildScrollView( 
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: 20, 
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    ),
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
                              onTap: (type) => setModalState(() => _currentDebtType = type),
                            ),
                            _TypeButton(
                              label: 'I Borrowed Money',
                              type: DebtType.borrowed,
                              currentType: _currentDebtType,
                              color: expenseColor,
                              onTap: (type) => setModalState(() => _currentDebtType = type),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ], 
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _currentDebtType == DebtType.lent ? incomeColor : expenseColor,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount (₹)',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _currentDebtType == DebtType.lent ? incomeColor : expenseColor,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _currentDebtType == DebtType.lent ? incomeColor : expenseColor,
                                width: 3,
                              ),
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
                            prefixIcon: const Icon(Icons.person_outline, color: bodyTextColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.grey, width: 1),
                          ),
                          leading: Icon(Icons.calendar_today,
                              color: _currentDebtType == DebtType.lent ? incomeColor : expenseColor),
                          title: Text(
                            _selectedDueDate == null
                                ? 'Select Due Date (Optional)'
                                : 'Due Date: ${DateFormat('dd MMM yyyy').format(_selectedDueDate!)}',
                            style: TextStyle(
                              color: _selectedDueDate == null ? bodyTextColor : headerTextColor,
                            ),
                          ),
                          trailing: const Icon(Icons.edit, color: bodyTextColor),
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
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentDebtType == DebtType.lent ? incomeColor : expenseColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _addDebt,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDebts = _debts.where((d) => d['status'] == DebtStatus.active).toList();
    final closedDebts = _debts.where((d) => d['status'] == DebtStatus.closed).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: appBarColor,
          elevation: 0,
          title: const Text('Debts',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            top: false,
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
        child: SingleChildScrollView(
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
        ),
      );
    }

    final sortedDebts = debts.toList();
    if (status == DebtStatus.active) {
      sortedDebts.sort((a, b) {
        final aDue = a['dueDate'] as DateTime?;
        final bDue = b['dueDate'] as DateTime?;
        final now = DateTime.now();
        final aIsOverdue = aDue != null && aDue.isBefore(now);
        final bIsOverdue = bDue != null && bDue.isBefore(now);

        if (aIsOverdue && !bIsOverdue) return -1; 
        if (!aIsOverdue && bIsOverdue) return 1; 

        if (aDue == null && bDue != null) return 1; 
        if (bDue == null && aDue != null) return -1; 
        if (aDue == null && bDue == null) return 0; 

        return aDue!.compareTo(bDue!); 
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
              color: isOverdue ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isOverdue ? Colors.red.withOpacity(0.2) : Colors.black26.withOpacity(0.1),
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
                    fontSize: 16, fontWeight: FontWeight.w600, color: headerTextColor),
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
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (status == DebtStatus.active)
                    TextButton.icon(
                      icon: Icon(Icons.check_circle, size: 20, color: amountColor),
                      label: Text(
                        'Mark Paid',
                        style: TextStyle(color: amountColor, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => onUpdateStatus(debt, DebtStatus.closed),
                    ),
                  if (status == DebtStatus.closed)
                    TextButton.icon(
                      icon: const Icon(Icons.undo, size: 20, color: bodyTextColor),
                      label: const Text(
                        'Re-open',
                        style: TextStyle(color: bodyTextColor, fontWeight: FontWeight.w600),
                      ),
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