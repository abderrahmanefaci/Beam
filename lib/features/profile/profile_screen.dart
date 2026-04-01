import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beam/core/services/auth_provider.dart';
import 'package:beam/core/services/ai_service.dart';
import 'package:beam/core/widgets/app_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _usageStats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUsageStats();
  }

  Future<void> _loadUsageStats() async {
    try {
      final aiService = AIService();
      final stats = await aiService.getUsageStats();
      setState(() {
        _usageStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  Map<String, int> _getLimits() {
    return {
      'summarize': 5,
      'chat_doc': 3,
      'translate': 2,
      'extract_text': 2,
      'solve_homework': 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final limits = _getLimits();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile header
            AppCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Free Plan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Usage Stats
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage This Month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingStats
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: limits.entries.map((entry) {
                            final used = _usageStats[entry.key] ?? 0;
                            final percentage = (used / entry.value).clamp(0.0, 1.0);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _getTaskDisplayName(entry.key),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '$used / ${entry.value}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      percentage >= 0.8
                                          ? Colors.red
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Upgrade prompt if limits exceeded
            if (_hasExceededLimits(limits))
              AppCard(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Theme.of(context).colorScheme.error,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Usage Limits Exceeded',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upgrade to Pro for unlimited AI features',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushNamed('/paywall'),
                        child: const Text('Upgrade Now'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Menu items
            _buildMenuItem(
              context,
              icon: Icons.library_books,
              title: 'My Library',
              subtitle: 'View all documents',
              onTap: () => Navigator.of(context).pushNamed('/library'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.document_scanner,
              title: 'Scan Document',
              subtitle: 'Add new document',
              onTap: () => Navigator.of(context).pushNamed('/scanner'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.subscriptions,
              title: 'Subscription',
              subtitle: 'Manage your plan',
              onTap: () => Navigator.of(context).pushNamed('/paywall'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'App preferences',
              onTap: () {
                // TODO: Implement settings
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () {
                // TODO: Implement help
              },
            ),
            const SizedBox(height: 24),
            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await context.read<AuthProvider>().signOut();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: ${e.toString()}')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTaskDisplayName(String task) {
    switch (task) {
      case 'summarize':
        return 'Document Summaries';
      case 'chat_doc':
        return 'Document Chats';
      case 'translate':
        return 'Translations';
      case 'extract_text':
        return 'Text Extractions';
      case 'solve_homework':
        return 'Homework Solutions';
      default:
        return task;
    }
  }

  bool _hasExceededLimits(Map<String, int> limits) {
    for (final entry in limits.entries) {
      final used = _usageStats[entry.key] ?? 0;
      if (used >= entry.value) return true;
    }
    return false;
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}