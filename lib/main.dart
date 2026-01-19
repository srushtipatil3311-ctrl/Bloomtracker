import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'bloom_splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('🔥 Firebase initialized successfully');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bloom',

      theme: ThemeData(
        primaryColor: const Color(0xFF7B1FA2),
        scaffoldBackgroundColor: const Color(0xFFF7EDF9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B1FA2),
        ),
        useMaterial3: true,
      ),

      // 🔁 ENTRY POINT — Splash decides everything
      home: const BloomSplashScreen(),
    );
  }
}
