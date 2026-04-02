import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/beam_theme.dart';
import '../../providers/providers.dart';
import 'document_viewer_screen.dart';

/// Tool Preview Screen - Full-screen preview after tool processing
class ToolPreviewScreen extends ConsumerStatefulWidget {
  final String outputType;
  final String suggestedName;

  const ToolPreviewScreen({
    super.key,
    required this.outputType,
    required this.suggestedName,
  });

  @override
  ConsumerState<ToolPreviewScreen> createState() => _ToolPreviewScreenState();
}

class _ToolPreviewScreenState extends ConsumerState<ToolPreviewScreen> {
  final _filenameController = TextEditingController();
  String? _selectedFolderId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _filenameController.text = widget.suggestedName;
  }

  @override
  void dispose() {
    _filenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeamTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSaving ? null : () => _showDiscardDialog(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            style: TextButton.styleFrom(
              foregroundColor: BeamTheme.successGreen,
              fontWeight: FontWeight.bold,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // File preview
          Expanded(
            child: _buildPreview(),
          ),
          // Save options
          _buildSaveOptions(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getPreviewIcon(),
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.outputType.toUpperCase()} Output',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: BeamTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BeamTheme.successGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: BeamTheme.successGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Processing complete! Review and save to library.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filename field
          TextField(
            controller: _filenameController,
            decoration: const InputDecoration(
              labelText: 'Filename',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Folder selector
          InkWell(
            onTap: _selectFolder,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: BeamTheme.primaryPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Save to folder',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          _selectedFolderId != null ? 'Selected folder' : 'Root (All Files)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedFolderId != null
                                ? BeamTheme.primaryPurple
                                : BeamTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: BeamTheme.successGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Saving...'),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('Save to Library'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getPreviewIcon() {
    switch (widget.outputType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
      case 'md':
        return Icons.description;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _selectFolder() {
    // TODO: Show folder picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Folder picker - Coming soon')),
    );
  }

  Future<void> _handleSave() async {
    if (_filenameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a filename'),
          backgroundColor: BeamTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Simulate save
      await Future.delayed(const Duration(seconds: 2));

      // Save to database
      final documentRepository = ref.read(documentRepositoryProvider);
      await documentRepository.createDocument(
        title: _filenameController.text.trim(),
        fileType: widget.outputType,
        fileSizeBytes: 1024 * 100, // Placeholder
        fileUrl: '', // Placeholder - would need actual upload
        sourceType: 'tool',
        folderId: _selectedFolderId,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to library'),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to library or open document
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            backgroundColor: BeamTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Output?'),
        content: const Text('Are you sure you want to discard this output?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BeamTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}
