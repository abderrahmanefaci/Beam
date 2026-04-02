import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';

/// Library Empty State Widget
class LibraryEmptyState extends StatelessWidget {
  final VoidCallback? onScanTap;

  const LibraryEmptyState({
    super.key,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: BeamTheme.primaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open,
                size: 64,
                color: BeamTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Your library is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Scan your first document to get started',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // CTA Button
            ElevatedButton.icon(
              onPressed: onScanTap,
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Document'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
