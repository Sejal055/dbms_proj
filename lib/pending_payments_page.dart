import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';

class PendingPaymentsPage extends StatefulWidget {
  const PendingPaymentsPage({super.key});

  @override
  State<PendingPaymentsPage> createState() => _PendingPaymentsPageState();
}

class _PendingPaymentsPageState extends State<PendingPaymentsPage> {
  final List<Map<String, dynamic>> pendingPayments = [
    {
      'title': 'Library Fine',
      'due': 'Due in 2 days',
      'amount': 250,
      'upi_id': 'library@upi',
      'friend_name': null,
    },
    {
      'title': 'Mess Fee',
      'due': 'Due in 5 days',
      'amount': 3100,
      'upi_id': 'mess@upi',
      'friend_name': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use app icon
      [
        NotificationChannel(
          channelKey: 'payment_reminder_channel',
          channelName: 'Payment Reminders',
          channelDescription: 'Reminders for pending payments',
          importance: NotificationImportance.Max,
        ),
      ],
    );

    // Request permission if not granted
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Payments")),
      body: ListView.builder(
        itemCount: pendingPayments.length,
        itemBuilder: (context, idx) {
          final payment = pendingPayments[idx];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: ListTile(
              title: Text(payment['title']),
              trailing: Text("₹${payment['amount']}"),
              isThreeLine: true,
              contentPadding: const EdgeInsets.all(16),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (payment['friend_name'] != null)
                    Text("Request from: ${payment['friend_name']}"),
                  Text(payment['due']),
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
                                content:
                                    Text("Could not redirect to payment app."),
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
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
