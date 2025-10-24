import 'package:flutter/material.dart';

class PlannedPaymentsPage extends StatelessWidget {
  const PlannedPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planned Payments'),
        backgroundColor: const Color(0xFF7BAFFC),
      ),
      body: const Center(
        child: Text(
          'This is the Planned Payments Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
