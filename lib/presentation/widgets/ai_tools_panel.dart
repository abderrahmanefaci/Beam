import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/beam_theme.dart';
import '../screens/tools_screen.dart';
import '../../services/ai_service.dart';
import '../../providers/providers.dart';
import 'tool_preview_screen.dart';

/// AI Tools Panel - Bottom sheet for AI-powered tools
class AiToolsPanel extends ConsumerStatefulWidget {
  final ToolDefinition tool;

  const AiToolsPanel({super.key, required this.tool});

  @override
  ConsumerState<AiToolsPanel> createState() => _AiToolsPanelState();
}

class _AiToolsPanelState extends ConsumerState<AiToolsPanel> {
  bool _isProcessing = false;
  DocumentEntity? _selectedDocument;

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
                      color: BeamTheme.accentAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.tool.icon,
                      color: BeamTheme.accentAmber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.tool.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: BeamTheme.accentAmber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: BeamTheme.accentAmber,
                                ),
                              ),
                            ),
                          ],
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
    if (_selectedDocument != null) {
      return _buildProcessingInterface();
    }
    return _buildDocumentPickerInterface();
  }

  Widget _buildDocumentPickerInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select a document to process'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _selectDocument,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose from Library'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BeamTheme.accentAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BeamTheme.accentAmber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: BeamTheme.accentAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI processing uses credits. Check your balance in Profile.',
                    style: TextStyle(
                      fontSize: 12,
                      color: BeamTheme.accentAmber.withOpacity(0.9),
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

  Widget _buildProcessingInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected document card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getFileIcon(_selectedDocument!.fileType),
                  color: _getFileColor(_selectedDocument!.fileType),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDocument!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _selectedDocument!.formattedFileSize,
                        style: TextStyle(
                          fontSize: 12,
                          color: BeamTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _selectedDocument = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isProcessing) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing with AI...'),
          ] else ...[
            ElevatedButton(
              onPressed: _processWithAi,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: BeamTheme.accentAmber,
              ),
              child: Text('Process with ${widget.tool.name}'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDocument() async {
    // Navigate to library for document selection
    // For MVP, use a placeholder
    final mockDoc = DocumentEntity(
      id: 'mock-id',
      userId: 'user-id',
      title: 'Sample Document.pdf',
      fileType: 'pdf',
      fileSizeBytes: 1024 * 512,
      fileUrl: '',
      sourceType: 'scanner',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    setState(() => _selectedDocument = mockDoc);
  }

  Future<void> _processWithAi() async {
    if (_selectedDocument == null) return;

    setState(() => _isProcessing = true);

    try {
      final aiService = AiService();
      // Simulate AI processing
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pop();
        _showPreview();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI processing failed: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ToolPreviewScreen(
          outputType: 'md',
          suggestedName: '${widget.tool.name}_result',
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc':
      case 'docx': return Icons.description;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'doc':
      case 'docx': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
