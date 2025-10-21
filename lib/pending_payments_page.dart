import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingPaymentsPage extends StatelessWidget {
  const PendingPaymentsPage({super.key});

  // Example static data; replace with Firestore query for real app
  final List<Map<String, dynamic>> pendingPayments = const [
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
                  Row(
                    children: [
                      ElevatedButton(
                        child: const Text("Pay Now"),
                        onPressed: () async {
                          String upiUrl =
                              "upi://pay?pa=${payment['upi_id']}&pn=${payment['title']}&am=${payment['amount']}&cu=INR";
                          if (await canLaunch(upiUrl)) {
                            await launch(upiUrl);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Could not redirect to payment app.",
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        child: const Text("Remind"),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Reminder set in app for ${payment['title']}",
                              ),
                            ),
                          );
                        },
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

