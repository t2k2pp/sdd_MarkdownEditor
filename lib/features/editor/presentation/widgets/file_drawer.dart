import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

/// ファイル一覧を表示するサイドドロワー
class FileDrawer extends ConsumerWidget {
  const FileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ドキュメント',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 新規作成ボタン
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: '新規作成',
                    onPressed: () async {
                      await ref.read(fileProvider.notifier).createFile();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),

            // ファイル一覧
            Expanded(
              child: fileState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : fileState.files.isEmpty
                  ? _buildEmptyState(context, ref)
                  : _buildFileList(context, ref, fileState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'ドキュメントがありません',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('新規作成'),
            onPressed: () async {
              await ref.read(fileProvider.notifier).createFile();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(
    BuildContext context,
    WidgetRef ref,
    FileState fileState,
  ) {
    return ListView.builder(
      itemCount: fileState.files.length,
      itemBuilder: (context, index) {
        final file = fileState.files[index];
        final isSelected = fileState.currentFile?.id == file.id;

        return ListTile(
          leading: Icon(
            Icons.description_outlined,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          title: Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            _formatDate(file.modifiedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          selected: isSelected,
          selectedTileColor: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          onTap: () {
            ref.read(fileProvider.notifier).selectFile(file);
            Navigator.of(context).pop();
          },
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('複製'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('削除', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'duplicate') {
                await ref.read(fileProvider.notifier).duplicateFile(file);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } else if (value == 'delete') {
                final confirmed = await _showDeleteConfirmation(
                  context,
                  file.name,
                );
                if (confirmed && context.mounted) {
                  await ref.read(fileProvider.notifier).deleteFile(file);
                }
              }
            },
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String fileName,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('削除の確認'),
            content: Text('「$fileName」を削除しますか？\nこの操作は取り消せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('削除'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨日';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
