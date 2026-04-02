import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/beam_theme.dart';
import '../../services/scanner_service.dart';
import '../widgets/scanner_filter_selector.dart';
import '../widgets/scanner_format_selector.dart';
import 'document_viewer_screen.dart';

/// Scanner Preview/Review Screen
/// Shows captured pages, allows adding more pages, applying filters, and selecting output format
class ScannerPreviewScreen extends ConsumerStatefulWidget {
  final List<File> capturedImages;
  final VoidCallback onScanComplete;

  const ScannerPreviewScreen({
    super.key,
    required this.capturedImages,
    required this.onScanComplete,
  });

  @override
  ConsumerState<ScannerPreviewScreen> createState() => _ScannerPreviewScreenState();
}

class _ScannerPreviewScreenState extends ConsumerState<ScannerPreviewScreen> {
  final _scannerService = ScannerService();
  List<ScannedPage> _pages = [];
  ScannerFilter _selectedFilter = ScannerFilter.original;
  ScanOutputFormat _selectedFormat = ScanOutputFormat.pdf;
  bool _isProcessing = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = widget.capturedImages.map((image) {
      return ScannedPage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageFile: image,
        filter: _selectedFilter,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeamTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Review Scan'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _handleSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isProcessing
          ? _buildProcessingView()
          : Column(
              children: [
                // Page thumbnails
                _buildThumbnailsSection(),
                // Add page button
                _buildAddPageButton(),
                // Filter selector
                _buildFilterSelector(),
                // Format selector
                _buildFormatSelector(),
                // Info card
                _buildInfoCard(),
              ],
            ),
    );
  }

  Widget _buildProcessingView() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                valueColor: const AlwaysStoppedAnimation<Color>(BeamTheme.primaryPurple),
              ),
              const SizedBox(height: 24),
              const Text(
                'Processing your scan...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _uploadProgress > 0
                    ? 'Uploading... ${(_uploadProgress * 100).toInt()}%'
                    : 'Applying filters and rendering...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailsSection() {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pages (${_pages.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: BeamTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildPageThumbnail(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageThumbnail(int index) {
    final page = _pages[index];
    return Stack(
      children: [
        Container(
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              page.imageFile,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Page number
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: BeamTheme.primaryPurple,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Delete button
        if (_pages.length > 1)
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _deletePage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddPageButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _isProcessing ? null : _handleAddPage,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Page'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BeamTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          ScannerFilterSelector(
            selectedFilter: _selectedFilter,
            onFilterSelected: _handleFilterChange,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Output Format',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BeamTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          ScannerFormatSelector(
            selectedFormat: _selectedFormat,
            onFormatSelected: (format) {
              setState(() {
                _selectedFormat = format;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BeamTheme.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BeamTheme.primaryPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: BeamTheme.primaryPurple,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your scan will be saved to your Library and ready to view or edit.',
              style: TextStyle(
                fontSize: 13,
                color: BeamTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFilterChange(ScannerFilter filter) async {
    setState(() {
      _selectedFilter = filter;
    });

    // Apply filter to all pages
    for (int i = 0; i < _pages.length; i++) {
      final page = _pages[i];
      try {
        final processedBytes = await _scannerService.applyFilter(
          page.imageFile,
          filter,
        );
        setState(() {
          _pages[i] = ScannedPage(
            id: page.id,
            imageFile: page.imageFile,
            filter: filter,
            processedImage: processedBytes,
          );
        });
      } catch (e) {
        // Continue with original if filter fails
      }
    }
  }

  Future<void> _handleAddPage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image != null) {
        setState(() {
          _pages.add(ScannedPage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            imageFile: File(image.path),
            filter: _selectedFilter,
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  void _deletePage(int index) {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last page'),
          backgroundColor: BeamTheme.warningOrange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: const Text('Are you sure you want to delete this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pages.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: BeamTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pages to save'),
          backgroundColor: BeamTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simulate progress
      setState(() => _uploadProgress = 0.2);

      // Render to selected format
      Uint8List fileData;
      String fileName;
      String mimeType;

      switch (_selectedFormat) {
        case ScanOutputFormat.pdf:
          fileData = await _scannerService.renderToPdf(_pages);
          fileName = _scannerService.generateFilename('pdf');
          mimeType = _selectedFormat.mimeType;
          break;

        case ScanOutputFormat.docx:
          // For DOCX, we need to upload images first
          final imageFiles = _pages.map((p) => p.imageFile).toList();
          fileData = await _scannerService.convertToDocx(imageFiles);
          fileName = _scannerService.generateFilename('docx');
          mimeType = _selectedFormat.mimeType;
          break;

        case ScanOutputFormat.jpg:
          // For single image or first page
          fileData = _pages.first.processedImage ?? await _pages.first.imageFile.readAsBytes();
          fileName = _scannerService.generateFilename('jpg');
          mimeType = _selectedFormat.mimeType;
          break;

        case ScanOutputFormat.png:
          fileData = _pages.first.processedImage ?? await _pages.first.imageFile.readAsBytes();
          fileName = _scannerService.generateFilename('png');
          mimeType = _selectedFormat.mimeType;
          break;
      }

      setState(() => _uploadProgress = 0.5);

      // Upload to storage
      final fileUrl = await _scannerService.uploadToStorage(
        fileData: fileData,
        fileName: fileName,
        fileType: mimeType,
      );

      setState(() => _uploadProgress = 0.8);

      // Save to database
      final documentData = await _scannerService.saveScanToDatabase(
        title: _scannerService.generateScanTitle(),
        fileType: _selectedFormat.extension,
        fileSize: _scannerService.getFileSize(fileData),
        fileUrl: fileUrl,
      );

      setState(() => _uploadProgress = 1.0);

      // Show success and navigate to viewer
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to library'),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => DocumentViewerScreen(
                      document: _documentFromData(documentData),
                    ),
                  ),
                  (route) => route.isFirst,
                );
              },
            ),
            backgroundColor: BeamTheme.successGreen,
          ),
        );

        widget.onScanComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  // Helper to create DocumentEntity from database response
  dynamic _documentFromData(Map<String, dynamic> data) {
    // This is a simplified version - in production, use proper model mapping
    return data;
  }
}
