import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:beam/core/services/document_service.dart';
import 'package:beam/core/widgets/app_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DocumentService _documentService = DocumentService();
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() => _isLoading = true);
      final documents = await _documentService.fetchUserDocuments();
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    try {
      await _documentService.deleteDocument(documentId);
      await _loadDocuments(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 80,
                        color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading documents',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadDocuments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _documents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No documents yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan or upload your first document',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/scanner'),
                            icon: const Icon(Icons.document_scanner),
                            label: const Text('Scan Document'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDocuments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          final createdAt = DateTime.parse(doc['created_at']);
                          final formattedDate = DateFormat('MMM dd, yyyy').format(createdAt);

                          return AppCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.description,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(doc['title'] ?? 'Untitled'),
                              subtitle: Text(formattedDate),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Document'),
                                        content: const Text('Are you sure you want to delete this document?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _deleteDocument(doc['id']);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                              onTap: () => context.go('/document-viewer', extra: doc),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/scanner'),
        child: const Icon(Icons.add),
      ),
    );
  }
}