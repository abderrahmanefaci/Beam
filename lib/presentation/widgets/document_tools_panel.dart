import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../screens/tools_screen.dart';
import 'tool_preview_screen.dart';

/// Document Tools Panel - Bottom sheet for document tools
class DocumentToolsPanel extends StatefulWidget {
  final ToolDefinition tool;

  const DocumentToolsPanel({super.key, required this.tool});

  @override
  State<DocumentToolsPanel> createState() => _DocumentToolsPanelState();
}

class _DocumentToolsPanelState extends State<DocumentToolsPanel> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: BeamTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BeamTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.tool.icon,
                      color: BeamTheme.primaryPurple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tool.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.tool.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: BeamTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tool interface
            _buildToolInterface(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolInterface() {
    switch (widget.tool.id) {
      case 'merge_pdf':
        return _buildMergePdfInterface();
      case 'split_pdf':
        return _buildSplitPdfInterface();
      case 'compress_pdf':
        return _buildCompressPdfInterface();
      case 'pdf_to_images':
        return _buildPdfToImagesInterface();
      case 'images_to_pdf':
        return _buildImagesToPdfInterface();
      default:
        return _buildPlaceholderInterface();
    }
  }

  Widget _buildMergePdfInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select 2 or more PDFs to merge'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _selectFiles,
            icon: const Icon(Icons.add),
            label: const Text('Select PDFs'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Merging PDFs...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSplitPdfInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a PDF to split'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _selectFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select PDF'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressPdfInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a PDF to compress'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _selectFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select PDF'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quality'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Low', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: 0.5,
                  divisions: 2,
                  label: 'Medium',
                  onChanged: (value) {},
                ),
              ),
              const Text('High', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfToImagesInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a PDF to convert'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _selectFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select PDF'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Output: '),
              ChoiceChip(
                label: const Text('JPG'),
                selected: true,
                onSelected: (selected) {},
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('PNG'),
                selected: false,
                onSelected: (selected) {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesToPdfInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select images to combine'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _selectImages,
            icon: const Icon(Icons.image),
            label: const Text('Select Images'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderInterface() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.tool.icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '${widget.tool.name} - Coming Soon',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This tool is under development',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectFiles() async {
    setState(() => _isProcessing = true);
    // TODO: Implement file picker for multiple files
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isProcessing = false);
      _showPreview();
    }
  }

  Future<void> _selectFile() async {
    setState(() => _isProcessing = true);
    // TODO: Implement file picker
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isProcessing = false);
      _showPreview();
    }
  }

  Future<void> _selectImages() async {
    setState(() => _isProcessing = true);
    // TODO: Implement image picker
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isProcessing = false);
      _showPreview();
    }
  }

  void _showPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ToolPreviewScreen(
          outputType: 'pdf',
          suggestedName: 'Output',
        ),
      ),
    );
  }
}
