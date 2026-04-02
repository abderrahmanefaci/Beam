import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';

/// AI Skill Buttons Widget
/// Displays 5 floating action buttons around the document
class AiSkillButtons extends StatelessWidget {
  final VoidCallback onSummarize;
  final VoidCallback onTranslate;
  final VoidCallback onExtractText;
  final VoidCallback onExtractTables;
  final VoidCallback onChat;
  final VoidCallback onMore;

  const AiSkillButtons({
    super.key,
    required this.onSummarize,
    required this.onTranslate,
    required this.onExtractText,
    required this.onExtractTables,
    required this.onChat,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top: Summarize
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: _SkillButton(
              icon: Icons.auto_awesome,
              label: 'Summarize',
              color: BeamTheme.accentTeal,
              onTap: onSummarize,
            ),
          ),
        ),
        // Left: Translate
        Positioned(
          top: 0,
          bottom: 0,
          left: 40,
          child: Center(
            child: _SkillButton(
              icon: Icons.language,
              label: 'Translate',
              color: BeamTheme.accentTeal,
              onTap: onTranslate,
              vertical: true,
            ),
          ),
        ),
        // Right: Extract
        Positioned(
          top: 0,
          bottom: 0,
          right: 40,
          child: Center(
            child: _SkillButton(
              icon: Icons.text_fields,
              label: 'Extract',
              color: BeamTheme.accentTeal,
              onTap: onExtractText,
              vertical: true,
            ),
          ),
        ),
        // Bottom-Left: Chat
        Positioned(
          bottom: 100,
          left: 80,
          child: _SkillButton(
            icon: Icons.chat,
            label: 'Chat',
            color: BeamTheme.accentTeal,
            onTap: onChat,
          ),
        ),
        // Bottom-Right: More
        Positioned(
          bottom: 100,
          right: 80,
          child: _SkillButton(
            icon: Icons.more_horiz,
            label: 'More...',
            color: BeamTheme.accentAmber,
            onTap: onMore,
          ),
        ),
      ],
    );
  }
}

class _SkillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool vertical;

  const _SkillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.vertical = false,
  });

  @override
  State<_SkillButton> createState() => _SkillButtonState();
}

class _SkillButtonState extends State<_SkillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.vertical) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
