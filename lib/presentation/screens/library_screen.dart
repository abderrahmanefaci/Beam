import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/beam_theme.dart';
import '../../core/constants/beam_constants.dart';
import '../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../widgets/library_file_card.dart';
import '../widgets/library_file_row.dart';
import '../widgets/library_folder_card.dart';
import '../widgets/file_actions_bottom_sheet.dart';
import '../widgets/folder_actions_bottom_sheet.dart';
import '../widgets/library_empty_state.dart';
import '../widgets/library_search_bar.dart';
import 'document_viewer_screen.dart';

/// Sort options for library
enum LibrarySortOption {
  dateModified('Date Modified'),
  dateCreated('Date Created'),
  nameAZ('Name (A-Z)'),
  fileSize('File Size');

  final String label;
  const LibrarySortOption(this.label);
}

/// Library Screen - Central hub for all user files
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _currentFolderId;
  bool _isGridView = true;
  LibrarySortOption _sortOption = LibrarySortOption.dateModified;
  bool _ascending = false;
  final _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadCurrentFolder();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCurrentFolder() {
    ref.read(documentsNotifierProvider.notifier).loadDocuments(
          folderId: _currentFolderId,
        );
    ref.read(foldersNotifierProvider.notifier).loadFolders(
          parentFolderId: _currentFolderId,
        );
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
  }

  void _navigateIntoFolder(FolderEntity folder) {
    setState(() {
      _currentFolderId = folder.id;
      _searchQuery = null;
      _searchController.clear();
    });
    _loadCurrentFolder();
  }

  void _navigateUp() {
    // Navigate to parent folder
    if (_currentFolderId != null) {
      // Get current folder to find parent
      // For simplicity, we'll just clear to root
      setState(() {
        _currentFolderId = null;
      });
      _loadCurrentFolder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersNotifierProvider);
    final documentsAsync = ref.watch(documentsNotifierProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: BeamTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          // View toggle
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          // Sort button
          PopupMenuButton<LibrarySortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) {
              setState(() {
                if (_sortOption == option) {
                  _ascending = !_ascending;
                } else {
                  _sortOption = option;
                  _ascending = false;
                }
                _loadCurrentFolder();
              });
            },
            itemBuilder: (context) => LibrarySortOption.values
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          Text(option.label),
                          if (_sortOption == option) ...[
                            const SizedBox(width: 8),
                            Icon(
                              _ascending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          LibrarySearchBar(
            controller: _searchController,
            onSearch: _handleSearch,
          ),
          // Breadcrumb and folder chips
          _buildBreadcrumbSection(foldersAsync),
          // Content
          Expanded(
            child: userAsync.when(
              data: (user) => _buildContent(
                  foldersAsync, documentsAsync, user?.id ?? ''),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildBreadcrumbSection(AsyncValue<List<FolderEntity>> foldersAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: BeamTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              if (_currentFolderId != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: _navigateUp,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Root folder
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentFolderId = null;
                          });
                          _loadCurrentFolder();
                        },
                        child: Text(
                          'Library',
                          style: TextStyle(
                            color: _currentFolderId == null
                                ? BeamTheme.primaryPurple
                                : BeamTheme.textSecondaryLight,
                            fontWeight: _currentFolderId == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      // Current folder breadcrumb (simplified)
                      if (_currentFolderId != null) ...[
                        const Text(' / ', style: TextStyle(color: Colors.grey)),
                        Text(
                          'Folder',
                          style: TextStyle(
                            color: BeamTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Subfolder chips
          foldersAsync.when(
            data: (folders) {
              if (folders.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: folders.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return _FolderChip(
                      folder: folder,
                      onTap: () => _navigateIntoFolder(folder),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<List<FolderEntity>> foldersAsync,
    AsyncValue<List<DocumentEntity>> documentsAsync,
    String userId,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadCurrentFolder();
      },
      color: BeamTheme.primaryPurple,
      child: CustomScrollView(
        slivers: [
          // Folders section
          foldersAsync.when(
            data: (folders) {
              if (folders.isEmpty) return const SliverToBoxAdapter();
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Folders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BeamTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: folders.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return LibraryFolderCard(
                              folder: folders[index],
                              onTap: () => _navigateIntoFolder(folders[index]),
                              onLongPress: () => _showFolderActions(
                                  folders[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading folders: $error'),
              ),
            ),
          ),
          // Files section
          documentsAsync.when(
            data: (documents) {
              if (documents.isEmpty) {
                return SliverFillRemaining(
                  child: LibraryEmptyState(
                    onScanTap: () {
                      // Navigate to scanner
                    },
                  ),
                );
              }

              if (_isGridView) {
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = documents[index];
                      return LibraryFileCard(
                        document: doc,
                        onTap: () => _openDocument(doc),
                        onLongPress: () => _showFileActions(doc),
                        onFavoriteTap: () => _toggleFavorite(doc),
                      );
                    },
                    childCount: documents.length,
                  ),
                );
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = documents[index];
                      return LibraryFileRow(
                        document: doc,
                        onTap: () => _openDocument(doc),
                        onLongPress: () => _showFileActions(doc),
                        onFavoriteTap: () => _toggleFavorite(doc),
                      );
                    },
                    childCount: documents.length,
                  ),
                );
              }
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _showFabMenu,
      backgroundColor: BeamTheme.primaryPurple,
      child: const Icon(Icons.add),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCurrentFolder,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _openDocument(DocumentEntity document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(document: document),
      ),
    );
  }

  void _showFileActions(DocumentEntity document) {
    showModalBottomSheet(
      context: context,
      builder: (_) => FileActionsBottomSheet(
        document: document,
        onOpen: () => _openDocument(document),
        onRename: () => _showRenameDialog(document),
        onDuplicate: () => _duplicateDocument(document),
        onMove: () => _showMoveDialog(document),
        onShare: () => _shareDocument(document),
        onDelete: () => _deleteDocument(document),
      ),
    );
  }

  void _showFolderActions(FolderEntity folder) {
    showModalBottomSheet(
      context: context,
      builder: (_) => FolderActionsBottomSheet(
        folder: folder,
        onRename: () => _showRenameFolderDialog(folder),
        onDelete: () => _deleteFolder(folder),
      ),
    );
  }

  void _showFabMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('New Folder'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCreateFolderDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Import File'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement file import
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(DocumentEntity document) async {
    final controller = TextEditingController(text: document.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != document.title) {
      await ref
          .read(documentsNotifierProvider.notifier)
          .renameDocument(document.id, result);
    }
  }

  Future<void> _duplicateDocument(DocumentEntity document) async {
    try {
      await ref
          .read(documentRepositoryProvider)
          .duplicateDocument(document.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document duplicated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(DocumentEntity document) async {
    await ref
        .read(documentsNotifierProvider.notifier)
        .toggleFavorite(document.id, !document.favorite);
  }

  Future<void> _deleteDocument(DocumentEntity document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BeamTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(documentsNotifierProvider.notifier)
          .deleteDocument(document.id);
    }
  }

  void _showMoveDialog(DocumentEntity document) {
    // TODO: Implement move to folder dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Move to folder - Coming soon')),
    );
  }

  void _shareDocument(DocumentEntity document) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share - Coming soon')),
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(foldersNotifierProvider.notifier).createFolder(
            result,
            parentFolderId: _currentFolderId,
          );
    }
  }

  Future<void> _showRenameFolderDialog(FolderEntity folder) async {
    final controller = TextEditingController(text: folder.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != folder.name) {
      await ref
          .read(foldersNotifierProvider.notifier)
          .renameFolder(folder.id, result);
    }
  }

  Future<void> _deleteFolder(FolderEntity folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
            'Are you sure you want to delete "${folder.name}"? This will also delete all files inside.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BeamTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(foldersNotifierProvider.notifier)
          .deleteFolder(folder.id);
    }
  }
}

class _FolderChip extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback onTap;

  const _FolderChip({
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: BeamTheme.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BeamTheme.primaryPurple),
        ),
        child: Text(
          folder.name,
          style: const TextStyle(
            color: BeamTheme.primaryPurple,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
