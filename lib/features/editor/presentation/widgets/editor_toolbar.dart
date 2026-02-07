import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/mermaid_samples.dart';

/// エディターツールバー（スクロール可能、コンパクト配置）
class EditorToolbar extends ConsumerWidget {
  final TextEditingController controller;

  const EditorToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
            _CompactDropdown(
              icon: Icons.title,
              tooltip: '見出し',
              items: List.generate(6, (i) => 'H${i + 1}'),
              onSelected: (value) {
                final level = int.parse(value.substring(1));
                final prefix = '#' * level + ' ';
                _insertAtLineStart(controller, prefix);
              },
            ),
            _divider(context),

            // 書式ボタン (グループ1: よく使う)
            _IconBtn(
              Icons.format_bold,
              '太字',
              () => _wrapText(controller, '**', '**'),
            ),
            _IconBtn(
              Icons.format_italic,
              '斜体',
              () => _wrapText(controller, '_', '_'),
            ),
            _IconBtn(Icons.code, 'コード', () => _wrapText(controller, '`', '`')),
            _divider(context),

            // リスト
            _IconBtn(
              Icons.format_list_bulleted,
              '箇条書き',
              () => _insertAtLineStart(controller, '- '),
            ),
            _IconBtn(
              Icons.check_box_outlined,
              'チェック',
              () => _insertAtLineStart(controller, '- [ ] '),
            ),
            _divider(context),

            // リンク・画像
            _IconBtn(
              Icons.link,
              'リンク',
              () => _wrapText(controller, '[', '](url)'),
            ),
            _IconBtn(
              Icons.image,
              '画像',
              () => _insertText(controller, '![alt](url)'),
            ),
            _divider(context),

            // その他 (Moreメニュー)
            _MoreMenu(controller: controller),
            _divider(context),

            // Mermaid
            _MermaidDropdown(controller: controller),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).dividerTheme.color?.withValues(alpha: 0.5),
    );
  }
}

/// コンパクトなドロップダウン
class _CompactDropdown extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final List<String> items;
  final Function(String) onSelected;

  const _CompactDropdown({
    required this.icon,
    required this.tooltip,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem<String>(
          value: item,
          height: 36,
          child: Text(item),
        );
      }).toList(),
      onSelected: onSelected,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}

/// アイコンボタン（コンパクト版）
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconBtn(this.icon, this.tooltip, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

/// その他のオプションメニュー
class _MoreMenu extends StatelessWidget {
  final TextEditingController controller;

  const _MoreMenu({required this.controller});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'その他',
      padding: EdgeInsets.zero,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.more_horiz, size: 18)],
        ),
      ),
      itemBuilder: (context) => [
        _menuItem('strikethrough', Icons.strikethrough_s, '取り消し線'),
        _menuItem('numbered', Icons.format_list_numbered, '番号付きリスト'),
        _menuItem('quote', Icons.format_quote, '引用'),
        _menuItem('hr', Icons.horizontal_rule, '水平線'),
        _menuItem('table', Icons.table_chart, 'テーブル'),
        _menuItem('codeblock', Icons.data_object, 'コードブロック'),
      ],
      onSelected: (value) {
        switch (value) {
          case 'strikethrough':
            _wrapText(controller, '~~', '~~');
            break;
          case 'numbered':
            _insertAtLineStart(controller, '1. ');
            break;
          case 'quote':
            _insertAtLineStart(controller, '> ');
            break;
          case 'hr':
            _insertText(controller, '\n---\n');
            break;
          case 'table':
            _insertTable(controller);
            break;
          case 'codeblock':
            _insertCodeBlock(controller);
            break;
        }
      },
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
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
      tooltip: 'Mermaid図を挿入',
      padding: EdgeInsets.zero,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schema_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Mermaid',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => MermaidSamples.allSamples.map((sample) {
        return PopupMenuItem<MermaidSampleItem>(
          value: sample,
          height: 40,
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

// ヘルパー関数

void _wrapText(TextEditingController controller, String prefix, String suffix) {
  final selection = controller.selection;
  final text = controller.text;

  if (selection.isCollapsed) {
    final newText = '$prefix$suffix';
    final cursorPos = selection.start;
    controller.text =
        text.substring(0, cursorPos) + newText + text.substring(cursorPos);
    controller.selection = TextSelection.collapsed(
      offset: cursorPos + prefix.length,
    );
  } else {
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

void _insertAtLineStart(TextEditingController controller, String prefix) {
  final text = controller.text;
  final selection = controller.selection;
  final cursorPos = selection.start;

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

void _insertTable(TextEditingController controller) {
  const table = '''

| 列1 | 列2 | 列3 |
|-----|-----|-----|
| A1  | B1  | C1  |
| A2  | B2  | C2  |

''';
  _insertText(controller, table);
}

void _insertCodeBlock(TextEditingController controller) {
  const codeBlock = '''

```
code here
```

''';
  _insertText(controller, codeBlock);
}
