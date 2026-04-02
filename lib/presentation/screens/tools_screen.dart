import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../widgets/tool_card.dart';
import '../widgets/tool_panel_sheet.dart';
import '../widgets/ai_tools_panel.dart';
import '../widgets/document_tools_panel.dart';
import '../widgets/creation_tools_panel.dart';

/// Tool definition
class ToolDefinition {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final ToolCategory category;
  final bool isAiPowered;

  const ToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.isAiPowered = false,
  });
}

enum ToolCategory {
  document,
  ai,
  creation,
}

/// Tools Tab Screen - Grid of all available features
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  // All tools definition
  static final List<ToolDefinition> allTools = [
    // Document Tools
    const ToolDefinition(
      id: 'merge_pdf',
      name: 'Merge PDFs',
      description: 'Combine multiple PDFs into one',
      icon: Icons.merge_type,
      category: ToolCategory.document,
    ),
    const ToolDefinition(
      id: 'split_pdf',
      name: 'Split PDF',
      description: 'Divide PDF into multiple files',
      icon: Icons.call_split,
      category: ToolCategory.document,
    ),
    const ToolDefinition(
      id: 'compress_pdf',
      name: 'Compress PDF',
      description: 'Reduce PDF file size',
      icon: Icons.compress,
      category: ToolCategory.document,
    ),
    const ToolDefinition(
      id: 'pdf_to_images',
      name: 'PDF to Images',
      description: 'Convert PDF pages to images',
      icon: Icons.image,
      category: ToolCategory.document,
    ),
    const ToolDefinition(
      id: 'images_to_pdf',
      name: 'Images to PDF',
      description: 'Combine images into PDF',
      icon: Icons.picture_as_pdf,
      category: ToolCategory.document,
    ),
    // AI Tools
    const ToolDefinition(
      id: 'ai_summarize',
      name: 'Summarize',
      description: 'Get quick summary of document',
      icon: Icons.auto_awesome,
      category: ToolCategory.ai,
      isAiPowered: true,
    ),
    const ToolDefinition(
      id: 'ai_translate',
      name: 'Translate',
      description: 'Translate to any language',
      icon: Icons.language,
      category: ToolCategory.ai,
      isAiPowered: true,
    ),
    const ToolDefinition(
      id: 'ai_extract',
      name: 'Extract Text',
      description: 'Extract all text content',
      icon: Icons.text_fields,
      category: ToolCategory.ai,
      isAiPowered: true,
    ),
    const ToolDefinition(
      id: 'ai_convert',
      name: 'Convert Format',
      description: 'Convert between formats',
      icon: Icons.swap_horiz,
      category: ToolCategory.ai,
      isAiPowered: true,
    ),
    const ToolDefinition(
      id: 'ai_custom',
      name: 'Custom AI',
      description: 'Custom AI requests',
      icon: Icons.smart_toy,
      category: ToolCategory.ai,
      isAiPowered: true,
    ),
    // Creation Tools
    const ToolDefinition(
      id: 'new_document',
      name: 'New Document',
      description: 'Create blank document',
      icon: Icons.note_add,
      category: ToolCategory.creation,
    ),
    const ToolDefinition(
      id: 'new_spreadsheet',
      name: 'New Spreadsheet',
      description: 'Create blank spreadsheet',
      icon: Icons.table_chart,
      category: ToolCategory.creation,
    ),
    const ToolDefinition(
      id: 'scan_to_file',
      name: 'Scan to File',
      description: 'Scan document with camera',
      icon: Icons.document_scanner,
      category: ToolCategory.creation,
    ),
    const ToolDefinition(
      id: 'e_signature',
      name: 'E-Signature',
      description: 'Create digital signature',
      icon: Icons.edit,
      category: ToolCategory.creation,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Tools Section
            _buildSectionHeader('Document Tools'),
            const SizedBox(height: 12),
            _buildToolsGrid(ToolCategory.document),
            const SizedBox(height: 24),
            // AI Tools Section
            _buildSectionHeader('AI Tools'),
            const SizedBox(height: 12),
            _buildToolsGrid(ToolCategory.ai),
            const SizedBox(height: 24),
            // Creation Tools Section
            _buildSectionHeader('Create'),
            const SizedBox(height: 12),
            _buildToolsGrid(ToolCategory.creation),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: BeamTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildToolsGrid(ToolCategory category) {
    final tools = allTools.where((t) => t.category == category).toList();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return ToolCard(
          tool: tool,
          onTap: () => _handleToolTap(context, tool),
        );
      },
    );
  }

  void _handleToolTap(BuildContext context, ToolDefinition tool) {
    Widget panel;

    switch (tool.category) {
      case ToolCategory.document:
        panel = DocumentToolsPanel(tool: tool);
        break;
      case ToolCategory.ai:
        panel = AiToolsPanel(tool: tool);
        break;
      case ToolCategory.creation:
        panel = CreationToolsPanel(tool: tool);
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => panel,
    );
  }
}
