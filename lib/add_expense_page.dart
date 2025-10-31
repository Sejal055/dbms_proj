import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/low_budget_notification.dart';

class AddExpensePopup extends StatefulWidget {
  final VoidCallback onCancel;
  const AddExpensePopup({required this.onCancel, super.key});

  @override
  State<AddExpensePopup> createState() => _AddExpensePopupState();
}

class _AddExpensePopupState extends State<AddExpensePopup> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController payToController = TextEditingController();

  DateTime? selectedDate;
  String? selectedCategory;
  String? selectedFrequency;
  String type = "Pay"; // Pay / Receive
  String currentTab = "Expense"; // Expense / Pending / Future / Recurring

  bool isIncome = false;
  bool _isSaving = false;
  bool isLoadingCategories = true;

  // Contact selection
  bool useContactForPayTo = false;
  
  // --- MODIFICATION 1: Specify the Contact type ---
  // Change 'Contact' to 'flutter_contacts.Contact' to be explicit
  fc.Contact? selectedContact;
  String? selectedPhoneNumber;

  final List<String> baseCategories = [
    'Food & Dining',
    'Transportation',
    'Education',
    'Entertainment',
    'Utilities',
    'Others',
  ];
  List<String> allCategories = [];

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadCategories();
  }

  Future<void> _initNotifications() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'payment_reminder_channel',
        channelName: 'Payment Reminders',
        channelDescription: 'Reminders for upcoming or pending payments',
        importance: NotificationImportance.Max,
      ),
    ]);
    if (!(await AwesomeNotifications().isNotificationAllowed())) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .get();

      final userCategories = snapshot.docs
          .map((doc) => doc['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      setState(() {
        allCategories = [...baseCategories, ...userCategories.toSet()];
        isLoadingCategories = false;
      });
    } catch (_) {
      setState(() {
        allCategories = baseCategories;
        isLoadingCategories = false;
      });
    }
  }

  // --- MODIFICATION 2: Update the contact picker method ---
 Future<void> _pickContactForPayTo() async {
  // Your permission_handler code is fine
  var permissionStatus = await Permission.contacts.status;
  if (!permissionStatus.isGranted) {
    permissionStatus = await Permission.contacts.request();
    if (!permissionStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
      }
      return;
    }
  }

  try {
    // --- UPDATE THIS SECTION ---
    
    // Add 'fc.' prefix to FlutterContacts and Contact
    final fc.Contact? contact = await fc.FlutterContacts.openExternalPick();

    if (contact != null) {
      String? phoneNumber;
      if (contact.phones.isNotEmpty) {
        phoneNumber = contact.phones.first.number;
      }

      setState(() {
        selectedContact = contact; // This is now an 'fc.Contact' type
        selectedPhoneNumber = phoneNumber;
        payToController.text = contact.displayName;
        useContactForPayTo = true;
      });
    }
    // --- END UPDATE ---
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting contact: $e')),
      );
    }
  }
}

  String _normalizePhoneNumber(String phone) {
    String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (normalized.startsWith('0')) normalized = normalized.substring(1);
    if (!normalized.startsWith('91')) normalized = '91$normalized';
    return normalized;
  }

  Future<void> _openGooglePay(String? phoneNumber, double amount) async {
    try {
      Uri gpayUri;
      
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Redirect to GPay with phone number and amount
        final normalizedPhone = _normalizePhoneNumber(phoneNumber);
        gpayUri = Uri.parse(
          'upi://pay?pa=$normalizedPhone@paytm&pn=${payToController.text}&am=$amount&cu=INR',
        );
      } else {
        // Redirect to GPay homepage
        gpayUri = Uri.parse('tez://');
      }

      if (await canLaunchUrl(gpayUri)) {
        await launchUrl(gpayUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Play Store
        final playStoreUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.google.android.apps.nbu.paisa.user',
        );
        if (await canLaunchUrl(playStoreUri)) {
          await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Pay: $e')),
        );
      }
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a category")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final name = nameController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
    final now = DateTime.now();

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      if (currentTab == "Expense") {
        await userRef.collection('expenses').add({
          'expense_name': name,
          'expense_amount': amount,
          'category': selectedCategory,
          'expense_type': isIncome ? 'Income' : 'Expense',
          'timestamp': FieldValue.serverTimestamp(),
        });
        await NotificationService().checkBudgetAndNotify();
      }

      if (currentTab == "Pending") {
        await userRef.collection('pending_payments').add({
          'title': name,
          'amount': amount,
          'category': selectedCategory,
          'type': type,
          'pay_to': payToController.text.trim(),
          'phone_number': selectedPhoneNumber,
          'has_contact': useContactForPayTo,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (currentTab == "Future") {
        if (selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Select a future date")),
          );
          setState(() => _isSaving = false);
          return;
        }

        await userRef.collection('pending_payments').add({
          'title': name,
          'amount': amount,
          'category': selectedCategory,
          'type': type,
          'pay_to': payToController.text.trim(),
          'phone_number': selectedPhoneNumber,
          'has_contact': useContactForPayTo,
          'scheduled_for': selectedDate,
          'status': 'scheduled',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Reminder notification 2 days before
        final reminderDate = selectedDate!.subtract(const Duration(days: 2));

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: name.hashCode,
            channelKey: 'payment_reminder_channel',
            title: 'Upcoming payment reminder',
            body:
                'Your $name of ₹$amount is due on ${DateFormat('dd MMM').format(selectedDate!)}',
          ),
          schedule: NotificationCalendar.fromDate(date: reminderDate),
        );

        await userRef.collection('notifications').add({
          'title': 'Upcoming payment',
          'body':
              'Your $name of ₹$amount is due on ${DateFormat('dd MMM').format(selectedDate!)}',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (currentTab == "Recurring") {
        if (selectedDate == null || selectedFrequency == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Select date and frequency")),
          );
          setState(() => _isSaving = false);
          return;
        }

        final nextDue = _calculateNextDue(selectedDate!, selectedFrequency!);

        await userRef.collection('recurring_payments').add({
          'title': name,
          'amount': amount,
          'category': selectedCategory,
          'type': type,
          'frequency': selectedFrequency,
          'start_date': selectedDate,
          'next_due': nextDue,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Schedule local notification 2 days before due
        final reminderDate = nextDue.subtract(const Duration(days: 2));
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: name.hashCode,
            channelKey: 'payment_reminder_channel',
            title: 'Upcoming recurring payment',
            body:
                'Your recurring $name of ₹$amount is due on ${DateFormat('dd MMM').format(nextDue)}',
          ),
          schedule: NotificationCalendar.fromDate(date: reminderDate),
        );

        // Store same reminder in Firestore
        await userRef.collection('notifications').add({
          'title': 'Upcoming recurring payment',
          'body':
              'Your recurring $name of ₹$amount is due on ${DateFormat('dd MMM').format(nextDue)}',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      Navigator.of(context).pop();
      nameController.clear();
      amountController.clear();
      payToController.clear();
      selectedDate = null;
      selectedCategory = null;
      selectedFrequency = null;
      selectedContact = null;
      selectedPhoneNumber = null;
      useContactForPayTo = false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  DateTime _calculateNextDue(DateTime base, String freq) {
    switch (freq) {
      case 'Weekly':
        return base.add(const Duration(days: 7));
      case 'Monthly':
        return DateTime(base.year, base.month + 1, base.day);
      case 'Yearly':
        return DateTime(base.year + 1, base.month, base.day);
      default:
        return base;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ["Expense", "Pending", "Future", "Recurring"];
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F0FF), Color(0xFFF8EFFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                  ),
                ),
                const SizedBox(height: 8),
                // Tabs
                Wrap(
                  spacing: 8,
                  children: tabs.map((tab) {
                    final selected = currentTab == tab;
                    return ChoiceChip(
                      label: Text(tab),
                      selected: selected,
                      onSelected: (_) => setState(() => currentTab = tab),
                      selectedColor: const Color(0xFFD6A8F8),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Pay/Receive toggle for Pending/Future/Recurring
                if (currentTab != "Expense")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Pay'),
                        selected: type == "Pay",
                        onSelected: (_) => setState(() => type = "Pay"),
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(
                          color: type == "Pay" ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Receive'),
                        selected: type == "Receive",
                        onSelected: (_) => setState(() => type = "Receive"),
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: type == "Receive" ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: nameController,
                  validator: (v) => (v == null || v.isEmpty) ? "Enter name" : null,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Amount
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty) ? "Enter amount" : null,
                  decoration: const InputDecoration(
                    labelText: "Amount (₹)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Pay To / Receive From (only for Pending or Future)
                if (currentTab == "Pending" || currentTab == "Future") ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: payToController,
                          validator: (v) => (v == null || v.isEmpty)
                              ? (type == "Pay"
                                  ? "Enter name of person to pay"
                                  : "Enter name of person to receive from")
                              : null,
                          decoration: InputDecoration(
                            labelText: type == "Pay" ? "Pay to" : "Receive from",
                            border: const OutlineInputBorder(),
                            suffixIcon: selectedContact != null
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.contacts, color: Colors.blue),
                        tooltip: 'Choose from contacts',
                        onPressed: _pickContactForPayTo,
                      ),
                    ],
                  ),
                  if (selectedContact != null && selectedPhoneNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedPhoneNumber!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Icon(Icons.payment, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            const Text(
                              'GPay Ready',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                // Category
                isLoadingCategories
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: allCategories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedCategory = v),
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null) ? "Select category" : null,
                      ),
                const SizedBox(height: 12),

                // Date & Frequency (for Future / Recurring)
                if (currentTab == "Future" || currentTab == "Recurring") ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            selectedDate == null
                                ? "Select Date"
                                : DateFormat('dd MMM yyyy').format(selectedDate!),
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                    ],
                  ),
                  if (currentTab == "Recurring") ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      items: ['Weekly', 'Monthly', 'Yearly']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedFrequency = v),
                      decoration: const InputDecoration(
                        labelText: "Frequency",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveData,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Save",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
  }
}