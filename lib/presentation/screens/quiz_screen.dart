import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stimuler_assignment/presentation/widgets/quiz_loading_screen.dart';
import 'package:stimuler_assignment/providers/question_provider.dart';

import '../../model/quiz_data.dart';

class QuizScreen extends StatefulWidget {
  final String category;

  QuizScreen({required this.category});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? selectedAnswerIndex;
  bool hasCheckedAnswer = false;
  String? correctAnswer;
  String? questionText;
  List<String> options = [];
  int currentQuestionIndex = 1;
  bool isLoading = true;
  bool isLastQuestion = false;
  int totalQuestions = 0;
  String currentExercise = 'Exercise 1';

  int questionsSolved = 0;
  // int totalQuestionsSolved = 0; // Total solved questions across all exercises
  int totalQuestionsAcrossExercises =
      0; // Total number of questions across all exercises

  @override
  void initState() {
    super.initState();
    initializeQuiz();
  }

  QuizState _getQuizState() {
    return context.read<QuestionState>().getQuizState(widget.category);
  }

  Future<void> initializeQuiz() async {
    QuizState currentState = _getQuizState();

    setState(() {
      currentExercise = currentState.currentExercise;
      currentQuestionIndex = currentState.currentQuestionIndex;
    });

    await fetchTotalQuestions();
    fetchQuizData();

    // Check if the user has already completed all the questions for this category
    if (context
        .read<QuestionState>()
        .hasAttemptedAllQuestions(widget.category)) {
      showCompletionDialog(); // Show the message if already completed
    }
  }

  Future<void> fetchTotalQuestions() async {
    int exercise1Count = (await FirebaseFirestore.instance
            .collection('quiz')
            .doc(widget.category)
            .collection('Exercise 1')
            .get())
        .docs
        .length;

    int exercise2Count = (await FirebaseFirestore.instance
            .collection('quiz')
            .doc(widget.category)
            .collection('Exercise 2')
            .get())
        .docs
        .length;

    setState(() {
      totalQuestionsAcrossExercises = exercise1Count + exercise2Count;
      totalQuestions =
          currentExercise == 'Exercise 1' ? exercise1Count : exercise2Count;
    });
  }

  Future<void> fetchQuizData() async {
    setState(() => isLoading = true);
    await fetchQuestion(currentQuestionIndex);

    setState(() {
      isLastQuestion = currentQuestionIndex >= totalQuestions;
      isLoading = false;
    });
  }

  Future<void> fetchQuestion(int questionIndex) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quiz')
        .doc(widget.category)
        .collection(currentExercise)
        .doc('Q$questionIndex')
        .get();

