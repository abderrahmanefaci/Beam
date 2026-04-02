import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/beam_theme.dart';
import '../../core/constants/beam_constants.dart';
import '../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../widgets/pdf_editor_widget.dart';
import '../widgets/onlyoffice_editor_widget.dart';
import '../widgets/quill_editor_widget.dart';
import '../widgets/image_editor_widget.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/version_history_screen.dart';
import '../../services/editor_service.dart';

/// Universal File Editor Screen
class EditorScreen extends ConsumerStatefulWidget {
  final DocumentEntity document;

  const EditorScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _editorService = EditorService();
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  String? _error;
  Timer? _autosaveTimer;
  Uint8List? _currentFileData;

  // Undo/Redo state
  bool _canUndo = false;
  bool _canRedo = false;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeEditor() async {
    setState(() => _isLoading = true);

    try {
      // Load file data
      _currentFileData = await _editorService.loadFileData(widget.document.fileUrl);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _markUnsavedChanges() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    _resetAutosaveTimer();
  }

  void _resetAutosaveTimer() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(
      const Duration(seconds: BeamConstants.autosaveDebounceSeconds),
      _triggerAutosave,
    );
  }

  Future<void> _triggerAutosave() async {
    if (!_hasUnsavedChanges || _currentFileData == null) return;

    try {
      await _editorService.saveVersion(
        documentId: widget.document.id,
        fileData: _currentFileData!,
        isAutosave: true,
      );

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-saved'),
            duration: Duration(seconds: 2),
            backgroundColor: BeamTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-save failed: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _manualSave() async {
    if (!_hasUnsavedChanges || _currentFileData == null) return;

    try {
      await _editorService.saveVersion(
        documentId: widget.document.id,
        fileData: _currentFileData!,
        isAutosave: false,
      );

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved'),
            backgroundColor: BeamTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  void _updateUndoRedoState({required bool canUndo, required bool canRedo}) {
    setState(() {
      _canUndo = canUndo;
      _canRedo = canRedo;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load document: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeEditor,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        backgroundColor: BeamTheme.backgroundLight,
        appBar: _buildAppBar(),
        body: _buildEditorBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filename with autosave indicator
          GestureDetector(
            onTap: _showRenameDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.document.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_hasUnsavedChanges)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: BeamTheme.accentAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackNavigation,
      ),
      actions: [
        // Undo
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: _canUndo ? _handleUndo : null,
          tooltip: 'Undo',
        ),
        // Redo
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: _canRedo ? _handleRedo : null,
          tooltip: 'Redo',
        ),
        // Share
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _handleShare,
          tooltip: 'Share',
        ),
        // More menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMoreAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.file_copy, size: 20),
                  SizedBox(width: 12),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'version_history',
              child: Row(
                children: [
                  Icon(Icons.history, size: 20),
                  SizedBox(width: 12),
                  Text('Version History'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 12),
                  Text('Export As'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'save',
              child: Row(
                children: [
                  Icon(Icons.save, size: 20),
                  SizedBox(width: 12),
                  Text('Save Now'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditorBody() {
    // Route to appropriate editor based on file type
    final fileType = widget.document.fileType.toLowerCase();

    Widget editor;

    switch (fileType) {
      case 'pdf':
        editor = PdfEditorWidget(
          fileData: _currentFileData!,
          fileUrl: widget.document.fileUrl,
          onDocumentChanged: _markUnsavedChanges,
          onUndoRedoState: _updateUndoRedoState,
          onDataUpdate: (data) => setState(() => _currentFileData = data),
        );
        break;

      case 'docx':
      case 'doc':
      case 'xlsx':
      case 'xls':
      case 'pptx':
      case 'ppt':
        editor = OnlyOfficeEditorWidget(
          fileData: _currentFileData!,
          fileUrl: widget.document.fileUrl,
          fileType: fileType,
          onDocumentChanged: _markUnsavedChanges,
          onUndoRedoState: _updateUndoRedoState,
          onDataUpdate: (data) => setState(() => _currentFileData = data),
        );
        break;

      case 'md':
      case 'txt':
        editor = QuillEditorWidget(
          fileData: _currentFileData!,
          fileType: fileType,
          onDocumentChanged: _markUnsavedChanges,
          onUndoRedoState: _updateUndoRedoState,
          onDataUpdate: (data) => setState(() => _currentFileData = data),
        );
        break;

      case 'jpg':
      case 'jpeg':
      case 'png':
        editor = ImageEditorWidget(
          fileData: _currentFileData!,
          fileType: fileType,
          onDocumentChanged: _markUnsavedChanges,
          onUndoRedoState: _updateUndoRedoState,
          onDataUpdate: (data) => setState(() => _currentFileData = data),
        );
        break;

      default:
        editor = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'File type not supported',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Cannot edit .${widget.document.fileType} files',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
    }

    return editor;
  }

  Future<bool> _handleBackNavigation() async {
    if (_hasUnsavedChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(foregroundColor: BeamTheme.errorRed),
              child: const Text('Discard'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                await _manualSave();
              },
              child: const Text('Save & Exit'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  void _showRenameDialog() {
    // TODO: Implement inline rename
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rename - Coming soon')),
    );
  }

  void _handleUndo() {
    // Undo handled by individual editor widgets
  }

  void _handleRedo() {
    // Redo handled by individual editor widgets
  }

  Future<void> _handleShare() async {
    try {
      await Share.share(
        'Check out this document: ${widget.document.title}',
        subject: widget.document.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  void _handleMoreAction(String action) {
    switch (action) {
      case 'duplicate':
        _duplicateDocument();
        break;
      case 'version_history':
        _showVersionHistory();
        break;
      case 'export':
        _exportDocument();
        break;
      case 'save':
        _manualSave();
        break;
    }
  }

  Future<void> _duplicateDocument() async {
    try {
      await ref.read(documentRepositoryProvider).duplicateDocument(widget.document.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document duplicated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate: $e')),
        );
      }
    }
  }

  void _showVersionHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VersionHistoryScreen(documentId: widget.document.id),
      ),
    );
  }

  void _exportDocument() {
    // TODO: Implement export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export - Coming soon')),
    );
  }
}
