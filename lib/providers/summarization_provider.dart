import 'package:flutter/material.dart';
import '../services/gemma_service.dart';

class SummarizationProvider extends ChangeNotifier {
  final GemmaService _gemmaService = GemmaService();
  
  String _inputText = '';
  String _summary = '';
  String _error = '';
  bool _isLoading = false;

  String get inputText => _inputText;
  String get summary => _summary;
  String get error => _error;
  bool get isLoading => _isLoading;

  void updateInputText(String text) {
    _inputText = text;
    _error = '';
    notifyListeners();
  }

  Future<void> summarizeText() async {
    if (_inputText.trim().isEmpty) {
      _error = 'Please enter some text to summarize';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    _summary = '';
    notifyListeners();

    try {
      final result = await _gemmaService.summarizeText(_inputText);
      _summary = result;
      _error = '';
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _summary = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSummary() {
    _summary = '';
    _error = '';
    notifyListeners();
  }

  void clearAll() {
    _inputText = '';
    _summary = '';
    _error = '';
    _isLoading = false;
    notifyListeners();
  }
}
