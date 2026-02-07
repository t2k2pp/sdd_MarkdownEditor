// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:markdown_mermaid_editor/main.dart';

void main() {
  testWidgets('Editor page shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: MarkdownMermaidEditorApp()),
    );

    // Verify that the app title is present
    expect(find.text('Markdown Editor'), findsOneWidget);
  });
}
