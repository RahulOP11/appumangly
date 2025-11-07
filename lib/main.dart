import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mood_selection_screen.dart';
import 'screens/dynamic_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UmanglyApp());
}

class UmanglyApp extends StatelessWidget {
  const UmanglyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Umangly',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/mood-selection': (context) => const MoodSelectionScreen(),
        '/dynamic-home': (context) => DynamicHomePersonalization(
          builder: (context, mood, weeklyData) => Scaffold(
            appBar: AppBar(title: const Text('Dynamic Home')),
            body: const Center(
              child: Text('Dynamic home personalization view'),
            ),
          ),
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
