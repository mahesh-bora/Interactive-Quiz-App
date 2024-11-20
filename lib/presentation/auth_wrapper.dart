import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stimuler_assignment/presentation/screens/home_screen.dart';
import 'package:stimuler_assignment/presentation/screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return const HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}
