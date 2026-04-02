import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/theme/beam_theme.dart';
import '../../services/signature_service.dart';

/// Signature Pad Screen - Draw digital signature
class SignaturePadScreen extends StatefulWidget {
  const SignaturePadScreen({super.key});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final _signatureService = SignatureService();
  
  // Drawing state
  List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  
  // Settings
  Color _selectedColor = Colors.black;
  double _strokeWidth = 2.0;
  
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Signature'),
        backgroundColor: Colors.white,
        foregroundColor: BeamTheme.textPrimaryLight,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            style: TextButton.styleFrom(
              foregroundColor: BeamTheme.primaryPurple,
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
          // Drawing canvas
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                color: Colors.white,
                child: CustomPaint(
                  painter: SignaturePainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    strokeColor: _selectedColor,
                    strokeWidth: _strokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Toolbar
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Color selection
            Row(
              children: [
                const Text(
                  'Color:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                _ColorButton(
                  color: Colors.black,
                  isSelected: _selectedColor == Colors.black,
                  onTap: () => setState(() => _selectedColor = Colors.black),
                ),
                const SizedBox(width: 8),
                _ColorButton(
                  color: Colors.blue,
                  isSelected: _selectedColor == Colors.blue,
                  onTap: () => setState(() => _selectedColor = Colors.blue),
                ),
                const SizedBox(width: 8),
                _ColorButton(
                  color: Colors.red,
                  isSelected: _selectedColor == Colors.red,
                  onTap: () => setState(() => _selectedColor = Colors.red),
                ),
                const Spacer(),
                // Thickness selection
                const Text(
                  'Thickness:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                _ThicknessButton(
                  width: 2.0,
                  isSelected: _strokeWidth == 2.0,
                  onTap: () => setState(() => _strokeWidth = 2.0),
                ),
                const SizedBox(width: 8),
                _ThicknessButton(
                  width: 4.0,
                  isSelected: _strokeWidth == 4.0,
                  onTap: () => setState(() => _strokeWidth = 4.0),
                ),
                const SizedBox(width: 8),
                _ThicknessButton(
                  width: 6.0,
                  isSelected: _strokeWidth == 6.0,
                  onTap: () => setState(() => _strokeWidth = 6.0),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                // Clear button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleClear,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BeamTheme.errorRed,
                      side: const BorderSide(color: BeamTheme.errorRed),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Undo button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _strokes.isEmpty ? null : _handleUndo,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _strokes.isEmpty || _isSaving ? null : _handleSave,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BeamTheme.primaryPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke = [...?_currentStroke, details.localPosition];
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null && _currentStroke!.isNotEmpty) {
      setState(() {
        _strokes.add(_currentStroke!);
        _currentStroke = null;
      });
    }
  }

  void _handleClear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void _handleUndo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  Future<void> _handleSave() async {
    if (_strokes.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Capture signature as PNG
      final pngBytes = await _captureSignature();
      
      // Upload to Supabase
      final fileUrl = await _signatureService.saveSignature(pngBytes);

      if (mounted) {
        setState(() => _isSaving = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Signature saved'),
            backgroundColor: BeamTheme.successGreen,
            action: SnackBarAction(
              label: 'Done',
              textColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<Uint8List> _captureSignature() async {
    // Create a temporary file to capture the canvas
    final directory = await getTemporaryDirectory();
    final filePath = path.join(directory.path, 'signature_${DateTime.now().millisecondsSinceEpoch}.png');
    final file = File(filePath);

    // For MVP, we'll create a simple representation
    // In production, use RenderRepaintBoundary to capture the actual canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 800, 400),
      Paint()..color = Colors.white,
    );

    // Draw all strokes
    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(
          stroke[i],
          stroke[i + 1],
          Paint()
            ..color = _selectedColor
            ..strokeWidth = _strokeWidth
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(800, 400);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}

/// Signature Painter
class SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  final Color strokeColor;
  final double strokeWidth;

  SignaturePainter({
    required this.strokes,
    this.currentStroke,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw all completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    // Draw current stroke
    if (currentStroke != null && currentStroke!.length >= 2) {
      for (int i = 0; i < currentStroke!.length - 1; i++) {
        canvas.drawLine(currentStroke![i], currentStroke![i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}

/// Color Button Widget
class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? BeamTheme.primaryPurple : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

/// Thickness Button Widget
class _ThicknessButton extends StatelessWidget {
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThicknessButton({
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected 
              ? BeamTheme.primaryPurple.withOpacity(0.1) 
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? BeamTheme.primaryPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Container(
            width: width,
            height: width,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
