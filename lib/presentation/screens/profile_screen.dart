import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/beam_theme.dart';
import '../../core/constants/beam_constants.dart';
import '../../providers/providers.dart';
import '../../services/supabase_service.dart';
import '../screens/manage_signatures_screen.dart';
import '../screens/signature_pad_screen.dart';
import '../screens/paywall_screen.dart';
import 'package:share_plus/share_plus.dart';

/// Profile Screen - Account, subscription, settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _imagePicker = ImagePicker();
  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: BeamTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings placeholder
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildContent(user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildContent(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(user),
          const SizedBox(height: 24),

          // Plan Card
          _buildPlanCard(user),
          const SizedBox(height: 16),

          // Storage Card
          _buildStorageCard(user),
          const SizedBox(height: 24),

          // Settings Sections
          _buildSectionHeader('Account'),
          _buildAccountSection(user),
          const SizedBox(height: 16),

          _buildSectionHeader('App'),
          _buildAppSection(),
          const SizedBox(height: 16),

          _buildSectionHeader('Data'),
          _buildDataSection(),
          const SizedBox(height: 16),

          _buildSectionHeader('About'),
          _buildAboutSection(),
          const SizedBox(height: 16),

          _buildSectionHeader('Danger Zone'),
          _buildDangerSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar
              GestureDetector(
                onTap: _uploadAvatar,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: BeamTheme.primaryPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isUploadingAvatar
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user.avatarUrl as String,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 50,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 50,
                            ),
                ),
              ),
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: BeamTheme.primaryPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name and email
          Text(
            user?.displayName ?? user?.email?.split('@').first ?? 'User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: BeamTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(dynamic user) {
    final isPremium = user?.plan == 'premium';
    final aiDocsUsed = user?.aiDocsUsed ?? 0;
    final creditsRemaining = user?.creditsRemaining ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [BeamTheme.primaryPurple, BeamTheme.primaryPurpleDark]
              : [Colors.grey.shade700, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? BeamTheme.primaryPurple : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isPremium ? Icons.workspace_premium : Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPremium ? 'Premium Plan' : 'Free Plan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BeamTheme.accentAmber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isPremium) ...[
            // Premium: Show credits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$creditsRemaining credits remaining',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  'Resets ${_getNextResetDate()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Free: Show AI usage
            Text(
              '$aiDocsUsed of ${BeamConstants.freeAiDocumentsLimit} AI documents used',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: aiDocsUsed / BeamConstants.freeAiDocumentsLimit,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BeamTheme.accentAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Upgrade to Premium'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStorageCard(dynamic user) {
    final storageUsed = user?.storageUsedBytes ?? 0;
    final storageUsedMB = storageUsed / (1024 * 1024);
    final storageLimitMB = 100; // Free tier limit
    final storagePercent = (storageUsedMB / storageLimitMB).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.storage, color: BeamTheme.primaryPurple),
                  SizedBox(width: 8),
                  Text(
                    'Storage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${storageUsedMB.toStringAsFixed(1)} / ${storageLimitMB} MB',
                style: TextStyle(
                  fontSize: 14,
                  color: BeamTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: storagePercent,
              backgroundColor: Colors.grey.shade200,
              valueColor: storagePercent > 0.8
                  ? const AlwaysStoppedAnimation<Color>(BeamTheme.errorRed)
                  : const AlwaysStoppedAnimation<Color>(BeamTheme.primaryPurple),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: BeamTheme.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildAccountSection(dynamic user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: BeamTheme.primaryPurple),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editProfile,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock, color: BeamTheme.primaryPurple),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit, color: BeamTheme.primaryPurple),
            title: const Text('Manage Signatures'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _manageSignatures,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSection() {
    bool notificationsEnabled = true; // Placeholder state

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications, color: BeamTheme.primaryPurple),
            title: const Text('Notifications'),
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
              activeColor: BeamTheme.primaryPurple,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description, color: BeamTheme.primaryPurple),
            title: const Text('Default Output Format'),
            subtitle: const Text('PDF'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show format picker
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history, color: BeamTheme.primaryPurple),
            title: const Text('Version History'),
            subtitle: const Text('All documents'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to version history
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: BeamTheme.primaryPurple),
            title: const Text('Clear Cache'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: BeamTheme.primaryPurple),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description, color: BeamTheme.primaryPurple),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Open terms
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: BeamTheme.primaryPurple),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Open privacy policy
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.star, color: BeamTheme.primaryPurple),
            title: const Text('Rate the App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _rateApp,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BeamTheme.errorRed.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: BeamTheme.errorRed),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: BeamTheme.errorRed),
        ),
        subtitle: const Text('Permanently delete all data'),
        trailing: const Icon(Icons.chevron_right, color: BeamTheme.errorRed),
        onTap: _deleteAccount,
      ),
    );
  }

  String _getNextResetDate() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return DateFormat('MMM d').format(nextMonth);
  }

  // Actions
  Future<void> _uploadAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        setState(() => _isUploadingAvatar = true);

        // Upload to Supabase Storage
        final file = File(image.path);
        final user = SupabaseService.currentUser;
        
        if (user != null) {
          await SupabaseService.client.storage
              .from('avatars')
              .uploadBinary('${user.id}/avatar.png', await file.readAsBytes());

          final avatarUrl = await SupabaseService.client.storage
              .from('avatars')
              .createSignedUrl('${user.id}/avatar.png', 60 * 60 * 24 * 365);

          // Update user profile
          await ref.read(userNotifierProvider.notifier).updateProfile(
                avatarUrl: avatarUrl,
              );
        }

        setState(() => _isUploadingAvatar = false);
      }
    } catch (e) {
      setState(() => _isUploadingAvatar = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e'),
            backgroundColor: BeamTheme.errorRed,
          ),
        );
      }
    }
  }

  void _editProfile() {
    // Show edit profile dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Edit profile - Coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    // Show change password dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Change password - Coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageSignatures() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageSignaturesScreen()),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    // Open app store for rating
    Share.share('Check out Beam - AI-Powered Document Intelligence Platform!');
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Delete account
              ref.read(userRepositoryProvider).deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BeamTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
