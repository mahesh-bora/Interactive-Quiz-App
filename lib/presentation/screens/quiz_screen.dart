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
  bool shouldUpdateBlobColor = false;

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

  // void checkAnswer() {
  //   if (selectedAnswerIndex != null && !hasCheckedAnswer) {
  //     bool isCorrect = options[selectedAnswerIndex!] == correctAnswer;
  //     setState(() {
  //       hasCheckedAnswer = true;
  //     });
  //
  //     // Mark the specific question as solved
  //     // context.read<QuestionState>().markQuestionSolved(
  //     //     widget.category, currentExercise, currentQuestionIndex);
  //     context.read<QuestionState>()
  //       ..updateSolvedQuestions(widget.category, currentQuestionIndex)
  //       ..updateQuizProgress(widget.category, isCorrect);
  //     ;
  //
  //     showResultBottomSheet();
  //   }
  // }
  void checkAnswer() async {
    if (selectedAnswerIndex != null && !hasCheckedAnswer) {
      bool isCorrect = options[selectedAnswerIndex!] == correctAnswer;

      // First, trigger the blob color change
      setState(() {
        hasCheckedAnswer = true;
        shouldUpdateBlobColor = true;
      });

      // Update the quiz state
      context.read<QuestionState>()
        ..updateSolvedQuestions(widget.category, currentQuestionIndex)
        ..updateQuizProgress(widget.category, isCorrect);

      // Wait for 3 seconds before showing the bottom sheet
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        showResultBottomSheet();
      }
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
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.blueAccent,
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
                      backgroundColor: Colors.blueAccent,
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

  void showResultBottomSheet() {
    bool isCorrect = options[selectedAnswerIndex!] == correctAnswer;

    showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 1.0, end: 0.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value * 200), // Slide up animation
                  child: Opacity(
                    opacity: 1 - value,
                    child: child,
                  ),
                );
              },
              child: Container(
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
                        SizedBox(height: 12),
                        Text(
                          'You are already rocking it, Keep hustling and upgrading your skills with your study buddy. Because learning should never stop',
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
                            backgroundColor: Colors.white.withOpacity(0.2),
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
            ));
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
  Widget buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Before popping, mark the category as in progress
            context
                .read<QuestionState>()
                .markCategoryInProgress(widget.category);
            Navigator.pop(context);
          },
        ),
        Text(
          'Grammar Practice',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.045,
          ),
        ),
        Spacer(),
        Icon(Icons.flag, color: Colors.white),
      ],
    );
  }

  Widget buildQuestionText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textAlign: TextAlign.left,
          'Q$currentQuestionIndex. Fill in the blanks',
          style: TextStyle(
            color: Colors.white70,
            fontSize: MediaQuery.of(context).size.width * 0.05,
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          '$questionText',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.04,
          ),
        ),
      ],
    );
  }

  Widget buildOptions(Size size) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selectedAnswerIndex == index;
        final isCorrect = hasCheckedAnswer && option == correctAnswer;
        final isWrong = hasCheckedAnswer && isSelected && !isCorrect;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: hasCheckedAnswer
                ? null
                : () {
                    setState(() => selectedAnswerIndex = index);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCorrect
                  ? Colors.green
                  : isWrong
                      ? Colors.red
                      : isSelected
                          ? Colors.blue
                          : Colors.black.withOpacity(0.5),
              padding: EdgeInsets.symmetric(
                vertical: size.height * 0.02,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: size.width * 0.05),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      ['A', 'B', 'C', 'D'][index],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.04,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(size.width * 0.02),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.04,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildCheckAnswerButton() {
    String buttonText = 'Check Answer';

    if (hasCheckedAnswer) {
      if (options[selectedAnswerIndex!] == correctAnswer) {
        buttonText = 'Great Work! 🎉';
      } else {
        buttonText = 'Oops! Wrong Answer';
      }
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedAnswerIndex != null && !hasCheckedAnswer
            ? checkAnswer
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selectedAnswerIndex != null ? Colors.blue : Colors.grey[800],
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            color:
                selectedAnswerIndex != null ? Colors.white : Colors.grey[400],
            fontSize: MediaQuery.of(context).size.width * 0.04,
          ),
        ),
      ),
    );
  }

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
    final size = MediaQuery.of(context).size;
    final blobColor = getBlobColor().withOpacity(0.3);
    final padding = MediaQuery.of(context).padding;
    final availableHeight = size.height - padding.top - padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: -30,
            bottom: 10,
            right: -20,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: blobColor,
                    blurRadius: 100,
                    spreadRadius: 70,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 200,
            // bottom: -100,
            left: -10,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: 100,
              height: 100,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.02,
                        ),
                        child: Column(
                          children: [
                            // Header
                            buildHeader(),
                            SizedBox(height: availableHeight * 0.02),

                            // Progress Bar
                            buildProgressBar(),
                            SizedBox(height: availableHeight * 0.03),

                            // Question Text
                            buildQuestionText(),
                            SizedBox(height: availableHeight * 0.02),

                            // Image
                            Container(
                              width: size.width * 0.4,
                              height: size.width * 0.4,
                              decoration: BoxDecoration(shape: BoxShape.circle),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/book_holder.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: availableHeight * 0.04),

                            // Options
                            buildOptions(size),

                            // Check Answer Button
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: availableHeight * 0.02,
                              ),
                              child: buildCheckAnswerButton(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
