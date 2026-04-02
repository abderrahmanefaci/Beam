import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../../domain/entities/entities.dart';

/// Library Folder Card Widget
class LibraryFolderCard extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const LibraryFolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BeamTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Folder icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BeamTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder,
                size: 32,
                color: BeamTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            // Folder name
            Text(
              folder.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BeamTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
