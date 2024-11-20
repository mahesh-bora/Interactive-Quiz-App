import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stimuler_assignment/presentation/auth_wrapper.dart';
import 'package:stimuler_assignment/providers/last_level_drawn_provider.dart';
import 'package:stimuler_assignment/providers/question_provider.dart';
import 'package:stimuler_assignment/providers/selected_exercise_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuestionState()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => LastDrawnLevelProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      home: const AuthWrapper(),
    );
  }
}
