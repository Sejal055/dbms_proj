// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> saveBudgetNotification() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final notificationData = {
    'title': 'Budget Warning',
    'body': 'Your spending is about to exceed your monthly budget!',
    'timestamp': FieldValue.serverTimestamp(),
    'read': false,
  };

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .add(notificationData);
}


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
  }

  Future<void> showBudgetWarning() async {
    const android = AndroidNotificationDetails(
      'budget_channel', 'Budget Alerts',
      importance: Importance.max, priority: Priority.high
    );
    const notifDetails = NotificationDetails(android: android);
    await _plugin.show(
      0, 'Budget Alert',
      'You are about to exceed your monthly budget!',
      notifDetails
    );
  }

  Future<bool> checkBudgetAndNotify() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final monthlyBudget = userDoc.data()?['monthly_budget'];
  if (monthlyBudget == null) return false;

  final expensesSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('expenses')
      .get();

  double total = 0.0;
  for (final doc in expensesSnap.docs) {
    final amt = doc.data()['expense_amount'];
    if (amt is num) total += amt.toDouble();
  }

  if (total >= 0.9 * monthlyBudget) {
    await showBudgetWarning();
    await saveBudgetNotification();  // Save notification record for dashboard
    return true;
  }
  return false;
}

Future<void> saveBudgetNotification() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final notificationData = {
    'title': 'Budget Warning',
    'body': 'Your spending is about to exceed your monthly budget!',
    'timestamp': FieldValue.serverTimestamp(),
    'read': false,
  };

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .add(notificationData);
}

}

