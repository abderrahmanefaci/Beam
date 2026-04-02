import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/theme/beam_theme.dart';

/// PDF Editor Widget using Syncfusion
class PdfEditorWidget extends StatefulWidget {
  final Uint8List fileData;
  final String fileUrl;
  final VoidCallback onDocumentChanged;
  final Function({required bool canUndo, required bool canRedo}) onUndoRedoState;
  final Function(Uint8List) onDataUpdate;

  const PdfEditorWidget({
    super.key,
    required this.fileData,
    required this.fileUrl,
    required this.onDocumentChanged,
    required this.onUndoRedoState,
    required this.onDataUpdate,
  });

  @override
  State<PdfEditorWidget> createState() => _PdfEditorWidgetState();
}

class _PdfEditorWidgetState extends State<PdfEditorWidget> {
  final GlobalKey<SfPdfViewerState> _viewerKey = GlobalKey();
  PdfAnnotationToolbarSettings? _annotationToolbarSettings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // PDF Viewer
        SfPdfViewer.memory(
          widget.fileData,
          key: _viewerKey,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            // Document loaded successfully
            widget.onUndoRedoState(canUndo: false, canRedo: false);
          },
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load PDF: ${details.error}'),
                backgroundColor: BeamTheme.errorRed,
              ),
            );
          },
          // Enable annotation mode
          annotationToolbarSettings: PdfAnnotationToolbarSettings(
            annotationToolbarEnabled: true,
            // Highlight
            highlightColor: Colors.yellow.withOpacity(0.5),
            // Underline
            underlineColor: BeamTheme.primaryPurple,
            // Strikethrough
            strikethroughColor: BeamTheme.errorRed,
            // Freehand
            inkColor: BeamTheme.primaryPurple,
            inkStrokeWidth: 2.0,
            // Text box
            textBoxTextColor: BeamTheme.textPrimaryLight,
            textBoxFillColor: Colors.white,
            // Sticky note
            noteColor: BeamTheme.accentAmber,
          ),
          // Enable all annotation tools
          canShowAnnotationToolbar: true,
          onAnnotationAdded: (annotation) {
            widget.onDocumentChanged();
          },
          onAnnotationRemoved: (annotation) {
            widget.onDocumentChanged();
          },
          onAnnotationModified: (annotation, oldAnnotation) {
            widget.onDocumentChanged();
          },
        ),
        // Annotation toolbar hint
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildAnnotationHint(),
        ),
      ],
    );
  }

  Widget _buildAnnotationHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolIcon(Icons.highlight, 'Highlight'),
          _buildToolIcon(Icons.format_underline, 'Underline'),
          _buildToolIcon(Icons.strikethrough_s, 'Strikethrough'),
          _buildToolIcon(Icons.draw, 'Draw'),
          _buildToolIcon(Icons.note, 'Note'),
          _buildToolIcon(Icons.text_fields, 'Text'),
        ],
      ),
    );
  }

  Widget _buildToolIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
