import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/beam_theme.dart';
import '../../domain/entities/entities.dart';
import '../../services/ai_service.dart';
import 'paywall_screen.dart';

/// Custom AI Chat Screen - Full-screen modal for custom AI requests
class CustomAiChatScreen extends ConsumerStatefulWidget {
  final DocumentEntity document;
  final String fileContent;

  const CustomAiChatScreen({
    super.key,
    required this.document,
    required this.fileContent,
  });

  @override
  ConsumerState<CustomAiChatScreen> createState() => _CustomAiChatScreenState();
}

class _CustomAiChatScreenState extends ConsumerState<CustomAiChatScreen> {
  final _aiService = AiService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_CustomChatMessage> _messages = [];
  int _creditsRemaining = 0;
  bool _isLoading = false;
  bool _hasText = false;

  static const int customRequestCost = 3;

  @override
  void initState() {
    super.initState();
    _loadCredits();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCredits() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final userData = await SupabaseService.client
        .from('users')
        .select('credits_remaining, plan')
        .eq('id', user.id)
        .single();

    setState(() {
      _creditsRemaining = userData['credits_remaining'] as int;
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(_CustomChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Hi! I\'m your custom AI assistant. Describe what you want to do with this document, and I\'ll help you accomplish it.',
        isUser: false,
        timestamp: DateTime.now(),
        messageType: CustomMessageType.welcome,
      ));
    });
  }

  void _onTextChanged(String text) {
    setState(() => _hasText = text.isNotEmpty);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_creditsRemaining < customRequestCost) {
      _showOutOfCredits();
      return;
    }

    // Show confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Custom Request'),
        content: Text(
          'This custom AI request will use $customRequestCost credits. '
          'You have $_creditsRemaining credits remaining.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BeamTheme.accentAmber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Add user message
    setState(() {
      _messages.add(_CustomChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        messageType: CustomMessageType.user,
      ));
      _isLoading = true;
    });

    _messageController.clear();
    setState(() => _hasText = false);
    _scrollToBottom();

    try {
      final response = await _aiService.customRequest(
        documentId: widget.document.id,
        request: text,
        fileContent: widget.fileContent,
      );

      setState(() {
        _creditsRemaining = response.creditsRemaining;
        _isLoading = false;

        // Determine message type based on response
        CustomMessageType messageType = CustomMessageType.ai;
        if (response.declined == true) {
          messageType = CustomMessageType.declined;
        } else if (response.result.startsWith('[Standard Request]')) {
          messageType = CustomMessageType.redirected;
        }

        _messages.add(_CustomChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: response.result,
          isUser: false,
          timestamp: DateTime.now(),
          messageType: messageType,
          creditsCharged: response.declined == true ? 0 : (messageType == CustomMessageType.redirected ? 1 : 3),
        ));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (e is AiException && e.upgradeRequired) {
        _showOutOfCredits();
      } else {
        setState(() {
          _messages.add(_CustomChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Sorry, I encountered an error. Please try again.\n\n${e.toString()}',
            isUser: false,
            timestamp: DateTime.now(),
            messageType: CustomMessageType.error,
          ));
        });
      }
    }
  }

  void _showOutOfCredits() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeamTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Custom AI Request'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BeamTheme.accentAmber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BeamTheme.accentAmber),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.credit_card, size: 14, color: BeamTheme.accentAmber),
                const SizedBox(width: 6),
                Text(
                  '$_creditsRemaining',
                  style: const TextStyle(
                    color: BeamTheme.accentAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Document thumbnail
          _buildDocumentThumbnail(),
          // Amber info banner
          _buildInfoBanner(),
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildDocumentThumbnail() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getFileColor(widget.document.fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(widget.document.fileType),
              color: _getFileColor(widget.document.fileType),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${widget.document.fileType.toUpperCase()} • ${widget.document.formattedFileSize}',
                  style: TextStyle(
                    fontSize: 11,
                    color: BeamTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeamTheme.accentAmber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BeamTheme.accentAmber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: BeamTheme.accentAmber,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Describe what you want to do with this document. Custom requests cost $customRequestCost credits.',
              style: TextStyle(
                fontSize: 13,
                color: BeamTheme.accentAmber.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: BeamTheme.accentAmber,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                _buildTypingDot(1),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 150)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.4 + (value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessage(_CustomChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message row
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isUser) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getMessageColor(message.messageType),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getMessageIcon(message.messageType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: _buildMessageBubble(message),
              ),
              if (message.isUser) const SizedBox(width: 12),
              if (message.isUser)
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: BeamTheme.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
            ],
          ),
          // Action buttons for AI responses
          if (!message.isUser && message.messageType != CustomMessageType.error)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 48),
              child: Row(
                children: [
                  _MessageActionButton(
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: () => _copyToClipboard(message.text),
                  ),
                  const SizedBox(width: 8),
                  _MessageActionButton(
                    icon: Icons.save,
                    label: 'Save',
                    onTap: () => _saveResult(message.text),
                  ),
                  const SizedBox(width: 8),
                  _MessageActionButton(
                    icon: Icons.refresh,
                    label: 'Try another',
                    onTap: () {
                      _messageController.text = 'Can you ';
                      _onTextChanged('Can you ');
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_CustomChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBubbleColor(message.messageType),
        borderRadius: BorderRadius.circular(16),
        border: message.messageType == CustomMessageType.declined
            ? Border.all(color: BeamTheme.accentAmber, width: 2)
            : message.messageType == CustomMessageType.redirected
                ? Border.all(color: BeamTheme.accentTeal, width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner for redirected messages
          if (message.messageType == CustomMessageType.redirected)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: BeamTheme.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: BeamTheme.accentTeal.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: BeamTheme.accentTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'We handled this as a standard request and only charged 1 credit.',
                      style: TextStyle(
                        fontSize: 12,
                        color: BeamTheme.accentTeal.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Warning banner for declined messages
          if (message.messageType == CustomMessageType.declined)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: BeamTheme.warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: BeamTheme.warningOrange.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: BeamTheme.warningOrange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Request declined: ${message.text.split('\n').first}',
                      style: TextStyle(
                        fontSize: 12,
                        color: BeamTheme.warningOrange.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Message content
          Text(
            message.messageType == CustomMessageType.declined
                ? message.text.split('\n').skip(1).join('\n')
                : message.text.replaceAll('[Standard Request] ', ''),
            style: TextStyle(
              color: message.isUser
                  ? Colors.white
                  : BeamTheme.textPrimaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          // Timestamp and credits
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: message.isUser
                      ? Colors.white70
                      : BeamTheme.textSecondaryLight,
                ),
              ),
              if (message.creditsCharged != null && !message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: message.creditsCharged == 0
                        ? BeamTheme.warningOrange.withOpacity(0.2)
                        : message.creditsCharged == 1
                            ? BeamTheme.accentTeal.withOpacity(0.2)
                            : BeamTheme.accentAmber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    message.creditsCharged == 0
                        ? '0 credits'
                        : '${message.creditsCharged} credit${message.creditsCharged > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: message.creditsCharged == 0
                          ? BeamTheme.warningOrange
                          : message.creditsCharged == 1
                              ? BeamTheme.accentTeal
                              : BeamTheme.accentAmber,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
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
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Describe your request...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _hasText && !_isLoading ? _sendMessage : null,
              icon: const Icon(Icons.send),
              color: _hasText && !_isLoading
                  ? BeamTheme.accentAmber
                  : Colors.grey,
              style: IconButton.styleFrom(
                backgroundColor: _hasText && !_isLoading
                    ? BeamTheme.accentAmber
                    : Colors.grey.shade300,
                foregroundColor: _hasText && !_isLoading
                    ? Colors.white
                    : Colors.grey.shade500,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    // TODO: Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _saveResult(String text) async {
    // TODO: Implement save to library
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to library')),
    );
  }

  IconData _getMessageIcon(CustomMessageType type) {
    switch (type) {
      case CustomMessageType.welcome:
        return Icons.smart_toy;
      case CustomMessageType.ai:
        return Icons.auto_awesome;
      case CustomMessageType.declined:
        return Icons.warning_amber;
      case CustomMessageType.redirected:
        return Icons.check_circle;
      case CustomMessageType.error:
        return Icons.error_outline;
      default:
        return Icons.smart_toy;
    }
  }

  Color _getMessageColor(CustomMessageType type) {
    switch (type) {
      case CustomMessageType.welcome:
      case CustomMessageType.ai:
        return BeamTheme.accentAmber;
      case CustomMessageType.declined:
        return BeamTheme.warningOrange;
      case CustomMessageType.redirected:
        return BeamTheme.accentTeal;
      case CustomMessageType.error:
        return Colors.grey;
      default:
        return BeamTheme.accentAmber;
    }
  }

  Color _getBubbleColor(CustomMessageType type) {
    switch (type) {
      case CustomMessageType.declined:
        return BeamTheme.warningOrange.withOpacity(0.05);
      case CustomMessageType.redirected:
        return BeamTheme.accentTeal.withOpacity(0.05);
      default:
        return Colors.white;
    }
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

enum CustomMessageType {
  welcome,
  user,
  ai,
  declined,
  redirected,
  error,
}

class _CustomChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final CustomMessageType messageType;
  final int? creditsCharged;

  _CustomChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
    this.creditsCharged,
  });
}

class _MessageActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MessageActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
