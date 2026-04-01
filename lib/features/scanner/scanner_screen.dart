import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:beam/core/widgets/app_button.dart';
import 'package:beam/features/scanner/camera_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.document_scanner,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready to scan?',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Position your document in good lighting and tap scan to begin.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            AppButton(
              text: 'Start Scanning',
              onPressed: () async {
                try {
                  final cameras = await availableCameras();
                  if (cameras.isNotEmpty) {
                    if (context.mounted) {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(camera: cameras.first),
                        ),
                      );
                      if (result != null && context.mounted) {
                        // Navigate back to home or library
                        context.go('/home');
                      }
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Camera error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement gallery picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gallery import coming soon!')),
                );
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Import from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}