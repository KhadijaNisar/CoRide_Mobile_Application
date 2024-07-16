import 'package:flutter/cupertino.dart';

class ModeToggle extends ChangeNotifier {
  bool _isDriverMode = true;
  bool get isDriverMode => _isDriverMode;

  void toggleMode() {
    _isDriverMode = !_isDriverMode;
    notifyListeners();
  }
}
