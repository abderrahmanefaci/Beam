import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/theme/beam_theme.dart';

/// OnlyOffice Editor Widget for DOCX, XLSX, PPTX files
class OnlyOfficeEditorWidget extends StatefulWidget {
  final Uint8List fileData;
  final String fileUrl;
  final String fileType;
  final VoidCallback onDocumentChanged;
  final Function({required bool canUndo, required bool canRedo}) onUndoRedoState;
  final Function(Uint8List) onDataUpdate;

  const OnlyOfficeEditorWidget({
    super.key,
    required this.fileData,
    required this.fileUrl,
    required this.fileType,
    required this.onDocumentChanged,
    required this.onUndoRedoState,
    required this.onDataUpdate,
  });

  @override
  State<OnlyOfficeEditorWidget> createState() => _OnlyOfficeEditorWidgetState();
}

class _OnlyOfficeEditorWidgetState extends State<OnlyOfficeEditorWidget> {
  InAppWebViewController? _webViewController;
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // OnlyOffice in WebView
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.fileUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            allowFileAccess: true,
            allowContentAccess: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _setupJavaScriptBridge();
          },
          onLoadStop: (controller, url) {
            setState(() => _isReady = true);
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('OnlyOffice Console: ${consoleMessage.message}');
          },
        ),
        // Loading indicator
        if (!_isReady)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading OnlyOffice Editor...'),
              ],
            ),
          ),
      ],
    );
  }

  void _setupJavaScriptBridge() {
    _webViewController?.addJavaScriptHandler(
      handlerName: 'onDocumentChange',
      callback: (args) {
        widget.onDocumentChanged();
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'onSave',
      callback: (args) {
        // Trigger manual save
        widget.onDocumentChanged();
      },
    );

    _webViewController?.addJavaScriptHandler(
      handlerName: 'onUndoRedoState',
      callback: (args) {
        if (args.isNotEmpty && args[0] is Map) {
          final state = args[0] as Map;
          widget.onUndoRedoState(
            canUndo: state['canUndo'] ?? false,
            canRedo: state['canRedo'] ?? false,
          );
        }
      },
    );
  }
}

/// Placeholder widget when OnlyOffice is not available
class OnlyOfficePlaceholder extends StatelessWidget {
  final String fileType;

  const OnlyOfficePlaceholder({
    super.key,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForFileType(fileType),
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'OnlyOffice Editor',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '.$fileType editing requires OnlyOffice integration',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: BeamTheme.accentAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BeamTheme.accentAmber),
            ),
            child: const Text(
              'To enable full editing:\n1. Add OnlyOffice Document Server URL\n2. Configure WebView with document URL\n3. Set up JavaScript bridge for save/undo events',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFileType(String fileType) {
    switch (fileType) {
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'pptx':
      case 'ppt':
        return Icons.presentation;
      default:
        return Icons.insert_drive_file;
    }
  }
}
