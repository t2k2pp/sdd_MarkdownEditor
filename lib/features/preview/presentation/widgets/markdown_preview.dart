import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Markdownプレビューウィジェット
class MarkdownPreviewWidget extends StatelessWidget {
  final String content;
  final bool isEditable;
  final Function(String)? onContentChanged;

  const MarkdownPreviewWidget({
    super.key,
    required this.content,
    this.isEditable = false,
    this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Mermaidブロックとその他のコンテンツを分離
    final parts = _parseMermaidBlocks(content);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parts.length,
      itemBuilder: (context, index) {
        final part = parts[index];
        if (part.isMermaid) {
          return MermaidRenderer(mermaidCode: part.content);
        } else {
          return MarkdownBody(
            data: part.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              h2: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              h3: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              p: Theme.of(context).textTheme.bodyLarge,
              code: TextStyle(
                backgroundColor: Theme.of(context).colorScheme.surface,
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 4,
                  ),
                ),
              ),
              blockquotePadding: const EdgeInsets.only(left: 16),
              tableBorder: TableBorder.all(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey,
              ),
              tableHead: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        }
      },
    );
  }

  /// Mermaidブロックを解析
  List<ContentPart> _parseMermaidBlocks(String markdown) {
    final parts = <ContentPart>[];
    final mermaidRegex = RegExp(r'```mermaid\n([\s\S]*?)```', multiLine: true);

    int lastEnd = 0;
    for (final match in mermaidRegex.allMatches(markdown)) {
      // Mermaid前のテキスト
      if (match.start > lastEnd) {
        final beforeText = markdown.substring(lastEnd, match.start).trim();
        if (beforeText.isNotEmpty) {
          parts.add(ContentPart(content: beforeText, isMermaid: false));
        }
      }
      // Mermaidブロック
      parts.add(ContentPart(content: match.group(1)!.trim(), isMermaid: true));
      lastEnd = match.end;
    }

    // 残りのテキスト
    if (lastEnd < markdown.length) {
      final afterText = markdown.substring(lastEnd).trim();
      if (afterText.isNotEmpty) {
        parts.add(ContentPart(content: afterText, isMermaid: false));
      }
    }

    if (parts.isEmpty) {
      parts.add(ContentPart(content: markdown, isMermaid: false));
    }

    return parts;
  }
}

/// コンテンツパーツ
class ContentPart {
  final String content;
  final bool isMermaid;

  ContentPart({required this.content, required this.isMermaid});
}

/// Mermaidレンダラー
class MermaidRenderer extends StatefulWidget {
  final String mermaidCode;

  const MermaidRenderer({super.key, required this.mermaidCode});

  @override
  State<MermaidRenderer> createState() => _MermaidRendererState();
}

class _MermaidRendererState extends State<MermaidRenderer> {
  late final WebViewController _controller;
  double _height = 300;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterHeight',
        onMessageReceived: (message) {
          final height = double.tryParse(message.message);
          if (height != null && height > 0) {
            setState(() {
              _height = height + 32; // padding
            });
          }
        },
      )
      ..loadHtmlString(_buildHtml(widget.mermaidCode));
  }

  @override
  void didUpdateWidget(MermaidRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mermaidCode != widget.mermaidCode) {
      _controller.loadHtmlString(_buildHtml(widget.mermaidCode));
    }
  }

  String _buildHtml(String mermaidCode) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <style>
    body {
      margin: 0;
      padding: 16px;
      background-color: transparent;
      display: flex;
      justify-content: center;
    }
    .mermaid {
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="mermaid">
$mermaidCode
  </div>
  <script>
    mermaid.initialize({
      startOnLoad: true,
      theme: 'dark',
      securityLevel: 'loose',
    });
    
    // レンダリング後に高さを通知
    setTimeout(() => {
      const height = document.body.scrollHeight;
      if (window.FlutterHeight) {
        FlutterHeight.postMessage(height.toString());
      }
    }, 500);
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? Colors.grey,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller),
    );
  }
}
