import 'package:flutter/material.dart';

class AnimationStateVM extends ChangeNotifier {
  bool _hasHeaderAnimated = false;
  bool _hasProfileScreenAnimated = false;

  bool get hasHeaderAnimated => _hasHeaderAnimated;
  bool get hasProfileScreenAnimated => _hasProfileScreenAnimated;

  void setHeaderAnimated(bool value) {
    _hasHeaderAnimated = value;
    notifyListeners();
  }

  void setProfileScreenAnimated(bool value) {
    _hasProfileScreenAnimated = value;
    notifyListeners();
  }

  void resetAllAnimations() {
    _hasHeaderAnimated = false;
    _hasProfileScreenAnimated = false;
    notifyListeners();
  }
}