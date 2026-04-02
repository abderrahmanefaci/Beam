import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../screens/tools_screen.dart';

/// Tool Card Widget
class ToolCard extends StatelessWidget {
  final ToolDefinition tool;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with background
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getToolColor(tool).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                tool.icon,
                color: _getToolColor(tool),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            // Tool name
            Text(
              tool.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BeamTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              tool.description,
              style: TextStyle(
                fontSize: 11,
                color: BeamTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // AI badge
            if (tool.isAiPowered)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: BeamTheme.accentAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: BeamTheme.accentAmber.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 10,
                      color: BeamTheme.accentAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: BeamTheme.accentAmber,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getToolColor(ToolDefinition tool) {
    switch (tool.category) {
      case ToolCategory.document:
        return BeamTheme.primaryPurple;
      case ToolCategory.ai:
        return BeamTheme.accentAmber;
      case ToolCategory.creation:
        return BeamTheme.successGreen;
    }
  }
}