    if (snapshot.exists) {
      setState(() {
        correctAnswer = snapshot['correctAnswer'];
        options = List<String>.from(snapshot['options']);
        questionText = snapshot['questionText'];
        selectedAnswerIndex = null;
        hasCheckedAnswer = false;
      });
    }
  }

  void checkAnswer() {
    if (selectedAnswerIndex != null && !hasCheckedAnswer) {
      bool isCorrect = options[selectedAnswerIndex!] == correctAnswer;
      setState(() {
        hasCheckedAnswer = true;
      });

      // Mark the specific question as solved
      // context.read<QuestionState>().markQuestionSolved(
      //     widget.category, currentExercise, currentQuestionIndex);
      context.read<QuestionState>()
        ..updateSolvedQuestions(widget.category, currentQuestionIndex)
        ..updateQuizProgress(widget.category, isCorrect);
      ;

      showResultBottomSheet();
    }
  }

  void proceedToNext() {
    // Update the quiz state in the provider
    context.read<QuestionState>().saveQuizState(
          widget.category,
          QuizState(
            currentExercise: currentExercise,
            currentQuestionIndex: currentQuestionIndex + 1,
            totalQuestionsSolved: context
                .read<QuestionState>()
                .getSolvedQuestionsCount(widget.category),
          ),
        );

    if (isLastQuestion) {
      if (currentExercise == 'Exercise 1') {
        // Move to Exercise 2
        context.read<QuestionState>().saveQuizState(
              widget.category,
              QuizState(
                currentExercise: 'Exercise 2',
                currentQuestionIndex: 1,
              ),
            );

        setState(() {
          currentExercise = 'Exercise 2';
          currentQuestionIndex = 1;
        });

        initializeQuiz();
      } else {
        // All exercises completed
        showCompletionDialog();
      }
    } else {
      // Load next question
      setState(() {
        currentQuestionIndex++;
        fetchQuizData();
      });
    }
  }

  void showCompletionDialog() {
    int totalSolved =
        context.read<QuestionState>().getSolvedQuestionsCount(widget.category);

    if (context
        .read<QuestionState>()
        .hasAttemptedAllQuestions(widget.category)) {
      // Show a message indicating they have completed all questions already
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Dark background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[800]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Achievement Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.task_alt_rounded,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'All Questions Attempted! 🎯',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Score
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$totalSolved/$totalQuestionsAcrossExercises',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        ' Questions',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Message
                Text(
                  'Great job completing all exercises for this category!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Show the congratulations dialog for the first-time completion
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Dark background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[800]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Congratulations! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Content
                Text(
                  'You have completed all exercises!\n'
                  'You attempted $totalSolved/$totalQuestionsAcrossExercises questions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<QuestionState>()
                          .markCategoryAsCompleted(widget.category);
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // void showCompletionDialog() {
  //   int totalSolved =
  //       context.read<QuestionState>().getSolvedQuestionsCount(widget.category);
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Congratulations!'),
  //       content: Text(
  //         'You have completed all exercises.\n'
  //         'You solved $totalSolved/$totalQuestionsAcrossExercises questions.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             context.read<QuestionState>().markLevelCompleted(widget.category);
  //             Navigator.pop(context);
  //           },
  //           child: Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void showResultBottomSheet() {
    bool isCorrect = options[selectedAnswerIndex!] == correctAnswer;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isCorrect ? Color(0xFF1C4C3B) : Color(0xFF4A1919),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect
                          ? Color(0xFF4CAF50) // Green for correct
                          : Color(0xFFD32F2F), // Red for incorrect
                    ),
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    isCorrect ? 'Correct Answer' : 'Incorrect Answer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Result feedback UI here
              SizedBox(height: 12),
              if (!isCorrect) ...[
                Text(
                  'The correct answer is ${correctAnswer}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '"${correctAnswer}" is the correct answer as per our data. Our data is based on verified information on the intenet and well-known institutions such as Oxford University.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              if (isCorrect) ...[
                Text(
                  'Great job! That\'s the right answer.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    proceedToNext();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isLastQuestion && currentExercise == 'Exercise 1'
                        ? 'Start Next Exercise'
                        : 'Continue to next question',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getBlobColor() {
    if (!hasCheckedAnswer) return Colors.blue;
    return selectedAnswerIndex != null &&
            options[selectedAnswerIndex!] == correctAnswer
        ? Colors.green
        : Colors.red;
  }

  Widget buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question $currentQuestionIndex of $totalQuestions',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '${((currentQuestionIndex / totalQuestions) * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[800],
          ),
          child: Row(
            children: [
              Flexible(
                flex: currentQuestionIndex,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade400],
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: totalQuestions - currentQuestionIndex,
                child: Container(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return QuizLoadingScreen();
    }

    // If questionText is null, make the background color black
    if (questionText == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        // body: Center(
        //   child: Text(
        //     'Loading or no question available',
        //     style: TextStyle(color: Colors.white, fontSize: 20),
        //   ),
        // ),
      );
    }
    final blobColor = getBlobColor().withOpacity(0.3);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blob effects
          Positioned(
            top: -50,
            right: -50,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: blobColor,
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: blobColor,
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Grammar Practice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.flag, color: Colors.white),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: buildProgressBar(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q$currentQuestionIndex. $questionText',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/book_holder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ...options.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = selectedAnswerIndex == index;
                    final isCorrect =
                        hasCheckedAnswer && option == correctAnswer;
                    final isWrong =
                        hasCheckedAnswer && isSelected && !isCorrect;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: hasCheckedAnswer
                              ? null
                              : () {
                                  setState(() {
                                    selectedAnswerIndex = index;
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCorrect
                                ? Colors.green
                                : isWrong
                                    ? Colors.red
                                    : isSelected
                                        ? Colors.blue
                                        : Colors.grey[900],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedAnswerIndex != null && !hasCheckedAnswer
                              ? checkAnswer
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedAnswerIndex != null
                            ? Colors.blue
                            : Colors.grey[800],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Check Answer',
                        style: TextStyle(
                          color: selectedAnswerIndex != null
                              ? Colors.white
                              : Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
