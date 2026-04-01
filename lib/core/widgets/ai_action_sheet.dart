import 'package:flutter/material.dart';

class AIActionSheet extends StatelessWidget {
  const AIActionSheet({super.key, required this.onTaskSelected});

  final Function(String task) onTaskSelected;

  final List<Map<String, dynamic>> _actions = const [
    {
      'task': 'summarize',
      'title': 'Summarize',
      'description': 'Get a concise summary of the document',
      'icon': Icons.summarize,
    },
    {
      'task': 'chat_doc',
      'title': 'Chat with Document',
      'description': 'Ask questions about the document content',
      'icon': Icons.chat,
    },
    {
      'task': 'translate',
      'title': 'Translate',
      'description': 'Translate the document to another language',
      'icon': Icons.translate,
    },
    {
      'task': 'extract_text',
      'title': 'Extract Text',
      'description': 'Extract key information and text',
      'icon': Icons.text_fields,
    },
    {
      'task': 'solve_homework',
      'title': 'Solve Homework',
      'description': 'Get help solving academic problems',
      'icon': Icons.school,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose AI Action',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _actions.length,
            itemBuilder: (context, index) {
              final action = _actions[index];
              return ListTile(
                leading: Icon(
                  action['icon'] as IconData,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(action['title'] as String),
                subtitle: Text(action['description'] as String),
                onTap: () {
                  Navigator.of(context).pop();
                  onTaskSelected(action['task'] as String);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context, Function(String task) onTaskSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AIActionSheet(onTaskSelected: onTaskSelected),
    );
  }
}