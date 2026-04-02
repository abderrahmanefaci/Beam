import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import '../../core/theme/beam_theme.dart';
import '../../core/constants/beam_constants.dart';
import '../widgets/scanner_preview_screen.dart';
import '../widgets/scanner_camera_overlay.dart';

/// Scanner Screen - Main camera capture screen
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _isProcessing = false;
  final List<File> _capturedImages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview with document scanner
          _buildScannerView(),
          // Top controls overlay
          _buildTopOverlay(),
          // Bottom capture button overlay
          _buildBottomOverlay(),
          // Processing indicator
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return CunningDocumentScanner(
      enableMerge: true,
      onCapturedImage: (File image) {
        setState(() {
          _capturedImages.add(image);
        });
        // Navigate to preview/review screen after capture
        _navigateToPreview();
      },
      errorBuilder: (context, error) {
        return _buildErrorState(error);
      },
      documentScannerOverlayWidgetBuilder: (context, actions) {
        return ScannerCameraOverlay(
          onBackPress: () => Navigator.of(context).pop(),
          onFlashToggle: actions.toggleFlash,
          onCapture: actions.capture,
        );
      },
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
            // Page counter
            if (_capturedImages.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: BeamTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_capturedImages.length} page${_capturedImages.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Flash toggle placeholder
            IconButton(
              icon: const Icon(Icons.flash_auto, color: Colors.white),
              onPressed: () {
                // Flash toggle handled by scanner package
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Capture button
              GestureDetector(
                onTap: _isProcessing ? null : _handleCapture,
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
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BeamTheme.primaryPurple),
            ),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_off,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCapture() {
    // Capture is handled by the scanner package via overlay
  }

  void _navigateToPreview() {
    if (_capturedImages.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannerPreviewScreen(
          capturedImages: _capturedImages,
          onScanComplete: () {
            // Clear captured images and return to scanner
            setState(() {
              _capturedImages.clear();
            });
            // Pop back to scanner home
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
}
