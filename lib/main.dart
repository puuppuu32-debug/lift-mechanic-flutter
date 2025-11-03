import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_menu_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase с конфигурацией для web
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDQd5RZyQAyOoI6Qzu6aCuQOxWSUQOVOxM",
      authDomain: "lift-mechanic-pwa.firebaseapp.com",
      projectId: "lift-mechanic-pwa",
      storageBucket: "lift-mechanic-pwa.firebasestorage.app",
      messagingSenderId: "504828099853",
      appId: "1:504828099853:web:6af96c6d3c79afa0930444",
      measurementId: "G-T5J495YEL8",
    ),
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'Электромеханик по лифтам',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Arial',
        ),
        home: AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return AuthScreen();
          }
          return MainMenuScreen();
        }
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}