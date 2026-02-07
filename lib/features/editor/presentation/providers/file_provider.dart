import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// ファイル情報を表すモデル
class MarkdownFile {
  final String id;
  final String name;
  final String content;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const MarkdownFile({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
  });

  MarkdownFile copyWith({String? name, String? content, DateTime? modifiedAt}) {
    return MarkdownFile(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }

  /// ファイル名からパスを生成
  String get fileName => '$id.md';
}

/// ファイル管理の状態
class FileState {
  final List<MarkdownFile> files;
  final MarkdownFile? currentFile;
  final bool isLoading;

  const FileState({
    this.files = const [],
    this.currentFile,
    this.isLoading = false,
  });

  FileState copyWith({
    List<MarkdownFile>? files,
    MarkdownFile? currentFile,
    bool? isLoading,
    bool clearCurrentFile = false,
  }) {
    return FileState(
      files: files ?? this.files,
      currentFile: clearCurrentFile ? null : (currentFile ?? this.currentFile),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// ファイル管理のNotifier
class FileNotifier extends Notifier<FileState> {
  @override
  FileState build() {
    _loadFiles();
    return const FileState(isLoading: true);
  }

  /// ストレージディレクトリを取得
  Future<Directory> _getStorageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${appDir.path}/markdown_files');
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    return storageDir;
  }

  /// ファイル一覧を読み込み
  Future<void> _loadFiles() async {
    try {
      final dir = await _getStorageDir();
      final files = <MarkdownFile>[];

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.md')) {
          final content = await entity.readAsString();
          final stat = await entity.stat();
          final fileName = entity.path.split('/').last;
          final id = fileName.replaceAll('.md', '');

          // ファイル名を内容の最初の行から取得（# で始まる場合）
          String name = 'Untitled';
          final lines = content.split('\n');
          if (lines.isNotEmpty && lines.first.startsWith('# ')) {
            name = lines.first.substring(2).trim();
          } else {
            name = id;
          }

          files.add(
            MarkdownFile(
              id: id,
              name: name,
              content: content,
              createdAt: stat.changed,
              modifiedAt: stat.modified,
            ),
          );
        }
      }

      // 更新日時でソート（新しい順）
      files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      state = state.copyWith(
        files: files,
        isLoading: false,
        currentFile: files.isNotEmpty ? files.first : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 新規ファイル作成
  Future<MarkdownFile> createFile({String? name}) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final fileName = name ?? '新規ドキュメント';
    final initialContent = '# $fileName\n\n';

    final newFile = MarkdownFile(
      id: id,
      name: fileName,
      content: initialContent,
      createdAt: now,
      modifiedAt: now,
    );

    await _saveFile(newFile);

    state = state.copyWith(
      files: [newFile, ...state.files],
      currentFile: newFile,
    );

    return newFile;
  }

  /// ファイルを選択
  void selectFile(MarkdownFile file) {
    state = state.copyWith(currentFile: file);
  }

  /// ファイルを保存
  Future<void> saveCurrentFile(String content) async {
    if (state.currentFile == null) return;

    // ファイル名を内容の最初の行から取得
    String name = state.currentFile!.name;
    final lines = content.split('\n');
    if (lines.isNotEmpty && lines.first.startsWith('# ')) {
      name = lines.first.substring(2).trim();
    }

    final updatedFile = state.currentFile!.copyWith(
      name: name,
      content: content,
      modifiedAt: DateTime.now(),
    );

    await _saveFile(updatedFile);

    final updatedFiles = state.files.map((f) {
      return f.id == updatedFile.id ? updatedFile : f;
    }).toList();

    state = state.copyWith(files: updatedFiles, currentFile: updatedFile);
  }

  /// ファイルをストレージに保存
  Future<void> _saveFile(MarkdownFile file) async {
    final dir = await _getStorageDir();
    final filePath = '${dir.path}/${file.fileName}';
    await File(filePath).writeAsString(file.content);
  }

  /// ファイルを削除
  Future<void> deleteFile(MarkdownFile file) async {
    final dir = await _getStorageDir();
    final filePath = '${dir.path}/${file.fileName}';
    final fileToDelete = File(filePath);

    if (await fileToDelete.exists()) {
      await fileToDelete.delete();
    }

    final updatedFiles = state.files.where((f) => f.id != file.id).toList();

    state = state.copyWith(
      files: updatedFiles,
      currentFile: state.currentFile?.id == file.id
          ? (updatedFiles.isNotEmpty ? updatedFiles.first : null)
          : state.currentFile,
      clearCurrentFile:
          state.currentFile?.id == file.id && updatedFiles.isEmpty,
    );
  }

  /// ファイルを複製
  Future<MarkdownFile> duplicateFile(MarkdownFile file) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final newName = '${file.name} (コピー)';

    // コンテンツの最初の行も更新
    String newContent = file.content;
    final lines = newContent.split('\n');
    if (lines.isNotEmpty && lines.first.startsWith('# ')) {
      lines[0] = '# $newName';
      newContent = lines.join('\n');
    }

    final newFile = MarkdownFile(
      id: id,
      name: newName,
      content: newContent,
      createdAt: now,
      modifiedAt: now,
    );

    await _saveFile(newFile);

    state = state.copyWith(
      files: [newFile, ...state.files],
      currentFile: newFile,
    );

    return newFile;
  }

  /// ファイル一覧を再読み込み
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadFiles();
  }
}

/// ファイル管理プロバイダー
final fileProvider = NotifierProvider<FileNotifier, FileState>(() {
  return FileNotifier();
});
