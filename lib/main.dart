import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'features/editor/presentation/pages/editor_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MarkdownMermaidEditorApp()));
}

class MarkdownMermaidEditorApp extends StatelessWidget {
  const MarkdownMermaidEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdown & Mermaid Editor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.notoSansJpTextTheme(
          AppTheme.lightTheme.textTheme,
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.notoSansJpTextTheme(
          AppTheme.darkTheme.textTheme,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const EditorPage(),
    );
  }
}
