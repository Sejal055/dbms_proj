import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth/signup_page.dart';
import 'auth/login_page.dart';        // <-- Import your login page
import 'home_page.dart';             // <-- Import your home page
import 'firebase_options.dart';      // (flutterfire configure)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'services/notification_service.dart';

// --- ADD THIS AUTH WRAPPER WIDGET ---
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return HomePage();
        } else {
          return LogInPage(); // Use your login page as entry
        }
      },
    );
  }
}
// ------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BudgetBuddyApp());
}

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // CHANGED: Use the AuthWrapper as your home widget
      home: const AuthWrapper(), // <--- This handles auth state and navigation!
    );
  }
}
