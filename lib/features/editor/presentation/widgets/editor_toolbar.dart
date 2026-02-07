import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/mermaid_samples.dart';

/// エディターツールバー
class EditorToolbar extends ConsumerWidget {
  final TextEditingController controller;

  const EditorToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color ?? Colors.grey,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 見出しボタン
            _HeadingDropdown(controller: controller),
            const _ToolbarDivider(),

            // 書式ボタン
            _ToolbarButton(
              icon: Icons.format_bold,
              tooltip: '太字',
              onPressed: () => _wrapText(controller, '**', '**'),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              tooltip: '斜体',
              onPressed: () => _wrapText(controller, '_', '_'),
            ),
            _ToolbarButton(
              icon: Icons.strikethrough_s,
              tooltip: '取り消し線',
              onPressed: () => _wrapText(controller, '~~', '~~'),
            ),
            _ToolbarButton(
              icon: Icons.code,
              tooltip: 'インラインコード',
              onPressed: () => _wrapText(controller, '`', '`'),
            ),
            const _ToolbarDivider(),

            // リストボタン
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: '箇条書きリスト',
              onPressed: () => _insertAtLineStart(controller, '- '),
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: '番号付きリスト',
              onPressed: () => _insertAtLineStart(controller, '1. '),
            ),
            _ToolbarButton(
              icon: Icons.check_box_outlined,
              tooltip: 'チェックリスト',
              onPressed: () => _insertAtLineStart(controller, '- [ ] '),
            ),
            const _ToolbarDivider(),

            // その他のマークダウン要素
            _ToolbarButton(
              icon: Icons.format_quote,
              tooltip: '引用',
              onPressed: () => _insertAtLineStart(controller, '> '),
            ),
            _ToolbarButton(
              icon: Icons.horizontal_rule,
              tooltip: '水平線',
              onPressed: () => _insertText(controller, '\n---\n'),
            ),
            _ToolbarButton(
              icon: Icons.link,
              tooltip: 'リンク',
              onPressed: () => _wrapText(controller, '[', '](url)'),
            ),
            _ToolbarButton(
              icon: Icons.image,
              tooltip: '画像',
              onPressed: () =>
                  _insertText(controller, '![alt text](image_url)'),
            ),
            _ToolbarButton(
              icon: Icons.table_chart,
              tooltip: 'テーブル',
              onPressed: () => _insertTable(controller),
            ),
            _ToolbarButton(
              icon: Icons.data_object,
              tooltip: 'コードブロック',
              onPressed: () => _insertCodeBlock(controller),
            ),
            const _ToolbarDivider(),

            // Mermaidサンプル
            _MermaidDropdown(controller: controller),
          ],
        ),
      ),
    );
  }
}

/// 見出しドロップダウン
class _HeadingDropdown extends StatelessWidget {
  final TextEditingController controller;

  const _HeadingDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.title, size: 20),
            SizedBox(width: 4),
            Text('見出し'),
            Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => List.generate(6, (index) {
        final level = index + 1;
        return PopupMenuItem<int>(
          value: level,
          child: Text('H$level - 見出し$level'),
        );
      }),
      onSelected: (level) {
        final prefix = '#' * level + ' ';
        _insertAtLineStart(controller, prefix);
      },
    );
  }
}

/// Mermaidサンプルドロップダウン
class _MermaidDropdown extends StatelessWidget {
  final TextEditingController controller;

  const _MermaidDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MermaidSampleItem>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schema_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Mermaid',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => MermaidSamples.allSamples.map((sample) {
        return PopupMenuItem<MermaidSampleItem>(
          value: sample,
          child: Row(
            children: [
              Text(sample.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(sample.name),
            ],
          ),
        );
      }).toList(),
      onSelected: (sample) {
        _insertText(controller, '\n${sample.template}\n');
      },
    );
  }
}

/// ツールバーボタン
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

/// ツールバー区切り線
class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).dividerTheme.color,
    );
  }
}

// ヘルパー関数

/// テキストをラップ（太字、斜体など）
void _wrapText(TextEditingController controller, String prefix, String suffix) {
  final selection = controller.selection;
  final text = controller.text;

  if (selection.isCollapsed) {
    // 選択がない場合はプレースホルダーを挿入
    final newText = '$prefix$suffix';
    final cursorPos = selection.start;
    controller.text =
        text.substring(0, cursorPos) + newText + text.substring(cursorPos);
    controller.selection = TextSelection.collapsed(
      offset: cursorPos + prefix.length,
    );
  } else {
    // 選択範囲をラップ
    final selectedText = text.substring(selection.start, selection.end);
    final newText = '$prefix$selectedText$suffix';
    controller.text =
        text.substring(0, selection.start) +
        newText +
        text.substring(selection.end);
    controller.selection = TextSelection.collapsed(
      offset: selection.start + newText.length,
    );
  }
}

/// テキストを挿入
void _insertText(TextEditingController controller, String insertText) {
  final selection = controller.selection;
  final text = controller.text;
  final cursorPos = selection.isCollapsed ? selection.start : selection.end;

  controller.text =
      text.substring(0, cursorPos) + insertText + text.substring(cursorPos);
  controller.selection = TextSelection.collapsed(
    offset: cursorPos + insertText.length,
  );
}

/// 行頭にテキストを挿入
void _insertAtLineStart(TextEditingController controller, String prefix) {
  final text = controller.text;
  final selection = controller.selection;
  final cursorPos = selection.start;

  // 現在の行の開始位置を見つける
  int lineStart = cursorPos;
  while (lineStart > 0 && text[lineStart - 1] != '\n') {
    lineStart--;
  }

  controller.text =
      text.substring(0, lineStart) + prefix + text.substring(lineStart);
  controller.selection = TextSelection.collapsed(
    offset: cursorPos + prefix.length,
  );
}

/// テーブルを挿入
void _insertTable(TextEditingController controller) {
  const table = '''

| 列1 | 列2 | 列3 |
|-----|-----|-----|
| A1  | B1  | C1  |
| A2  | B2  | C2  |

''';
  _insertText(controller, table);
}

/// コードブロックを挿入
void _insertCodeBlock(TextEditingController controller) {
  const codeBlock = '''

```
code here
```

''';
  _insertText(controller, codeBlock);
}
