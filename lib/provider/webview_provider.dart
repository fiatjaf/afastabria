import "package:flutter/material.dart";

class WebViewProvider extends ChangeNotifier {
  String? _url;

  bool _showable = true;

  String? get url => _url;

  bool get showable => _showable;

  void open(final String url) {
    _url = url;
    _showable = true;
    notifyListeners();
  }

  void close() {
    _url = null;
    _showable = false;
    notifyListeners();
  }

  void hide() {
    _showable = false;
    notifyListeners();
  }

  void show() {
    _showable = true;
    notifyListeners();
  }
}
