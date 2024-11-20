import 'package:flutter/material.dart';

class LastDrawnLevelProvider with ChangeNotifier {
  int _lastDrawnLevel = -1; // Initial value for the last drawn level

  int get lastDrawnLevel => _lastDrawnLevel;

  void updateLastDrawnLevel(int newLevel) {
    if (newLevel > _lastDrawnLevel) {
      _lastDrawnLevel = newLevel;
      notifyListeners(); // Notify listeners of the state change
    }
  }
}
