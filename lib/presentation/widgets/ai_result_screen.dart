import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/theme/beam_theme.dart';
import '../../domain/entities/entities.dart';
import '../../services/ai_service.dart';
import '../../providers/providers.dart';

/// AI Result Screen - Shows AI output with action buttons
class AiResultScreen extends ConsumerStatefulWidget {
  final AiActionType actionType;
  final String result;
  final DocumentEntity document;
  final int creditsRemaining;

  const AiResultScreen({
    super.key,
    required this.actionType,
    required this.result,
    required this.document,
    required this.creditsRemaining,
  });

  @override
  ConsumerState<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends ConsumerState<AiResultScreen> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeamTheme.backgroundLight,
      appBar: AppBar(
        title: Text(_getActionTitle()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Credits badge
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: BeamTheme.accentAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BeamTheme.accentAmber),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.credit_card, size: 16, color: BeamTheme.accentAmber),
                const SizedBox(width: 8),
                Text(
                  '${widget.creditsRemaining} credits remaining',
                  style: const TextStyle(
                    color: BeamTheme.accentAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Result card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getActionColor().withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getActionIcon(),
                          color: _getActionColor(),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getActionTitle(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getActionColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildResultContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildResultContent() {
    switch (widget.actionType) {
      case AiActionType.summarize:
        return _buildSummaryContent();
      case AiActionType.translate:
        return _buildTranslationContent();
      case AiActionType.extractText:
      case AiActionType.extractTables:
        return _buildExtractedContent();
      default:
        return Text(widget.result);
    }
  }

  Widget _buildSummaryContent() {
    // Parse the summary structure
    final lines = widget.result.split('\n');
    final sections = <String, List<String>>{};
    String? currentSection;

    for (final line in lines) {
      if (line.startsWith('##')) {
        currentSection = line.replaceAll('##', '').trim();
        sections[currentSection!] = [];
      } else if (line.trim().isNotEmpty && currentSection != null) {
        sections[currentSection]?.add(line.trim());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sections.containsKey('Overview')) ...[
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BeamTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sections['Overview']?.join(' ') ?? '',
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
        if (sections.containsKey('Key Points')) ...[
          const Text(
            'Key Points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BeamTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          ...?sections['Key Points']?.map((point) {
            final cleanPoint = point.replaceAll(RegExp(r'^[-•*]\s*'), '');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(height: 1.6)),
                  Expanded(child: Text(cleanPoint, style: const TextStyle(height: 1.6))),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
        if (sections.containsKey('Key Terms')) ...[
          const Text(
            'Key Terms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BeamTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          ...?sections['Key Terms']?.map((term) {
            final parts = term.split(':');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parts.first,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: BeamTheme.primaryPurple,
                    ),
                  ),
                  if (parts.length > 1)
                    Text(
                      parts.skip(1).join(':').trim(),
                      style: const TextStyle(height: 1.5),
                    ),
                ],
              ),
            );
          }),
        ],
        if (sections.isEmpty)
          Text(widget.result, style: const TextStyle(height: 1.6)),
      ],
    );
  }

  Widget _buildTranslationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.result,
          style: const TextStyle(height: 1.6, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildExtractedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.result,
          style: const TextStyle(
            height: 1.6,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
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
      child: SafeArea(
        child: Row(
          children: [
            // Copy
            Expanded(
              child: _ActionButton(
                icon: _isCopied ? Icons.check : Icons.copy,
                label: _isCopied ? 'Copied!' : 'Copy',
                color: _isCopied ? BeamTheme.successGreen : BeamTheme.textSecondaryLight,
                onTap: _handleCopy,
              ),
            ),
            const SizedBox(width: 8),
            // Save
            Expanded(
              child: _ActionButton(
                icon: Icons.save,
                label: 'Save',
                color: BeamTheme.primaryPurple,
                onTap: _handleSave,
              ),
            ),
            const SizedBox(width: 8),
            // Share
            Expanded(
              child: _ActionButton(
                icon: Icons.share,
                label: 'Share',
                color: BeamTheme.textSecondaryLight,
                onTap: _handleShare,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.result));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _handleSave() async {
    try {
      final documentRepository = ref.read(documentRepositoryProvider);
      final fileName = '${widget.document.title}_${widget.actionType.value}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.md';
      
      await documentRepository.createDocument(
        title: fileName,
        fileType: 'md',
        fileSizeBytes: widget.result.length,
        fileUrl: '', // Would need to upload first
        sourceType: 'ai_action',
        outputOf: widget.document.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to library'),
            backgroundColor: BeamTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    try {
      await Share.share(
        '${_getActionTitle()} of ${widget.document.title}:\n\n${widget.result}',
        subject: '${_getActionTitle()} - ${widget.document.title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  String _getActionTitle() {
    switch (widget.actionType) {
      case AiActionType.summarize:
        return 'Summary';
      case AiActionType.translate:
        return 'Translation';
      case AiActionType.extractText:
        return 'Extracted Text';
      case AiActionType.extractTables:
        return 'Extracted Tables';
      case AiActionType.chat:
        return 'Chat Response';
      case AiActionType.custom:
        return 'AI Result';
    }
  }

  IconData _getActionIcon() {
    switch (widget.actionType) {
      case AiActionType.summarize:
        return Icons.auto_awesome;
      case AiActionType.translate:
        return Icons.language;
      case AiActionType.extractText:
        return Icons.text_fields;
      case AiActionType.extractTables:
        return Icons.table_chart;
      case AiActionType.chat:
        return Icons.chat;
      case AiActionType.custom:
        return Icons.smart_toy;
    }
  }

  Color _getActionColor() {
    switch (widget.actionType) {
      case AiActionType.summarize:
      case AiActionType.extractText:
      case AiActionType.extractTables:
        return BeamTheme.accentTeal;
      case AiActionType.translate:
        return Colors.blue;
      case AiActionType.chat:
        return BeamTheme.primaryPurple;
      case AiActionType.custom:
        return BeamTheme.accentAmber;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
