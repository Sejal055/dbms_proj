import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'splash_page.dart'; // Import the new SplashPage
import 'auth/signup_page.dart';
import 'auth/login_page.dart'; // <-- Import your login page
import 'home_page.dart'; // <-- Import your home page
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