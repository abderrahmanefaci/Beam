import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';
import '../../core/theme/beam_theme.dart';

/// Image Editor Widget for JPG and PNG files
class ImageEditorWidget extends StatefulWidget {
  final Uint8List fileData;
  final String fileType;
  final VoidCallback onDocumentChanged;
  final Function({required bool canUndo, required bool canRedo}) onUndoRedoState;
  final Function(Uint8List) onDataUpdate;

  const ImageEditorWidget({
    super.key,
    required this.fileData,
    required this.fileType,
    required this.onDocumentChanged,
    required this.onUndoRedoState,
    required this.onDataUpdate,
  });

  @override
  State<ImageEditorWidget> createState() => _ImageEditorWidgetState();
}

class _ImageEditorWidgetState extends State<ImageEditorWidget> {
  late Uint8List _imageData;
  double _brightness = 0;
  double _contrast = 0;
  int _rotateAngle = 0;
  bool _isDrawing = false;
  
  // Undo/Redo stack
  final List<Uint8List> _undoStack = [];
  final List<Uint8List> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _imageData = widget.fileData;
  }

  void _pushState() {
    setState(() {
      _undoStack.add(_imageData);
      _redoStack.clear();
      widget.onDocumentChanged();
      widget.onUndoRedoState(
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      );
    });
  }

  Future<void> _applyTransformations() async {
    try {
      final image = Image.fromUint8List(_imageData);
      
      // Apply brightness and contrast
      if (_brightness != 0 || _contrast != 0) {
        final adjusted = await ImageEditor.adjustColor(
          image: image,
          brightness: _brightness,
          contrast: _contrast,
        );
        _imageData = adjusted;
      }
      
      // Apply rotation
      if (_rotateAngle != 0) {
        final rotated = await ImageEditor.rotate(
          image: image,
          angle: _rotateAngle,
        );
        _imageData = rotated;
      }

      widget.onDataUpdate(_imageData);
      _pushState();
      
      // Reset transformations
      setState(() {
        _brightness = 0;
        _contrast = 0;
        _rotateAngle = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply transformations: $e'),
          backgroundColor: BeamTheme.errorRed,
        ),
      );
    }
  }

  void _handleRotate(int degrees) {
    setState(() {
      _rotateAngle = (_rotateAngle + degrees) % 360;
    });
    _applyTransformations();
  }

  void _handleUndo() {
    if (_undoStack.isEmpty) return;
    
    setState(() {
      _redoStack.add(_imageData);
      _imageData = _undoStack.removeLast();
      widget.onUndoRedoState(
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      );
    });
  }

  void _handleRedo() {
    if (_redoStack.isEmpty) return;
    
    setState(() {
      _undoStack.add(_imageData);
      _imageData = _redoStack.removeLast();
      widget.onUndoRedoState(
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: Container(
            color: Colors.black12,
            child: Center(
              child: Image.memory(
                _imageData,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Toolbar
        _buildToolbar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: BeamTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Row 1: Transform tools
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolButton(
                    icon: Icons.rotate_left,
                    label: 'Rotate -90°',
                    onTap: () => _handleRotate(-90),
                  ),
                  _ToolButton(
                    icon: Icons.rotate_right,
                    label: 'Rotate +90°',
                    onTap: () => _handleRotate(90),
                  ),
                  _ToolButton(
                    icon: Icons.flip,
                    label: 'Flip',
                    onTap: () {
                      // TODO: Implement flip
                    },
                  ),
                  _ToolButton(
                    icon: Icons.crop,
                    label: 'Crop',
                    onTap: () {
                      // TODO: Implement crop
                    },
                  ),
                  _ToolButton(
                    icon: Icons.brightness_6,
                    label: 'Brightness',
                    onTap: _showBrightnessDialog,
                  ),
                  _ToolButton(
                    icon: Icons.contrast,
                    label: 'Contrast',
                    onTap: _showContrastDialog,
                  ),
                  _ToolButton(
                    icon: Icons.draw,
                    label: 'Draw',
                    onTap: () {
                      setState(() => _isDrawing = !_isDrawing);
                    },
                  ),
                  _ToolButton(
                    icon: Icons.text_fields,
                    label: 'Text',
                    onTap: () {
                      // TODO: Implement text overlay
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Row 2: Undo/Redo and actions
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _undoStack.isNotEmpty ? _handleUndo : null,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: _redoStack.isNotEmpty ? _handleRedo : null,
                  tooltip: 'Redo',
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onDataUpdate(_imageData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Image saved'),
                        backgroundColor: BeamTheme.successGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBrightnessDialog() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Brightness'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _brightness,
                min: -1,
                max: 1,
                divisions: 20,
                label: _brightness.toStringAsFixed(1),
                onChanged: (value) {
                  setDialogState(() {});
                },
              ),
              Text('Value: ${_brightness.toStringAsFixed(1)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_brightness),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null) {
      _applyTransformations();
    }
  }

  Future<void> _showContrastDialog() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Contrast'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _contrast,
                min: -1,
                max: 1,
                divisions: 20,
                label: _contrast.toStringAsFixed(1),
                onChanged: (value) {
                  setDialogState(() {});
                },
              ),
              Text('Value: ${_contrast.toStringAsFixed(1)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_contrast),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null) {
      _applyTransformations();
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: BeamTheme.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: BeamTheme.primaryPurple),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: BeamTheme.primaryPurple),
            ),
          ],
        ),
      ),
    );
  }
}
