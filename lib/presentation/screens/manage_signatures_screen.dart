import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/beam_theme.dart';
import '../../services/signature_service.dart';
import 'signature_pad_screen.dart';

/// Manage Signatures Screen - Grid of saved signatures
class ManageSignaturesScreen extends ConsumerStatefulWidget {
  const ManageSignaturesScreen({super.key});

  @override
  ConsumerState<ManageSignaturesScreen> createState() => _ManageSignaturesScreenState();
}

class _ManageSignaturesScreenState extends ConsumerState<ManageSignaturesScreen> {
  final _signatureService = SignatureService();
  List<Map<String, dynamic>> _signatures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSignatures();
  }

  Future<void> _loadSignatures() async {
    setState(() => _isLoading = true);
    try {
      final signatures = await _signatureService.getSignatures();
      setState(() {
        _signatures = signatures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load signatures: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Signatures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNewSignature(),
            tooltip: 'Add New',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _signatures.isEmpty
              ? _buildEmptyState()
              : _buildSignaturesGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No signatures yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first signature to sign documents',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addNewSignature,
            icon: const Icon(Icons.add),
            label: const Text('Create Signature'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: _signatures.length,
      itemBuilder: (context, index) {
        final signature = _signatures[index];
        return _SignatureCard(
          signature: signature,
          onTap: () => _selectSignature(signature),
          onLongPress: () => _showSignatureOptions(signature),
          onDelete: () => _deleteSignature(signature),
        );
      },
    );
  }

  Future<void> _addNewSignature() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SignaturePadScreen()),
    );

    if (result == true && mounted) {
      _loadSignatures();
    }
  }

  void _selectSignature(Map<String, dynamic> signature) {
    Navigator.of(context).pop(signature);
  }

  void _showSignatureOptions(Map<String, dynamic> signature) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.of(context).pop();
                  _renameSignature(signature);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteSignature(signature);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameSignature(Map<String, dynamic> signature) async {
    final controller = TextEditingController(text: signature['label'] as String);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Signature'),
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

    if (result != null && result.isNotEmpty) {
      await _signatureService.updateSignatureLabel(signature['id'] as String, result);
      _loadSignatures();
    }
  }

  Future<void> _deleteSignature(Map<String, dynamic> signature) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Signature'),
        content: const Text('Are you sure you want to delete this signature?'),
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
      await _signatureService.deleteSignature(signature['id'] as String);
      _loadSignatures();
    }
  }
}

class _SignatureCard extends StatelessWidget {
  final Map<String, dynamic> signature;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _SignatureCard({
    required this.signature,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Signature preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: signature['file_url'] != null
                      ? Image.network(
                          signature['file_url'] as String,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.edit,
                              color: Colors.grey,
                            );
                          },
                        )
                      : const Icon(
                          Icons.edit,
                          color: Colors.grey,
                        ),
                ),
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                signature['label'] as String? ?? 'Signature',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
