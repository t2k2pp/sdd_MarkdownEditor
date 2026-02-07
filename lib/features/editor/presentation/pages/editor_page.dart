import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/editor_provider.dart';
import '../widgets/editor_toolbar.dart';
import '../../../preview/presentation/widgets/markdown_preview.dart';

/// メインエディターページ
class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getInitialContent());
    _controller.addListener(_onTextChanged);
  }

  String _getInitialContent() {
    return '''# Markdown & Mermaid Editor へようこそ！

このエディターでは、**Markdown** と **Mermaid** ダイアグラムを編集・プレビューできます。

## 機能

- 📝 プレーンテキストエディター
- 👀 リアルタイムプレビュー
- 📊 Mermaidダイアグラム対応

## サンプルコード

${'```'}dart
void main() {
  print('Hello, Markdown!');
}
${'```'}

## チェックリスト

- [x] エディター実装
- [x] プレビュー実装
- [ ] その他の機能

> 💡 **ヒント**: ツールバーからMermaidサンプルを挿入できます！

''';
  }

  void _onTextChanged() {
    ref.read(editorProvider.notifier).updateContent(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Editor'),
        actions: [
          // モード切り替えボタン
          _ModeToggleButton(
            currentMode: editorState.mode,
            onModeChanged: (mode) {
              ref.read(editorProvider.notifier).setMode(mode);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ツールバー（エディターモード時のみ表示）
          if (editorState.mode != EditorMode.preview)
            EditorToolbar(controller: _controller),

          // メインコンテンツ
          Expanded(child: _buildContent(editorState)),
        ],
      ),
    );
  }

  Widget _buildContent(EditorState state) {
    switch (state.mode) {
      case EditorMode.plainText:
        return _PlainTextEditor(controller: _controller);

      case EditorMode.preview:
        return MarkdownPreviewWidget(
          content: _controller.text,
          isEditable: false,
        );

      case EditorMode.editablePreview:
        return _SplitView(
          editor: _PlainTextEditor(controller: _controller),
          preview: MarkdownPreviewWidget(
            content: _controller.text,
            isEditable: false,
          ),
        );
    }
  }
}

/// プレーンテキストエディター
class _PlainTextEditor extends StatelessWidget {
  final TextEditingController controller;

  const _PlainTextEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText: 'ここに Markdown を入力...',
        ),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }
}

/// 分割ビュー（エディター + プレビュー）
class _SplitView extends StatelessWidget {
  final Widget editor;
  final Widget preview;

  const _SplitView({required this.editor, required this.preview});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      // 縦向きの場合は上下分割
      return Column(
        children: [
          Expanded(child: editor),
          Container(height: 2, color: Theme.of(context).dividerTheme.color),
          Expanded(child: preview),
        ],
      );
    } else {
      // 横向きの場合は左右分割
      return Row(
        children: [
          Expanded(child: editor),
          Container(width: 2, color: Theme.of(context).dividerTheme.color),
          Expanded(child: preview),
        ],
      );
    }
  }
}

/// モード切り替えボタン
class _ModeToggleButton extends StatelessWidget {
  final EditorMode currentMode;
  final Function(EditorMode) onModeChanged;

  const _ModeToggleButton({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<EditorMode>(
      segments: const [
        ButtonSegment<EditorMode>(
          value: EditorMode.plainText,
          icon: Icon(Icons.edit_note, size: 18),
          tooltip: 'エディター',
        ),
        ButtonSegment<EditorMode>(
          value: EditorMode.editablePreview,
          icon: Icon(Icons.vertical_split, size: 18),
          tooltip: '分割表示',
        ),
        ButtonSegment<EditorMode>(
          value: EditorMode.preview,
          icon: Icon(Icons.visibility, size: 18),
          tooltip: 'プレビュー',
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (modes) {
        onModeChanged(modes.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}
