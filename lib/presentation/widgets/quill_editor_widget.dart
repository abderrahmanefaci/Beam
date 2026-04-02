import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../core/theme/beam_theme.dart';

/// Quill Editor Widget for Markdown and TXT files
class QuillEditorWidget extends StatefulWidget {
  final Uint8List fileData;
  final String fileType;
  final VoidCallback onDocumentChanged;
  final Function({required bool canUndo, required bool canRedo}) onUndoRedoState;
  final Function(Uint8List) onDataUpdate;

  const QuillEditorWidget({
    super.key,
    required this.fileData,
    required this.fileType,
    required this.onDocumentChanged,
    required this.onUndoRedoState,
    required this.onDataUpdate,
  });

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isPreview = false;
  bool _isMarkdown = false;

  @override
  void initState() {
    super.initState();
    _isMarkdown = widget.fileType == 'md';
    _initializeController();
  }

  void _initializeController() {
    try {
      final content = utf8.decode(widget.fileData);
      
      if (_isMarkdown) {
        // For markdown, we'll use plain text for now
        // In production, use a markdown-to-Delta converter
        _controller = QuillController.basic();
        _controller.document.insert(0, content);
      } else {
        // Plain text
        _controller = QuillController.basic();
        _controller.document.insert(0, content);
      }

      _controller.addListener(_onContentChanged);
    } catch (e) {
      _controller = QuillController.basic();
    }
  }

  void _onContentChanged() {
    widget.onDocumentChanged();
    _updateUndoRedoState();
  }

  void _updateUndoRedoState() {
    widget.onUndoRedoState(
      canUndo: _controller.hasUndo,
      canRedo: _controller.hasRedo,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePreview() {
    setState(() => _isPreview = !_isPreview);
  }

  void _exportData() {
    final content = _controller.document.toPlainText();
    widget.onDataUpdate(Uint8List.fromList(utf8.encode(content)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        if (!_isPreview) _buildToolbar(),
        const Divider(height: 1),
        // Editor or Preview
        Expanded(
          child: _isPreview
              ? _buildPreview()
              : _buildEditor(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BeamTheme.surfaceLight,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Formatting toolbar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: QuillSimpleToolbar(
                controller: _controller,
                showAlignmentButtons: true,
                showBackgroundColorButton: true,
                showBoldButton: true,
                showCenterAlignment: true,
                showCodeBlock: true,
                showColorButton: true,
                showDirection: false,
                showDividers: true,
                showFontSize: true,
                showFontFamily: false,
                showHeaderStyle: true,
                showIndent: true,
                showInlineCode: true,
                showItalicButton: true,
                showJustifyAlignment: true,
                showLeftAlignment: true,
                showLink: true,
                showListBullets: true,
                showListCheck: true,
                showListNumbers: true,
                showQuote: true,
                showRedo: true,
                showRightAlignment: true,
                showSearchButton: false,
                showSmallButton: true,
                showStrikeThrough: true,
                showSubscript: true,
                showSuperscript: true,
                showUnderLineButton: true,
                showUndo: true,
                showClipboardCopy: true,
                showClipboardPaste: false,
                toolbarIconAlignment: WrapAlignment.start,
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (_isMarkdown)
                    IconButton(
                      icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
                      onPressed: _togglePreview,
                      tooltip: _isPreview ? 'Edit' : 'Preview',
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _exportData,
                    tooltip: 'Save',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return QuillEditor(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: ScrollController(),
      padding: const EdgeInsets.all(16),
      autoFocus: false,
      expands: true,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  Widget _buildPreview() {
    final content = _controller.document.toPlainText();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _isMarkdown
          ? _buildMarkdownPreview(content)
          : Text(
              content,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
    );
  }

  Widget _buildMarkdownPreview(String content) {
    // Simple markdown rendering (production should use a proper markdown parser)
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: BeamTheme.textPrimaryLight, fontSize: 14),
        children: _parseMarkdown(content),
      ),
    );
  }

  List<TextSpan> _parseMarkdown(String content) {
    // Very basic markdown parsing for MVP
    final lines = content.split('\n');
    final spans = <TextSpan>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ));
      } else if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ));
      } else if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        spans.add(TextSpan(
          text: '$line\n',
          style: const TextStyle(height: 1.5),
        ));
      } else if (line.startsWith('```')) {
        // Code block - simplified
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.shade200,
          ),
        ));
      } else if (line.isEmpty) {
        spans.add(const TextSpan(text: '\n'));
      } else {
        spans.add(TextSpan(text: '$line\n'));
      }
    }

    return spans;
  }
}
