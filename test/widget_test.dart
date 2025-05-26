import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gemma_notes/main.dart';
import 'package:flutter_gemma_notes/providers/notes_provider.dart';

void main() {
  testWidgets('Notes app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => NotesProvider(),
        child: const NotesApp(),
      ),
    );

    // Verify that the app starts correctly
    expect(find.text('Notes'), findsOneWidget);
  });
}
