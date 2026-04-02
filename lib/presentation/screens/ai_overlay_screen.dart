import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/beam_theme.dart';
import '../../domain/entities/entities.dart';
import '../../services/ai_service.dart';
import '../widgets/ai_skill_buttons.dart';
import '../widgets/ai_chat_screen.dart';
import '../widgets/custom_ai_chat_screen.dart';
import '../widgets/ai_result_screen.dart';
import '../widgets/language_picker_sheet.dart';
import 'paywall_screen.dart';

/// AI Overlay Screen
/// Shows animated overlay with AI skill buttons
class AiOverlayScreen extends StatefulWidget {
  final DocumentEntity document;
  final String fileContent;

  const AiOverlayScreen({
    super.key,
    required this.document,
    required this.fileContent,
  });

  @override
  State<AiOverlayScreen> createState() => _AiOverlayScreenState();
}

class _AiOverlayScreenState extends State<AiOverlayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shrinkAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _buttonAnimation;
  
  bool _showButtons = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Document shrinks to 65% and centers
    _shrinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.65,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Overlay fades in
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // Buttons animate in from different directions
    _buttonAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
    ));

    // Start animations
    _controller.forward().then((_) {
      setState(() => _showButtons = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent dark overlay
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
              );
            },
          ),
          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: _handleClose,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          // Center content with shrinking animation
          Center(
            child: AnimatedBuilder(
              animation: _shrinkAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _shrinkAnimation.value,
                  child: child,
                );
              },
              child: _buildDocumentPreview(),
            ),
          ),
          // AI Skill buttons
          if (_showButtons)
            _buildSkillButtons(),
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return Container(
      margin: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // App bar placeholder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BeamTheme.primaryPurple,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              widget.document.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Document content placeholder
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: Center(
                child: Icon(
                  _getFileIcon(widget.document.fileType),
                  size: 80,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillButtons() {
    return SlideTransition(
      position: _buttonAnimation,
      child: AiSkillButtons(
        onSummarize: () => _handleSkillAction(AiActionType.summarize),
        onTranslate: () => _showLanguagePicker(),
        onExtractText: () => _handleSkillAction(AiActionType.extractText),
        onExtractTables: () => _handleSkillAction(AiActionType.extractTables),
        onChat: () => _handleChat(),
        onMore: () => _handleMore(),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BeamTheme.primaryPurple),
            ),
            SizedBox(height: 16),
            Text(
              'AI is thinking...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSkillAction(AiActionType actionType) async {
    setState(() => _isLoading = true);

    try {
      final aiService = AiService();
      AiResponse response;

      switch (actionType) {
        case AiActionType.summarize:
          response = await aiService.summarize(
            documentId: widget.document.id,
            fileContent: widget.fileContent,
          );
          break;
        case AiActionType.extractText:
          response = await aiService.extractText(
            documentId: widget.document.id,
            fileContent: widget.fileContent,
          );
          break;
        case AiActionType.extractTables:
          response = await aiService.extractTables(
            documentId: widget.document.id,
            fileContent: widget.fileContent,
          );
          break;
        default:
          throw Exception('Unsupported action type');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _showResult(actionType, response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _handleError(e);
      }
    }
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => LanguagePickerSheet(
        onLanguageSelected: (language) async {
          Navigator.of(context).pop();
          setState(() => _isLoading = true);

          try {
            final aiService = AiService();
            final response = await aiService.translate(
              documentId: widget.document.id,
              fileContent: widget.fileContent,
              language: language.code,
            );

            if (mounted) {
              setState(() => _isLoading = false);
              _showResult(AiActionType.translate, response);
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              _handleError(e);
            }
          }
        },
      ),
    );
  }

  void _handleChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          document: widget.document,
          fileContent: widget.fileContent,
        ),
      ),
    );
  }

  void _handleMore() {
    // Navigate to custom AI request
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomAiChatScreen(
          document: widget.document,
          fileContent: widget.fileContent,
        ),
      ),
    );
  }

  void _showResult(AiActionType actionType, AiResponse response) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiResultScreen(
          actionType: actionType,
          result: response.result,
          document: widget.document,
          creditsRemaining: response.creditsRemaining,
        ),
      ),
    );
  }

  void _handleError(dynamic error) {
    if (error is AiException && error.upgradeRequired) {
      // Show paywall
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: BeamTheme.errorRed,
        ),
      );
    }
  }

  void _handleClose() {
    Navigator.of(context).pop();
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
}
