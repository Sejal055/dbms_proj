import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecurringPaymentChecker {
  /// Moves any recurring payments due soon into pending_payments
  static Future<void> checkAndMoveRecurringPayments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threshold = today.add(const Duration(days: 2)); // 2 days early

    final recurringRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('recurring_payments');

    final pendingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pending_payments');

    final snapshot = await recurringRef.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final nextDue = (data['next_due'] as Timestamp?)?.toDate();

      if (nextDue == null) continue;

      // If due today or within 2 days
      if (nextDue.isBefore(threshold)) {
        // Check if already exists in pending_payments
        final pendingQuery = await pendingRef
            .where('title', isEqualTo: data['title'])
            .where('category', isEqualTo: data['category'])
            .where('amount', isEqualTo: data['amount'])
            .where('status', isEqualTo: 'pending')
            .get();

        if (pendingQuery.docs.isEmpty) {
          await pendingRef.add({
            'title': data['title'],
            'amount': data['amount'],
            'category': data['category'],
            'type': data['type'],
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
            'from_recurring': true,
            'scheduled_for': data['next_due'],
          });
        }

        // Update next due date for next cycle
        final frequency = data['frequency'] ?? 'Monthly';
        final newNextDue = _calculateNextDue(nextDue, frequency);
        await recurringRef.doc(doc.id).update({'next_due': newNextDue});
      }
    }
  }

  static DateTime _calculateNextDue(DateTime base, String freq) {
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
}