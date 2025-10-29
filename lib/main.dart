
// import 'package:flutter/material.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// Note: You can remove the Firebase, local_notifications, and timezone imports 
// from main.dart because they are now handled inside SplashPage.
// import 'package:firebase_core/firebase_core.dart';
// import 'package:timezone/data/latest_all.dart' as tz; 

//import 'splash_page.dart'; // Import the new SplashPage
// import 'auth/signup_page.dart';
// import 'firebase_options.dart'; 
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'services/notification_service.dart';
// import 'auth/signup_page.dart';
// import 'auth/login_page.dart';        // <-- Import your login page
// import 'home_page.dart';             // <-- Import your home page
// import 'firebase_options.dart';      // (flutterfire configure)
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'services/notification_service.dart';

// --- ADD THIS AUTH WRAPPER WIDGET ---
// import 'package:firebase_auth/firebase_auth.dart';

// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (snapshot.hasData) {
//           return HomePage();
//         } else {
//           return LogInPage(); // Use your login page as entry
//         }
//       },
//     );
//   }
// }
// // ------------------------------------

// void main() async {
//   // 1. Ensure widgets binding is initialized.
//   WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

//   // 2. Preserve the native splash screen until FlutterNativeSplash.remove() is called.
//   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

//   // Note: All your heavy initialization (Firebase, Notifications, timezones) 
//   // has been moved to the SplashPage's _initializeApp method.

//   // 3. Run the app, starting with the SplashPage.
//   runApp(const BudgetBuddyApp());
// }

// class BudgetBuddyApp extends StatelessWidget {
//   const BudgetBuddyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       // Start the app with the dedicated SplashPage
//       home: const SplashPage(), 
//       // CHANGED: Use the AuthWrapper as your home widget
//       home: const AuthWrapper(), // <--- This handles auth state and navigation!
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'splash_page.dart'; // Import the new SplashPage
import 'auth/signup_page.dart';
import 'auth/login_page.dart'; // <-- Import your login page
import 'home_page.dart'; // <-- Import your home page
import 'firebase_options.dart'; // (flutterfire configure)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- AUTH WRAPPER WIDGET (Manages 'remember me' logic) ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // This StreamBuilder checks if a user is currently logged in.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // You could return a simple loading indicator here, 
          // but the SplashPage already handled the initial loading.
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // User is signed in (the 'remember me' state is active) -> Go to Home
          return HomePage();
        } else {
          // No user signed in -> Go to Login (which often contains a SignUp link)
          return LogInPage(); 
        }
      },
    );
  }
}
// ------------------------------------

void main() async {
  // 1. Ensure widgets binding is initialized.
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Preserve the native splash screen until FlutterNativeSplash.remove() is called.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 3. Run the app, starting with the SplashPage.
  runApp(const BudgetBuddyApp());
}

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Start the app with the dedicated SplashPage.
      // This page will perform initialization and then navigate to AuthWrapper.
      home: const SplashPage(), 
    );
  }
}

// NOTE: You will need to ensure your SplashPage navigates to AuthWrapper 
// after all initializations are complete. See the suggested structure below.