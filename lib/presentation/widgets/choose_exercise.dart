import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stimuler_assignment/presentation/screens/quiz_screen.dart';

import '../../../providers/question_provider.dart';
import '../../../providers/selected_exercise_provider.dart';

class ChooseExercise extends StatefulWidget {
  const ChooseExercise({super.key});

  @override
  State<ChooseExercise> createState() => _ChooseExerciseState();
}

class _ChooseExerciseState extends State<ChooseExercise> {
  @override
  Widget _buildExerciseOption(
    String title,
    IconData icon,
    String? selectedExercise,
    Function(String) onSelect,
  ) {
    final questionState = context.watch<QuestionState>();
    final progressString = questionState.getProgressString(title);
    final isLevelUnlocked =
        context.watch<QuestionState>().isLevelUnlocked(title);
    final isLevelCompleted = questionState.completedLevels.contains(title);

    IconData getIconForLevel(String title, bool isCompleted) {
      if (isCompleted) {
        return Icons.check_circle;
      }
      switch (title) {
        case 'Adjectives':
          return Icons.format_color_text;
        case 'Adverbs':
          return Icons.timeline;
        case 'Conjunctions':
          return Icons.link;
        case 'Prefix & Suffix':
          return Icons.text_fields;
        case 'Sentence Structure':
          return Icons.format_align_left;
        case 'Verbs':
          return Icons.play_arrow;
        default:
          return Icons.book;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: !isLevelUnlocked
            ? Colors.grey.shade900
            : (selectedExercise == title
                ? Colors.deepPurple.shade900
                : Colors.deepPurple.shade900.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        border: isLevelCompleted
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Color(0xFF675a8a), width: 2),
      ),
      child: ListTile(
        leading: Icon(
          getIconForLevel(title, isLevelCompleted),
          color: isLevelCompleted
              ? Colors.green
              : (!isLevelUnlocked
                  ? Colors.white54
                  : (selectedExercise == title
                      ? Colors.white
                      : Colors.white54)),
          size: 24,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: !isLevelUnlocked
                      ? Colors.white54
                      : (selectedExercise == title
                          ? Colors.white
                          : Colors.white54),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                progressString,
                style: TextStyle(
                  color: isLevelCompleted
                      ? Colors.green
                      : (!isLevelUnlocked
                          ? Colors.white54
                          : (selectedExercise == title
                              ? Colors.white
                              : Colors.white54)),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        onTap: isLevelUnlocked ? () => onSelect(title) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Consumer<ExerciseProvider>(
          builder: (context, exerciseProvider, child) {
            return DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.3,
              maxChildSize: 0.6,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixed Header Section
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "Choose Exercise",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    // Scrollable Exercise Options
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: exerciseProvider.levels.map((title) {
                          return _buildExerciseOption(
                            title,
                            Icons.description,
                            exerciseProvider.selectedExercise,
                            (title) {
                              exerciseProvider.setSelectedExercise(
                                exerciseProvider.selectedExercise == title
                                    ? null
                                    : title,
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: exerciseProvider.selectedExercise != null
                            ? () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizScreen(
                                      category:
                                          exerciseProvider.selectedExercise!,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              Colors.deepPurple.shade900.withOpacity(0.3),
                        ),
                        child: Text(
                          "Start Practice",
                          style: TextStyle(
                            color: exerciseProvider.selectedExercise != null
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
