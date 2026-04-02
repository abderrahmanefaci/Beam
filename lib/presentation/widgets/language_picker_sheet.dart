import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../../services/ai_service.dart';

/// Language Picker Bottom Sheet
class LanguagePickerSheet extends StatelessWidget {
  final Function(SupportedLanguage) onLanguageSelected;

  const LanguagePickerSheet({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                itemCount: SupportedLanguage.languages.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final language = SupportedLanguage.languages[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: BeamTheme.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          language.code.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: BeamTheme.primaryPurple,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      language.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      language.nativeName,
                      style: TextStyle(
                        color: BeamTheme.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => onLanguageSelected(language),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
