import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/beam_theme.dart';
import '../../core/constants/beam_constants.dart';
import '../../domain/entities/entities.dart';
import '../../providers/providers.dart';
import '../widgets/recent_documents_list.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/usage_stats_card.dart';
import '../widgets/premium_banner.dart';
import '../widgets/empty_state.dart';
import 'document_viewer_screen.dart';
import 'library_screen.dart';

/// Home Screen - Recent documents, quick actions, usage stats
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Preload recent documents
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(recentDocumentsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beam',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: BeamTheme.primaryPurple,
                  ),
            ),
            Text(
              'Document Intelligence',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BeamTheme.textSecondaryLight,
                  ),
            ),
          ],
        ),
        actions: [
          // Notifications button
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildContent(user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildContent(UserEntity? user) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recentDocumentsProvider);
        ref.invalidate(currentUserProvider);
      },
      color: BeamTheme.primaryPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            _buildWelcomeSection(user),
            const SizedBox(height: 20),

            // Usage Stats Card
            UsageStatsCard(user: user),
            const SizedBox(height: 20),

            // Premium Banner (only for free users)
            if (user?.isPremium == false) ...[
              const PremiumBanner(),
              const SizedBox(height: 20),
            ],

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BeamTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            const QuickActionsGrid(),
            const SizedBox(height: 24),

            // Recent Documents
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BeamTheme.textPrimaryLight,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LibraryScreen()),
                    );
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const RecentDocumentsList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(UserEntity? user) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    final displayName = user?.displayName ?? user?.email.split('@').first ?? 'there';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $displayName!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'What would you like to do today?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: BeamTheme.errorRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(currentUserProvider);
              ref.invalidate(recentDocumentsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.document_scanner, 'Scan', false),
            _buildFloatingActionButton(),
            _buildNavItem(Icons.folder, 'Library', false),
            _buildNavItem(Icons.grid_view, 'Tools', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () {
        // Navigation handled by main navigation screen
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? BeamTheme.primaryPurple : BeamTheme.textSecondaryLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? BeamTheme.primaryPurple : BeamTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: () {
        // Quick scan action
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: BeamTheme.primaryPurple,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: BeamTheme.primaryPurple.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
