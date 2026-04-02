import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../../domain/entities/entities.dart';

/// File Actions Bottom Sheet
class FileActionsBottomSheet extends StatelessWidget {
  final DocumentEntity document;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onMove;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const FileActionsBottomSheet({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onRename,
    required this.onDuplicate,
    required this.onMove,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileColor(document.fileType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(document.fileType),
                    color: _getFileColor(document.fileType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        document.formattedFileSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: BeamTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Actions
            _ActionItem(
              icon: Icons.visibility,
              label: 'Open',
              onTap: () {
                Navigator.of(context).pop();
                onOpen();
              },
            ),
            _ActionItem(
              icon: Icons.edit,
              label: 'Rename',
              onTap: () {
                Navigator.of(context).pop();
                onRename();
              },
            ),
            _ActionItem(
              icon: Icons.file_copy,
              label: 'Duplicate',
              onTap: () {
                Navigator.of(context).pop();
                onDuplicate();
              },
            ),
            _ActionItem(
              icon: Icons.folder_move,
              label: 'Move to folder',
              onTap: () {
                Navigator.of(context).pop();
                onMove();
              },
            ),
            _ActionItem(
              icon: Icons.share,
              label: 'Share',
              onTap: () {
                Navigator.of(context).pop();
                onShare();
              },
            ),
            _ActionItem(
              icon: Icons.delete,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.presentation;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? BeamTheme.errorRed : BeamTheme.textPrimaryLight,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? BeamTheme.errorRed : BeamTheme.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
