import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/editor_provider.dart';
import '../providers/file_provider.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/file_drawer.dart';
import '../../../preview/presentation/widgets/markdown_preview.dart';

/// メインエディターページ
class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late TextEditingController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isToolbarExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    ref.read(editorProvider.notifier).updateContent(_controller.text);
    // 自動保存
    ref.read(fileProvider.notifier).saveCurrentFile(_controller.text);
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
    final fileState = ref.watch(fileProvider);

    // ファイルが変更されたらコントローラーを更新
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.currentFile != null &&
          (previous?.currentFile?.id != next.currentFile?.id)) {
        _controller.text = next.currentFile!.content;
      }
    });

    // 初回ロード時
    if (fileState.currentFile != null && _controller.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = fileState.currentFile!.content;
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const FileDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'ファイル一覧',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          fileState.currentFile?.name ?? 'ドキュメントを選択',
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 共有ボタン
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '共有',
            onPressed: fileState.currentFile != null
                ? () => _shareContent(fileState.currentFile!.content)
                : null,
          ),
          // ツールバー表示切替
          IconButton(
            icon: Icon(
              _isToolbarExpanded ? Icons.keyboard_hide : Icons.keyboard,
            ),
            tooltip: _isToolbarExpanded ? 'ツールバーを隠す' : 'ツールバーを表示',
            onPressed: () {
              setState(() {
                _isToolbarExpanded = !_isToolbarExpanded;
              });
            },
          ),
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
          // ツールバー（折りたたみ可能、エディターモード時のみ）
          if (editorState.mode != EditorMode.preview)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isToolbarExpanded ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isToolbarExpanded ? 1.0 : 0.0,
                child: _isToolbarExpanded
                    ? EditorToolbar(controller: _controller)
                    : const SizedBox.shrink(),
              ),
            ),

          // メインコンテンツ
          Expanded(child: _buildContent(editorState, fileState)),
        ],
      ),
    );
  }

  void _shareContent(String content) {
    SharePlus.instance.share(ShareParams(text: content));
  }

  Widget _buildContent(EditorState editorState, FileState fileState) {
    if (fileState.currentFile == null) {
      return _buildNoFileSelected();
    }

    switch (editorState.mode) {
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

  Widget _buildNoFileSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'ドキュメントを選択してください',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.menu),
                label: const Text('ファイル一覧'),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('新規作成'),
                onPressed: () async {
                  await ref.read(fileProvider.notifier).createFile();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// プレーンテキストエディター（スクロールバー常時表示）
class _PlainTextEditor extends StatelessWidget {
  final TextEditingController controller;

  const _PlainTextEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Scrollbar(
        thumbVisibility: true,
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
      return Column(
        children: [
          Expanded(child: editor),
          Container(height: 2, color: Theme.of(context).dividerTheme.color),
          Expanded(child: preview),
        ],
      );
    } else {
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
