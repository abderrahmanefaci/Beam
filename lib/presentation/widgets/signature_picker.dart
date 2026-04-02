import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../../services/signature_service.dart';

/// Signature Picker Widget - For selecting signature to apply to PDF
class SignaturePicker extends StatefulWidget {
  final Function(String signatureUrl) onSignatureSelected;

  const SignaturePicker({
    super.key,
    required this.onSignatureSelected,
  });

  @override
  State<SignaturePicker> createState() => _SignaturePickerState();
}

class _SignaturePickerState extends State<SignaturePicker> {
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
    }
  }

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
                  'Select Signature',
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_signatures.isEmpty)
              _buildEmptyState()
            else
              _buildSignaturesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.edit, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No signatures saved',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to signature pad
              // For MVP, show placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create signature first')),
              );
            },
            child: const Text('Create Signature'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesList() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _signatures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final signature = _signatures[index];
          return _SignatureOption(
            signature: signature,
            onTap: () {
              widget.onSignatureSelected(signature['file_url'] as String);
              Navigator.of(context).pop(signature);
            },
          );
        },
      ),
    );
  }
}

class _SignatureOption extends StatelessWidget {
  final Map<String, dynamic> signature;
  final VoidCallback onTap;

  const _SignatureOption({
    required this.signature,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BeamTheme.primaryPurple),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Signature preview
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: signature['file_url'] != null
                  ? Image.network(
                      signature['file_url'] as String,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.edit, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              signature['label'] as String? ?? 'Signature',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
