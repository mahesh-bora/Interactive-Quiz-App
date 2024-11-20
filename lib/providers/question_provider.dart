import 'package:flutter/material.dart';

import '../model/quiz_data.dart';

class QuestionState extends ChangeNotifier {
  Map<String, QuizState> quizStates = {};
  Map<String, Set<String>> solvedQuestions = {};
  Map<String, int> _correctAnswers = {};
  Map<String, int> _totalAnswered = {};
  final Map<String, bool> _levelCompletionStatus = {};
  // Set<String> completedLevels = {};
  final Set<String> _completedLevels = {};
  Set<String> get completedLevels => _completedLevels;
  final Map<String, bool> _hasAttemptedAllQuestions = {};

  final Set<String> _startedLevels = {
    "Adjectives"
  }; // First level starts unlocked
  final Map<String, Map<String, int>> totalQuestionsCounts = {
    'Adjectives': {'Exercise 1': 3, 'Exercise 2': 2},
    'Adverbs': {'Exercise 1': 2, 'Exercise 2': 2},
    'Conjunctions': {'Exercise 1': 2, 'Exercise 2': 2},
    'Prefix & Suffix': {'Exercise 1': 2, 'Exercise 2': 2},
    'Sentence Structure': {'Exercise 1': 2, 'Exercise 2': 2},
    'Verbs': {'Exercise 1': 2, 'Exercise 2': 2},
  };

  final List<String> levelOrder = [
    'Adjectives',
    'Adverbs',
    'Conjunctions',
    'Prefix & Suffix',
    'Sentence Structure',
    'Verbs'
  ];

  // Method to check if the user has completed all the questions for a category
  bool hasAttemptedAllQuestions(String category) {
    return _hasAttemptedAllQuestions[category] ?? false;
  }

  // Method to mark the category as completed
  void markCategoryAsCompleted(String category) {
    _hasAttemptedAllQuestions[category] = true;
    notifyListeners();
  }

  // Flag to track if Verbs level has been reached
  bool _hasReachedVerbs = false;

  QuestionState() {
    initializeState();
  }

  void initializeState() {
    if (quizStates.isEmpty) {
      // Initialize first level
      quizStates['Adjectives'] = QuizState(isLevelUnlocked: true);

      // Find the last unlocked level based on solved questions
      int lastUnlockedIndex = 0;
      for (int i = 0; i < levelOrder.length; i++) {
        String category = levelOrder[i];
        if (solvedQuestions[category]?.isNotEmpty ?? false) {
          lastUnlockedIndex = i + 1;
        }
        // Check if Verbs was previously unlocked
        if (category == 'Verbs' &&
            (quizStates[category]?.isLevelUnlocked == true ||
                solvedQuestions[category]?.isNotEmpty == true)) {
          _hasReachedVerbs = true;
        }
      }

      // Initialize other levels based on progression
      for (int i = 1; i < levelOrder.length; i++) {
        String level = levelOrder[i];
        bool shouldBeUnlocked =
            i <= lastUnlockedIndex || (level == 'Verbs' && _hasReachedVerbs);
        quizStates[level] = QuizState(isLevelUnlocked: shouldBeUnlocked);
      }

      // Initialize empty solved questions sets for all levels
      for (var level in levelOrder) {
        solvedQuestions[level] ??= {};
      }
    }

    // Ensure Verbs stays unlocked if previously reached
    if (_hasReachedVerbs && !quizStates['Verbs']!.isLevelUnlocked) {
      quizStates['Verbs'] =
          quizStates['Verbs']!.copyWith(isLevelUnlocked: true);
    }
  }

  QuizState getQuizState(String category) {
    if (category == 'Verbs' && _hasReachedVerbs) {
      return quizStates[category] ?? QuizState(isLevelUnlocked: true);
    }
    return quizStates[category] ??
        QuizState(isLevelUnlocked: category == 'Adjectives');
  }

  void updateSolvedQuestions(String category, int questionIndex) {
    solvedQuestions[category] ??= {};

    String questionKey =
        '${getQuizState(category).currentExercise}-Q$questionIndex';
    solvedQuestions[category]!.add(questionKey);

    quizStates[category] = quizStates[category]!.copyWith(
      totalQuestionsSolved: solvedQuestions[category]!.length,
    );

    // If we're unlocking Verbs, set the flag
    if (category == 'Sentence Structure' && isLevelCompleted(category)) {
      _hasReachedVerbs = true;
    }

    if (isExerciseCompleted(category, getQuizState(category).currentExercise)) {
      if (getQuizState(category).currentExercise == 'Exercise 1') {
        quizStates[category] = quizStates[category]!.copyWith(
          currentExercise: 'Exercise 2',
          currentQuestionIndex: 1,
        );
      } else if (isLevelCompleted(category)) {
        unlockNextLevel(category);
      }
    }

    notifyListeners();
  }

