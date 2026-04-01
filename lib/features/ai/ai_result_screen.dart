import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AIResultScreen extends StatelessWidget {
  const AIResultScreen({
    super.key,
    required this.task,
    required this.result,
    required this.modelUsed,
    required this.tokensUsed,
  });

  final String task;
  final String result;
  final String modelUsed;
  final int tokensUsed;

  String _getTaskTitle(String task) {
    switch (task) {
      case 'summarize':
        return 'Document Summary';
      case 'chat_doc':
        return 'Document Chat';
      case 'translate':
        return 'Translation';
      case 'extract_text':
        return 'Extracted Text';
      case 'solve_homework':
        return 'Homework Solution';
      default:
        return 'AI Result';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTaskTitle(task)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTaskTitle(task),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Powered by $modelUsed • $tokensUsed tokens used',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Result content
            Text(
              'Result',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Text(
                result,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Document'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement follow-up
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ask another question coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Ask Another'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}