// import 'package:flutter/material.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'auth/signup_page.dart';
// import 'firebase_options.dart';
// import 'services/notification_service.dart';

// class SplashPage extends StatefulWidget {
//   const SplashPage({super.key});

//   @override
//   State<SplashPage> createState() => _SplashPageState();
// }

// class _SplashPageState extends State<SplashPage> {

//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }

//   // This function performs all your critical asynchronous startup tasks.
//   void _initializeApp() async {
//     // 1. Initialize Timezones (required for local notifications)
//     tz.initializeTimeZones();

//     // 2. Initialize Local Notifications
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const initSettings = InitializationSettings(android: androidInit);
//     await flutterLocalNotificationsPlugin.initialize(initSettings);

//     // 3. Initialize Firebase
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );

//     // 4. Critical: Remove the native splash screen
//     // This is called when all initial native and asynchronous Dart work is done.
//     FlutterNativeSplash.remove();

//     // 5. Navigate to the main screen (e.g., SignUpPage)
//     if (mounted) {
//       // Replace the SplashPage with the next screen.
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (context) => const SignUpPage()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // While the app is initializing, show a simple loading indicator.
//     // The native splash screen will cover the initial loading time.
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

// NOTE: We need the AuthWrapper defined in main.dart or a similar file.
// Assuming AuthWrapper is in 'main.dart' or a shared location:
// You might need to adjust the path based on your file structure.
// If AuthWrapper is in main.dart, use:
import 'main.dart'; // Import to access AuthWrapper

import 'firebase_options.dart';
import 'services/notification_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    // Use a small delay to ensure the native splash is visible for a moment 
    // and then call the initialization function.
    Future.delayed(const Duration(milliseconds: 500), _initializeApp);
  }

  // This function performs all your critical asynchronous startup tasks.
  void _initializeApp() async {
    // 1. Initialize Timezones (required for local notifications)
    tz.initializeTimeZones();

    // 2. Initialize Local Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 3. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 4. Critical: Remove the native splash screen
    FlutterNativeSplash.remove();

    // 5. Navigate to the AuthWrapper to check the 'remember me' status
    if (mounted) {
      // Navigate to the AuthWrapper, which redirects to HomePage or LogInPage.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // CHANGED: Navigate to AuthWrapper, not SignUpPage
          builder: (context) => const AuthWrapper(), 
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // While initialization is running, Flutter shows the UI here.
    // The native splash should cover this period initially.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}