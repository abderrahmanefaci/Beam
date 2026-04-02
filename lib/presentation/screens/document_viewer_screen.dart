import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/beam_theme.dart';
import '../../domain/entities/entities.dart';
import '../../services/ai_service.dart';
import '../screens/ai_overlay_screen.dart';
import '../screens/editor_screen.dart';
import '../screens/paywall_screen.dart';
import '../providers/providers.dart';

/// Document Viewer Screen with AI button
class DocumentViewerScreen extends ConsumerWidget {
  final DocumentEntity document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            icon: Icon(document.favorite ? Icons.star : Icons.star_border),
            onPressed: () {
              // TODO: Toggle favorite
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getFileIcon(document.fileType),
              size: 80,
              color: _getFileColor(document.fileType),
            ),
            const SizedBox(height: 24),
            Text(
              document.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${document.formattedFileSize} • ${document.fileType.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            // Edit button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditorScreen(document: document),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Open in Editor'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AiFab(document: document),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.presentation;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

/// AI Floating Action Button with unlock logic
class _AiFab extends StatelessWidget {
  final DocumentEntity document;

  const _AiFab({required this.document});

  Future<void> _handleAiTap(BuildContext context, WidgetRef ref) async {
    final aiService = AiService();

    // Check AI unlock status
    final unlockStatus = await aiService.checkAiUnlockStatus(
      documentId: document.id,
      isAiUnlocked: document.aiUnlocked,
    );

    if (!unlockStatus['canUnlock'] as bool) {
      // Show paywall
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }

    // If document not unlocked and free tier available, unlock it
    if (!document.aiUnlocked && unlockStatus['reason'] == 'free_tier_available') {
      final success = await aiService.unlockDocument(document.id);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unlock document'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
        return;
      }
    }

    // Show AI overlay
    if (context.mounted) {
      // For MVP, we'll use placeholder content
      // In production, extract actual text from document
      final fileContent = await _extractDocumentContent(document);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiOverlayScreen(
            document: document,
            fileContent: fileContent,
          ),
        ),
      );
    }
  }

  Future<String> _extractDocumentContent(DocumentEntity document) async {
    // In production, this would extract actual text from the document
    // For MVP, return placeholder based on file type
    return '''
## Overview
This is a sample ${document.fileType.toUpperCase()} document titled "${document.title}".

## Key Points
• This is the first key point from the document
• This is the second key point from the document
• This is the third key point from the document
• This is the fourth key point from the document
• This is the fifth key point from the document

## Key Terms
• Term 1: Definition of the first important term
• Term 2: Definition of the second important term
• Term 3: Definition of the third important term
''';
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => FloatingActionButton(
        onPressed: () => _handleAiTap(context, context as WidgetRef),
        backgroundColor: BeamTheme.primaryPurple,
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }
}
