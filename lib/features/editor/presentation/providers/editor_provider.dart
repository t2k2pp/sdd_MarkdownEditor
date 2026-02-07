import 'package:flutter_riverpod/flutter_riverpod.dart';

/// エディターの表示モード
enum EditorMode {
  /// プレーンテキストエディター
  plainText,

  /// 純粋なプレビュー（読み取り専用）
  preview,

  /// 編集可能プレビュー
  editablePreview,
}

/// エディターの状態
class EditorState {
  final String content;
  final EditorMode mode;
  final int cursorPosition;

  const EditorState({
    this.content = '',
    this.mode = EditorMode.plainText,
    this.cursorPosition = 0,
  });

  EditorState copyWith({
    String? content,
    EditorMode? mode,
    int? cursorPosition,
  }) {
    return EditorState(
      content: content ?? this.content,
      mode: mode ?? this.mode,
      cursorPosition: cursorPosition ?? this.cursorPosition,
    );
  }
}

/// エディターのNotifier (Riverpod 3.x対応)
class EditorNotifier extends Notifier<EditorState> {
  @override
  EditorState build() {
    return const EditorState();
  }

  /// コンテンツを更新
  void updateContent(String content) {
    state = state.copyWith(content: content);
  }

  /// モードを切り替え
  void setMode(EditorMode mode) {
    state = state.copyWith(mode: mode);
  }

  /// カーソル位置を更新
  void updateCursorPosition(int position) {
    state = state.copyWith(cursorPosition: position);
  }

  /// カーソル位置にテキストを挿入
  void insertText(String text) {
    final before = state.content.substring(0, state.cursorPosition);
    final after = state.content.substring(state.cursorPosition);
    final newContent = '$before$text$after';
    final newPosition = state.cursorPosition + text.length;
    state = state.copyWith(content: newContent, cursorPosition: newPosition);
  }

  /// 選択範囲をラップ（太字、斜体など用）
  void wrapSelection(
    String prefix,
    String suffix,
    int selectionStart,
    int selectionEnd,
  ) {
    if (selectionStart == selectionEnd) {
      // 選択がない場合はカーソル位置に挿入
      insertText('$prefix$suffix');
      return;
    }

    final before = state.content.substring(0, selectionStart);
    final selected = state.content.substring(selectionStart, selectionEnd);
    final after = state.content.substring(selectionEnd);
    final newContent = '$before$prefix$selected$suffix$after';
    state = state.copyWith(content: newContent);
  }

  /// 行頭にテキストを挿入（見出し用）
  void insertAtLineStart(String prefix) {
    final lines = state.content.split('\n');
    int currentPos = 0;
    int lineIndex = 0;

    for (int i = 0; i < lines.length; i++) {
      if (currentPos + lines[i].length >= state.cursorPosition) {
        lineIndex = i;
        break;
      }
      currentPos += lines[i].length + 1;
    }

    lines[lineIndex] = '$prefix${lines[lineIndex]}';
    final newContent = lines.join('\n');
    state = state.copyWith(content: newContent);
  }
}

/// エディター状態のProvider (Riverpod 3.x)
final editorProvider = NotifierProvider<EditorNotifier, EditorState>(() {
  return EditorNotifier();
});
