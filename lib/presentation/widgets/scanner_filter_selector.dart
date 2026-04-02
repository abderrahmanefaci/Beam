import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../../services/scanner_service.dart';

/// Scanner Filter Selector Widget
class ScannerFilterSelector extends StatefulWidget {
  final ScannerFilter selectedFilter;
  final Function(ScannerFilter) onFilterSelected;

  const ScannerFilterSelector({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  State<ScannerFilterSelector> createState() => _ScannerFilterSelectorState();
}

class _ScannerFilterSelectorState extends State<ScannerFilterSelector> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ScannerFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = ScannerFilter.values[index];
          final isSelected = widget.selectedFilter == filter;

          return _FilterChip(
            filter: filter,
            isSelected: isSelected,
            onTap: () => widget.onFilterSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final ScannerFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? BeamTheme.primaryPurple
              : Colors.white,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter preview icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getFilterPreviewColor(filter),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFilterIcon(filter),
                color: isSelected ? Colors.white : Colors.black54,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            // Filter name
            Text(
              filter.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : BeamTheme.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterPreviewColor(ScannerFilter filter) {
    switch (filter) {
      case ScannerFilter.original:
        return Colors.grey.shade300;
      case ScannerFilter.blackWhite:
        return Colors.grey.shade700;
      case ScannerFilter.enhanced:
        return BeamTheme.accentTeal;
      case ScannerFilter.color:
        return BeamTheme.primaryPurple;
    }
  }

  IconData _getFilterIcon(ScannerFilter filter) {
    switch (filter) {
      case ScannerFilter.original:
        return Icons.photo;
      case ScannerFilter.blackWhite:
        return Icons.contrast;
      case ScannerFilter.enhanced:
        return AutoFixHigh;
      case ScannerFilter.color:
        return Icons.palette;
    }
  }

  // Custom icon for enhanced filter
  IconData get AutoFixHigh => Icons.auto_fix_high;
}
