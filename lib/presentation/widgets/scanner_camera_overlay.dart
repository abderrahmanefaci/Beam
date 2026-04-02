import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';

/// Scanner Camera Overlay Widget
/// Provides custom UI for the document scanner camera
class ScannerCameraOverlay extends StatelessWidget {
  final VoidCallback onBackPress;
  final VoidCallback onFlashToggle;
  final VoidCallback onCapture;

  const ScannerCameraOverlay({
    super.key,
    required this.onBackPress,
    required this.onFlashToggle,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBackPress,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                // Flash toggle
                IconButton(
                  icon: const Icon(Icons.flash_auto, color: Colors.white),
                  onPressed: onFlashToggle,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          // Center - edge detection overlay is shown by scanner package
          const Expanded(
            child: Center(
              child: Text(
                'Position document within the frame',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Bottom bar - capture button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
