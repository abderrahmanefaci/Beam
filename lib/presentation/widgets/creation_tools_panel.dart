import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../screens/tools_screen.dart';
import '../screens/scanner_screen.dart';

/// Creation Tools Panel - Bottom sheet for creation tools
class CreationToolsPanel extends StatelessWidget {
  final ToolDefinition tool;

  const CreationToolsPanel({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: BeamTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BeamTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tool.icon,
                      color: BeamTheme.successGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tool.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: BeamTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tool interface
            _buildToolInterface(context),
          ],
        ),
      ),
    );
  }

  Widget _buildToolInterface(BuildContext context) {
    switch (tool.id) {
      case 'new_document':
        return _buildNewDocumentInterface(context);
      case 'new_spreadsheet':
        return _buildNewSpreadsheetInterface(context);
      case 'scan_to_file':
        return _buildScanInterface(context);
      case 'e_signature':
        return _buildESignatureInterface(context);
      default:
        return _buildPlaceholderInterface(context);
    }
  }

  Widget _buildNewDocumentInterface(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Create a new blank document'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Create blank .docx and open editor
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening document editor...')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: BeamTheme.successGreen,
            ),
            child: const Text('Create Document'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'This will create a blank .docx file and open it in the editor.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewSpreadsheetInterface(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Create a new blank spreadsheet'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Create blank .xlsx and open editor
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening spreadsheet editor...')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: BeamTheme.successGreen,
            ),
            child: const Text('Create Spreadsheet'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'This will create a blank .xlsx file and open it in the editor.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanInterface(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Scan a document using your camera'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to scanner tab
              // For MVP, show placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening scanner...')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: BeamTheme.successGreen,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.document_scanner),
                SizedBox(width: 8),
                Text('Open Scanner'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Use your camera to scan documents. They will be saved to your library.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildESignatureInterface(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Create or manage your digital signatures'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Open signature pad (Task 10)
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening signature pad...')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: BeamTheme.successGreen,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Create Signature'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // TODO: Show saved signatures
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved signatures - Coming soon')),
              );
            },
            child: const Text('View Saved Signatures'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Create a signature to sign PDF documents. Signatures are saved securely.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderInterface(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tool.icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '${tool.name} - Coming Soon',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This tool is under development',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