  void unlockNextLevel(String category) {
    int currentIndex = levelOrder.indexOf(category);
    if (currentIndex < levelOrder.length - 1) {
      String nextCategory = levelOrder[currentIndex + 1];

      // Set flag if we're unlocking Verbs
      if (nextCategory == 'Verbs') {
        _hasReachedVerbs = true;
      }

      if (quizStates[nextCategory]?.isLevelUnlocked != true) {
        quizStates[nextCategory] = quizStates[nextCategory]?.copyWith(
              isLevelUnlocked: true,
            ) ??
            QuizState(
              isLevelUnlocked: true,
              currentExercise: 'Exercise 1',
              currentQuestionIndex: 1,
            );
      }
      notifyListeners();
    }
  }

  bool isExerciseCompleted(String category, String exercise) {
    int exerciseQuestions = totalQuestionsCounts[category]?[exercise] ?? 5;
    int solvedInExercise = solvedQuestions[category]
            ?.where((q) => q.startsWith(exercise))
            .length ??
        0;
    return solvedInExercise >= exerciseQuestions;
  }

  bool isLevelCompleted(String category) {
    int totalQuestions = (totalQuestionsCounts[category]?['Exercise 1'] ?? 5) +
        (totalQuestionsCounts[category]?['Exercise 2'] ?? 5);
    bool completed = (solvedQuestions[category]?.length ?? 0) >= totalQuestions;

    // Add to completed levels set if completed
    if (completed) {
      completedLevels.add(category);
    }

    return (solvedQuestions[category]?.length ?? 0) >= totalQuestions;
  }

  void markLevelCompleted(String level) {
    _levelCompletionStatus[level] = true;
    notifyListeners();
  }

  int getSolvedQuestionsCount(String category) {
    return solvedQuestions[category]?.length ?? 0;
  }

  void saveQuizState(String category, QuizState state) {
    quizStates[category] = state;
    if (category == 'Verbs' && state.isLevelUnlocked) {
      _hasReachedVerbs = true;
    }
    notifyListeners();
  }

  int getCorrectAnswersCount(String category) {
    return _correctAnswers[category] ?? 0;
  }

  void updateQuizProgress(String category, bool isCorrect) {
    _totalAnswered[category] = (_totalAnswered[category] ?? 0) + 1;
    if (isCorrect) {
      _correctAnswers[category] = (_correctAnswers[category] ?? 0) + 1;
    }
    notifyListeners();
  }

  int getTotalAnsweredCount(String category) {
    return _totalAnswered[category] ?? 0;
  }

  String getProgressString(String category) {
    int correct = getCorrectAnswersCount(category);
    int total = getTotalAnsweredCount(category);
    return '$correct/$total';
  }

  // Method to check if a level is unlocked
  bool isLevelUnlocked(String level) {
    // A level is unlocked if:
    // 1. It's in started levels OR
    // 2. It's in completed levels OR
    // 3. The previous level is completed

    if (_startedLevels.contains(level) || _completedLevels.contains(level)) {
      return true;
    }

    // Get the previous level based on the fixed order
    final levels = [
      "Adjectives",
      "Adverbs",
      "Conjunctions",
      "Prefix & Suffix",
      "Sentence Structure",
      "Verbs"
    ];

    if (levels == 'Verbs' && _hasReachedVerbs) {
      return true;
    }
    return quizStates[level]?.isLevelUnlocked ?? (levels == 'Adjectives');

    final currentIndex = levels.indexOf(level);
    if (currentIndex <= 0) return true; // First level is always unlocked

    // Check if previous level is completed
    final previousLevel = levels[currentIndex - 1];
    return _completedLevels.contains(previousLevel);
  }

  // Call this when starting a quiz
  void startLevel(String level) {
    _startedLevels.add(level);
    notifyListeners();
  }

  // Call this when a quiz is completed
  void completeLevel(String level) {
    _completedLevels.add(level);
    // Also unlock the next level
    final levels = [
      "Adjectives",
      "Adverbs",
      "Conjunctions",
      "Prefix & Suffix",
      "Sentence Structure",
      "Verbs"
    ];

    final currentIndex = levels.indexOf(level);
    if (currentIndex < levels.length - 1) {
      _startedLevels.add(levels[currentIndex + 1]);
    }
    notifyListeners();
  }

  // Optional: Method to reset progress
  // void resetProgress() {
  //   _startedLevels.clear();
  //   _completedLevels.clear();
  //   _startedLevels.add("Adjectives"); // Keep first level unlocked
  //   notifyListeners();
  // }
}
