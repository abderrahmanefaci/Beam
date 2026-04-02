import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../../services/scanner_service.dart';

/// Scanner Format Selector Widget
class ScannerFormatSelector extends StatelessWidget {
  final ScanOutputFormat selectedFormat;
  final Function(ScanOutputFormat) onFormatSelected;

  const ScannerFormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ScanOutputFormat.values.map((format) {
        final isSelected = selectedFormat == format;
        return _FormatChip(
          format: format,
          isSelected: isSelected,
          onTap: () => onFormatSelected(format),
        );
      }).toList(),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final ScanOutputFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? BeamTheme.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BeamTheme.primaryPurple
                : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: BeamTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFormatIcon(format),
              color: isSelected ? Colors.white : BeamTheme.textPrimaryLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              format.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : BeamTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFormatIcon(ScanOutputFormat format) {
    switch (format) {
      case ScanOutputFormat.pdf:
        return Icons.picture_as_pdf;
      case ScanOutputFormat.docx:
        return Icons.description;
      case ScanOutputFormat.jpg:
      case ScanOutputFormat.png:
        return Icons.image;
    }
  }
}
