import 'package:flutter/material.dart';

class ExerciseProvider extends ChangeNotifier {
  String? _selectedExercise = 'Adjectives';

  String? get selectedExercise => _selectedExercise;

  void setSelectedExercise(String? exercise) {
    _selectedExercise = exercise;
    notifyListeners();
  }

  final List<String> levels = [
    "Adjectives",
    "Adverbs",
    "Conjunctions",
    "Prefix & Suffix",
    "Sentence Structure",
    "Verbs"
  ];
}
