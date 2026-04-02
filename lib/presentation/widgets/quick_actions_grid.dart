import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';

/// Quick Actions Grid Widget
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        QuickActionItem(
          icon: Icons.document_scanner,
          label: 'Scan',
          color: BeamTheme.primaryPurple,
          onTap: () {
            // Navigate to scanner
            // TODO: Implement navigation
          },
        ),
        QuickActionItem(
          icon: Icons.upload_file,
          label: 'Upload',
          color: BeamTheme.accentTeal,
          onTap: () {
            // Upload file
            // TODO: Implement file picker
          },
        ),
        QuickActionItem(
          icon: Icons.note_add,
          label: 'Create',
          color: BeamTheme.accentAmber,
          onTap: () {
            // Create new document
            // TODO: Implement create document
          },
        ),
        QuickActionItem(
          icon: Icons.folder,
          label: 'Folder',
          color: BeamTheme.successGreen,
          onTap: () {
            // Create new folder
            // TODO: Implement create folder
          },
        ),
      ],
    );
  }
}

/// Quick Action Item Widget
class QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
