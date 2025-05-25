import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gemma_summarizer/main.dart';
import 'package:flutter_gemma_summarizer/providers/summarization_provider.dart';

void main() {
  group('Flutter Gemma Summarizer Tests', () {
    testWidgets('App should display title and input field', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the app title is displayed
      expect(find.text('Gemma Text Summarizer'), findsOneWidget);
      
      // Verify that the input text label is displayed
      expect(find.text('Enter text to summarize:'), findsOneWidget);
      
      // Verify that the summarize button is present
      expect(find.text('Summarize'), findsOneWidget);
    });

    testWidgets('Text input should update character count', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Find the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter some text
      await tester.enterText(textField, 'This is a test text');
      await tester.pump();

      // Verify character count is displayed
      expect(find.textContaining('Characters: 19'), findsOneWidget);
    });

    testWidgets('Summarize button should be disabled when no text', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Find the summarize button
      final button = find.widgetWithText(ElevatedButton, 'Summarize');
      expect(button, findsOneWidget);

      // Tap the button without entering text
      await tester.tap(button);
      await tester.pump();

      // Should show snackbar with error message
      expect(find.text('Please enter some text to summarize'), findsOneWidget);
    });

    testWidgets('Should show loading indicator when summarizing', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Enter some text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'This is a long text that needs to be summarized for testing purposes.');
      await tester.pump();

      // Tap the summarize button
      final button = find.widgetWithText(ElevatedButton, 'Summarize');
      await tester.tap(button);
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SummarizationProvider Tests', () {
    test('Should update input text correctly', () {
      final provider = SummarizationProvider();
      
      provider.updateInputText('Test text');
      
      expect(provider.inputText, 'Test text');
      expect(provider.error, '');
    });

    test('Should clear all data correctly', () {
      final provider = SummarizationProvider();
      
      provider.updateInputText('Test text');
      provider.clearAll();
      
      expect(provider.inputText, '');
      expect(provider.summary, '');
      expect(provider.error, '');
      expect(provider.isLoading, false);
    });

    test('Should handle empty text summarization', () async {
      final provider = SummarizationProvider();
      
      await provider.summarizeText();
      
      expect(provider.error, 'Please enter some text to summarize');
      expect(provider.summary, '');
    });
  });
}
