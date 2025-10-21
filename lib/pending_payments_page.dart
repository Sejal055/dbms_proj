import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingPaymentsPage extends StatefulWidget {
  const PendingPaymentsPage({super.key});

  @override
  State<PendingPaymentsPage> createState() => _PendingPaymentsPageState();
}

class _PendingPaymentsPageState extends State<PendingPaymentsPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'payment_reminder_channel',
          channelName: 'Payment Reminders',
          channelDescription: 'Reminders for pending payments',
          importance: NotificationImportance.Max,
        ),
      ],
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _scheduleReminder(String title, DateTime dateTime) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: title.hashCode,
        channelKey: 'payment_reminder_channel',
        title: 'Payment Reminder',
        body: 'Don’t forget to pay for $title 💸',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: dateTime),
    );
  }

  Future<void> _pickDateTimeAndSetReminder(
      BuildContext context, String title) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (dateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a future time')),
      );
      return;
    }

    await _scheduleReminder(title, dateTime);
    final formatted = DateFormat('dd MMM, hh:mm a').format(dateTime);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for $title at $formatted')),
    );
  }

  Future<void> _markAsPaid(
      BuildContext context, String docId, Map<String, dynamic> paymentData) async {
    if (user == null) return;

    try {
      // Move to history
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('history')
          .add({
        ...paymentData,
        'status': 'Paid',
        'paidOn': Timestamp.now(),
      });

      // Remove from pending
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('pending_payments')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment marked as paid ✅')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your payments.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Pending Payments")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('pending_payments')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending payments 🎉"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final payment = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: ListTile(
                  title: Text(payment['title'] ?? 'Unknown'),
                  trailing: Text("₹${payment['amount']}"),
                  isThreeLine: true,
                  contentPadding: const EdgeInsets.all(16),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (payment['friend_name'] != null)
                        Text("Request from: ${payment['friend_name']}"),
                      if (payment['due'] != null) Text(payment['due']),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final upiUrl =
                                  "upi://pay?pa=${payment['upi_id']}&pn=${Uri.encodeComponent(payment['title'])}&am=${payment['amount']}&cu=INR";
                              if (await canLaunchUrl(Uri.parse(upiUrl))) {
                                await launchUrl(Uri.parse(upiUrl));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Could not open payment app."),
                                  ),
                                );
                              }
                            },
                            child: const Text("Pay Now"),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () async {
                              await _pickDateTimeAndSetReminder(
                                  context, payment['title']);
                            },
                            child: const Text("Remind"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await _markAsPaid(context, doc.id, payment);
                            },
                            child: const Text("Mark as Paid"),
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
}
