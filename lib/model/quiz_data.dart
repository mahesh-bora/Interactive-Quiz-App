class QuizState {
  final String currentExercise;
  final int currentQuestionIndex;
  final int totalQuestionsSolved;
  final bool isLevelUnlocked;

  QuizState({
    this.currentExercise = 'Exercise 1',
    this.currentQuestionIndex = 1,
    this.totalQuestionsSolved = 0,
    this.isLevelUnlocked = false,
  });

  QuizState copyWith({
    String? currentExercise,
    int? currentQuestionIndex,
    int? totalQuestionsSolved,
    bool? isLevelUnlocked,
  }) {
    return QuizState(
      currentExercise: currentExercise ?? this.currentExercise,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestionsSolved: totalQuestionsSolved ?? this.totalQuestionsSolved,
      isLevelUnlocked: isLevelUnlocked ?? this.isLevelUnlocked,
    );
  }
}
