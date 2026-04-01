import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:beam/core/services/ai_service.dart';
import 'package:beam/core/widgets/ai_action_sheet.dart';
import 'package:beam/core/widgets/app_button.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, this.document});

  final Map<String, dynamic>? document;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isLoading = true;
  String? _error;
  int? _totalPages;
  int _currentPage = 0;
  Uint8List? _pdfData;
  bool _isProcessingAI = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final fileUrl = widget.document?['file_url'] as String?;
    if (fileUrl == null) {
      setState(() {
        _error = 'No PDF URL available';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        setState(() {
          _pdfData = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load PDF: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processAIRequest(String task) async {
    if (_isProcessingAI) return;

    setState(() => _isProcessingAI = true);

    try {
      final aiService = AIService();
      // For demo, use dummy content - in real app, extract text from PDF
      final dummyContent = 'This is sample document content for AI processing. It contains information about taxes, income, deductions, and calculations.';

      final result = await aiService.processAIRequest(
        task: task,
        content: dummyContent,
      );

      if (mounted) {
        context.go('/ai-result', extra: {
          'task': task,
          'result': result['result'],
          'model_used': result['model_used'],
          'tokens_used': result['tokens_used'],
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('PAYWALL')) {
          _showPaywallDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI request failed: $errorMessage')),
          );
        }
      }
    } finally {
      setState(() => _isProcessingAI = false);
    }
  }

  void _showPaywallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usage Limit Exceeded'),
        content: const Text(
          'You\'ve reached your free plan limits. Upgrade to Pro for unlimited AI features and premium document processing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/paywall');
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;

    if (document == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document Viewer')),
        body: const Center(child: Text('No document selected')),
      );
    }

    final fileUrl = document['file_url'] as String?;
    final title = document['title'] as String? ?? 'Untitled';
    final createdAt = document['created_at'] != null
        ? DateTime.parse(document['created_at'])
        : DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Document header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Created on $formattedDate',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: fileUrl != null
                ? Stack(
                    children: [
                      PDFView(
                        filePath: null,
                        pdfData: _pdfData,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: false,
                        pageFling: false,
                        onRender: (pages) {
                          setState(() {
                            _totalPages = pages;
                            _isLoading = false;
                          });
                        },
                        onError: (error) {
                          setState(() {
                            _error = error.toString();
                            _isLoading = false;
                          });
                        },
                        onPageError: (page, error) {
                          setState(() {
                            _error = 'Page $page error: $error';
                          });
                        },
                        onViewCreated: (PDFViewController pdfViewController) {
                          // Controller available
                        },
                        onPageChanged: (page, total) {
                          setState(() {
                            _currentPage = page!;
                          });
                        },
                      ),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator()),
                      if (_error != null)
                        Center(
                          child: Text(
                            'Error loading PDF: $_error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  )
                : const Center(child: Text('PDF URL not available')),
          ),
          // Page indicator and actions
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                if (_totalPages != null && _totalPages! > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                Row(
                  children: [
                      Expanded(
                        child: AppButton(
                          text: 'Ask AI',
                          isLoading: _isProcessingAI,
                          onPressed: () {
                            AIActionSheet.show(context, (task) {
                              _processAIRequest(task);
                            });
                          },
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Implement export
                        },
                        child: const Text('Export'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}