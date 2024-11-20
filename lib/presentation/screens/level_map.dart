import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stimuler_assignment/providers/question_provider.dart';

import '../../providers/last_level_drawn_provider.dart';
import '../widgets/choose_exercise.dart';
import '../widgets/path_painter.dart';

class LevelMap extends StatefulWidget {
  @override
  _LevelMapState createState() => _LevelMapState();
}

class _LevelMapState extends State<LevelMap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController pathAnimationController;
  late Animation<double> pathAnimation;
  bool isFirstBuild = true;
  int lastDrawnLevel = -1;

  final List<String> levelss = [
    "Adjectives",
    "Adverbs",
    "Conjunctions",
    "Prefix & Suffix",
    "Sentence Structure",
    "Verbs"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this as WidgetsBindingObserver);

    // Initialize path animation controller
    pathAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 5000),
    );

    pathAnimation = CurvedAnimation(
        parent: pathAnimationController, curve: Curves.easeInCubic);

    // Start animations after frame is built
    if (isFirstBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startAnimations();
        isFirstBuild = false;
      });
    }
  }

  void startAnimations() {
    final questionState = context.read<QuestionState>();
    final lastDrawnLevelProvider = context.read<LastDrawnLevelProvider>();

    int lastUnlockedIndex = _getLastUnlockedLevel(context);

    if (lastUnlockedIndex > lastDrawnLevelProvider.lastDrawnLevel) {
      // Update the provider state
      lastDrawnLevelProvider.updateLastDrawnLevel(lastUnlockedIndex);

      // Start animation for the new path
      pathAnimationController.reset();
      pathAnimationController.duration = Duration(milliseconds: 3000);
      pathAnimationController.forward(from: 0.0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset and restart animation when app comes to foreground
      restartAnimation();
    }
  }

  void restartAnimation() {
    pathAnimationController.reset();
    startAnimations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    pathAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add route observer to detect when we return to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        restartAnimation();
      }
    });

    List<Offset> positions = [
      Offset(210, 50),
      Offset(70, 180),
      Offset(220, 300),
      Offset(50, 400),
      Offset(170, 550),
      Offset(60, 700),
      Offset(300, 900)
    ];

    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: restartAnimation,
      //   child: Icon(Icons.refresh),
      //   backgroundColor: Color(0xFF6165F0),
      // ),
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate scaling factor based on screen width
          double scaleFactor = constraints.maxWidth / 360; // Base design width

          // Dynamic positioning function
          Offset calculatePosition(Offset originalPosition) {
            return Offset(originalPosition.dx * scaleFactor,
                originalPosition.dy * scaleFactor);
          }

          // Dynamically scale positions
          List<Offset> dynamicPositions =
              positions.map((position) => calculatePosition(position)).toList();

          return SingleChildScrollView(
            child: Container(
              height: 800 * scaleFactor, // Scaled height
              child: Stack(
                children: [
                  // Animated Path
                  AnimatedBuilder(
                    animation: pathAnimation,
                    builder: (context, child) {
                      final lastDrawnLevel = context
                          .watch<LastDrawnLevelProvider>()
                          .lastDrawnLevel;

                      return CustomPaint(
                        painter: LevelPathPainter(
                          positions: dynamicPositions,
                          activeLevel:
                              LevelPathPainter.getActiveLevelFromState(context),
                          progress: pathAnimation.value,
                          lastDrawnLevel: lastDrawnLevel,
                        ),
                        child: Container(),
                      );
                    },
                  ),

                  // Level Indicators
                  ...levelss.asMap().entries.map((entry) {
                    int index = entry.key;
                    String label = entry.value;
                    final questionState = context.watch<QuestionState>();
                    final isLevelUnlocked =
                        questionState.isLevelUnlocked(label);
                    final isLevelCompleted =
                        questionState.completedLevels.contains(label);

                    return Positioned(
                      left: dynamicPositions[index].dx - 20 * scaleFactor,
                      top: dynamicPositions[index].dy - 20 * scaleFactor,
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 5000),
                        opacity: 1.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Circle Avatar (scaled)
                            AnimatedContainer(
                              duration: Duration(milliseconds: 5000),
                              child: CircleAvatar(
                                radius: 20 * scaleFactor,
                                backgroundColor: isLevelCompleted
                                    ? Colors.green
                                    : (isLevelUnlocked
                                        ? Color(0xFF6165F0)
                                        : Color(0xFF464758)),
                                child: CircleAvatar(
                                  radius: 10 * scaleFactor,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 5 * scaleFactor,
                                    backgroundColor: isLevelCompleted
                                        ? Colors.green
                                        : (isLevelUnlocked
                                            ? Color(0xFF6165F0)
                                            : Color(0xFF464758)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 2 * scaleFactor),
                            // Label Container (scaled)
                            AnimatedContainer(
                              duration: Duration(milliseconds: 5000),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scaleFactor,
                                  vertical: 8 * scaleFactor),
                              decoration: BoxDecoration(
                                color: isLevelCompleted
                                    ? Colors.green
                                    : (isLevelUnlocked
                                        ? Color(0xFF6165F0)
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: GestureDetector(
                                onTap: isLevelUnlocked
                                    ? () => _onLevelTap(index)
                                    : null,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: isLevelUnlocked
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 14 * scaleFactor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getLastUnlockedLevel(BuildContext context) {
    final questionState = context.read<QuestionState>();
    int lastUnlocked = -1;

    for (int i = 0; i < levelss.length; i++) {
      if (questionState.isLevelUnlocked(levelss[i])) {
        lastUnlocked = i;
      }
    }

    return lastUnlocked;
  }

  void _onLevelTap(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return ChooseExercise();
      },
    );
  }
}
