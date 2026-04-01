import 'package:flutter/material.dart';

class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  final String title;
  final Widget content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content,
      actions: actions,
    );
  }

  static void show({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (context) => AppModal(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}