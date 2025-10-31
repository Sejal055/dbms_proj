import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingPaymentsPage extends StatefulWidget {
  const PendingPaymentsPage({super.key});

  @override
  State<PendingPaymentsPage> createState() => _PendingPaymentsPageState();
}

class _PendingPaymentsPageState extends State<PendingPaymentsPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('pending_payments')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending or future payments 🎉',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Untitled';
              final amount = (data['amount'] ?? 0).toDouble();
              final category = data['category'] ?? 'Uncategorized';
              final type = data['type'] ?? 'Pay';
              final status = data['status'] ?? 'pending';
              
              // --- MODIFICATION 1: Read all required fields ---
              final payTo = data['pay_to'] ?? '';
              // Safely read the phone number (it might be null)
              final phoneNumber = data['phone_number'] as String?;

              // Handle Timestamps safely
              DateTime? createdAt;
              if (data['timestamp'] is Timestamp) {
                createdAt = (data['timestamp'] as Timestamp).toDate();
              }

              DateTime? scheduledFor;
              if (data['scheduled_for'] is Timestamp) {
                scheduledFor = (data['scheduled_for'] as Timestamp).toDate();
              }

              // Choose best date to display
              String dateText;
              Color dateColor;
              if (scheduledFor != null) {
                dateText =
                    'Scheduled for: ${scheduledFor.toLocal().toString().split(' ')[0]}';
                dateColor = Colors.deepPurple;
              } else if (createdAt != null) {
                dateText =
                    'Added on: ${createdAt.toLocal().toString().split(' ')[0]}';
                dateColor = Colors.grey;
              } else {
                dateText = 'Date unavailable';
                dateColor = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: type == 'Pay'
                          ? [Colors.red.shade50, Colors.red.shade100]
                          : [Colors.green.shade50, Colors.green.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Title + Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 🔹 Category + Type
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            type == 'Pay' ? 'To Pay' : 'To Receive',
                            style: TextStyle(
                              color: type == 'Pay'
                                  ? Colors.redAccent
                                  : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 🔹 Date + Pay to / Receive from name
                      if (payTo.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                type == 'Pay'
                                    ? 'Pay to: $payTo'
                                    : 'Receive from: $payTo',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateText,
                              style: TextStyle(color: dateColor, fontSize: 13),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // 🔹 Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Pay button (only for "Pay" type)
                          if (type == 'Pay')
                            ElevatedButton.icon(
                              // --- MODIFICATION 2: Call the new function ---
                              onPressed: () async {
                                // Pass all the required data
                                await _openGooglePay(
                                  phoneNumber,
                                  payTo,
                                  amount,
                                );
                              },
                              icon: const Icon(Icons.account_balance_wallet),
                              label: const Text('Pay'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),

                          // Mark as Paid / Received
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _markAsDone(doc.id, data);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              type == 'Pay'
                                  ? 'Mark as Paid'
                                  : 'Mark as Received',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- MODIFICATION 3: Added normalize function from AddExpensePopup ---
  String _normalizePhoneNumber(String phone) {
    String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (normalized.startsWith('0')) normalized = normalized.substring(1);
    if (!normalized.startsWith('91')) normalized = '91$normalized';
    return normalized;
  }

  // --- MODIFICATION 4: Replaced _openUpiPayment with logic from AddExpensePopup ---
  Future<void> _openGooglePay(
      String? phoneNumber, String payToName, double amount) async {
    try {
      Uri gpayUri;

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Contact was selected: Redirect to GPay with phone, name, and amount
        final normalizedPhone = _normalizePhoneNumber(phoneNumber);
        gpayUri = Uri.parse(
          'upi://pay?pa=$normalizedPhone@paytm&pn=$payToName&am=$amount&cu=INR',
        );
      } else {
        // Manual entry: Redirect to GPay homepage
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
        } else {
          throw 'Could not launch GPay or Play Store.';
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

  // 🔹 Function to move payment to History (Unchanged)
  Future<void> _markAsDone(String docId, Map<String, dynamic> data) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);

      final bool isPay = data['type'] == 'Pay';

      // Save to 'history' collection
      await userRef.collection('history').add({
        'expense_name': data['title'],
        'amount': data['amount'],
        'category': data['category'],
        'expense_type': isPay ? 'Expense' : 'Income',
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'Pending',
      });

      // Optionally also store in 'expenses'
      await userRef.collection('expenses').add({
        'expense_name': data['title'],
        'amount': data['amount'],
        'category': data['category'],
        'expense_type': isPay ? 'Expense' : 'Income',
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'Pending',
      });

      // Delete from pending list
      await userRef.collection('pending_payments').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPay
                  ? 'Payment marked as Paid ✅ and moved to history'
                  : 'Payment marked as Received ✅ and moved to history',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving to history: $e')));
      }
    }
  }
}