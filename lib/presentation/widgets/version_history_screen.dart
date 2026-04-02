import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/beam_theme.dart';
import '../../providers/providers.dart';
import '../../services/editor_service.dart';

/// Version History Screen
class VersionHistoryScreen extends ConsumerStatefulWidget {
  final String documentId;

  const VersionHistoryScreen({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends ConsumerState<VersionHistoryScreen> {
  final _editorService = EditorService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _versions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _isLoading = true);

    try {
      final versions = await _editorService.getVersions(widget.documentId);
      setState(() {
        _versions = versions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Version History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _versions.isEmpty
                  ? _buildEmptyState()
                  : _buildVersionList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Failed to load versions: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadVersions,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No version history',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Versions will appear here as you edit',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _versions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final version = _versions[index];
        return _VersionCard(
          version: version,
          isCurrentVersion: index == 0,
          onRevert: () => _confirmRevert(version),
        );
      },
    );
  }

  Future<void> _confirmRevert(Map<String, dynamic> version) async {
    final versionNumber = version['version_number'] as int;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert to this version?'),
        content: Text(
          'This will create a new version based on version $versionNumber. '
          'The current version will be preserved in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BeamTheme.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _revertToVersion(version);
    }
  }

  Future<void> _revertToVersion(Map<String, dynamic> version) async {
    final versionNumber = version['version_number'] as int;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _editorService.revertToVersion(
        documentId: widget.documentId,
        versionNumber: versionNumber,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        Navigator.of(context).pop(); // Close version history
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reverted to version $versionNumber'),
            backgroundColor: BeamTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to revert: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }
}

class _VersionCard extends StatelessWidget {
  final Map<String, dynamic> version;
  final bool isCurrentVersion;
  final VoidCallback onRevert;

  const _VersionCard({
    required this.version,
    required this.isCurrentVersion,
    required this.onRevert,
  });

  @override
  Widget build(BuildContext context) {
    final versionNumber = version['version_number'] as int;
    final isAutosave = version['is_autosave'] as bool;
    final label = version['label'] as String?;
    final savedAt = DateTime.parse(version['saved_at'] as String);
    final fileSize = version['file_size_bytes'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BeamTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentVersion
              ? BeamTheme.successGreen
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Version number badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isCurrentVersion
                  ? BeamTheme.successGreen.withOpacity(0.1)
                  : BeamTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'v$versionNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentVersion
                      ? BeamTheme.successGreen
                      : BeamTheme.primaryPurple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Text(
                      label ?? 'Version $versionNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isAutosave)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: BeamTheme.accentAmber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Auto',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: BeamTheme.accentAmber,
                          ),
                        ),
                      ),
                    if (isCurrentVersion) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: BeamTheme.successGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: BeamTheme.successGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Meta row
                Row(
                  children: [
                    Text(
                      _formatDate(savedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: BeamTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatFileSize(fileSize),
                      style: TextStyle(
                        fontSize: 12,
                        color: BeamTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Revert button
          if (!isCurrentVersion)
            TextButton(
              onPressed: onRevert,
              child: const Text('Revert'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, y h:mm a').format(date);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
