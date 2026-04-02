import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../../domain/entities/entities.dart';

/// Folder Actions Bottom Sheet
class FolderActionsBottomSheet extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const FolderActionsBottomSheet({
    super.key,
    required this.folder,
    required this.onRename,
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
                    color: BeamTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder,
                    color: BeamTheme.primaryPurple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Folder',
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
              icon: Icons.edit,
              label: 'Rename',
              onTap: () {
                Navigator.of(context).pop();
                onRename();
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
