import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:beam/core/services/document_service.dart';
import 'package:beam/core/services/pdf_service.dart';
import 'package:beam/core/widgets/app_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final List<XFile> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller.initialize();
    } else {
      setState(() {
        // Handle permission denied
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      setState(() {
        _capturedImages.add(image);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  Future<void> _finishScanning() async {
    if (_capturedImages.isEmpty) return;

    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Convert images to bytes
      final imageBytes = <Uint8List>[];
      for (final image in _capturedImages) {
        final bytes = await File(image.path).readAsBytes();
        imageBytes.add(bytes);
      }

      // Create PDF
      final pdfService = PdfService();
      final pdfFile = await pdfService.createPdfFromImages(
        images: imageBytes,
        title: 'Scanned Document ${DateTime.now().millisecondsSinceEpoch}',
      );

      // Upload to storage and save to DB
      final documentService = DocumentService();
      await documentService.uploadDocument(
        title: 'Scanned Document',
        pdfFile: pdfFile,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan (${_capturedImages.length} pages)'),
        actions: [
          if (_capturedImages.isNotEmpty)
            TextButton(
              onPressed: _finishScanning,
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                // Capture button overlay
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.large(
                        onPressed: _takePicture,
                        child: const Icon(Icons.camera),
                      ),
                    ],
                  ),
                ),
                // Captured images indicator
                if (_capturedImages.isNotEmpty)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_capturedImages.length} page${_capturedImages.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}