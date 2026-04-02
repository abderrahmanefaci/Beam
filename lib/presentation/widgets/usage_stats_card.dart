import 'package:flutter/material.dart';
import '../../core/theme/beam_theme.dart';
import '../../domain/entities/user_entity.dart';

/// Usage Stats Card Widget
class UsageStatsCard extends StatelessWidget {
  final UserEntity? user;

  const UsageStatsCard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const _UsageStatsShimmer();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BeamTheme.primaryPurple,
            BeamTheme.primaryPurpleDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: BeamTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Usage Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user!.isPremium
                        ? BeamTheme.accentAmber
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user!.isPremium ? 'Premium' : 'Free',
                    style: TextStyle(
                      color: user!.isPremium ? BeamTheme.primaryPurple : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // AI Documents
                Expanded(
                  child: _StatItem(
                    icon: Icons.auto_awesome,
                    label: 'AI Docs',
                    value: '${user!.aiDocsUsed}/3',
                    isUnlimited: user!.isPremium,
                    color: BeamTheme.accentTeal,
                  ),
                ),
                const SizedBox(width: 12),
                // Credits
                Expanded(
                  child: _StatItem(
                    icon: Icons.credit_card,
                    label: 'Credits',
                    value: user!.isPremium ? '${user!.creditsRemaining}' : '—',
                    isUnlimited: false,
                    color: BeamTheme.accentAmber,
                  ),
                ),
                const SizedBox(width: 12),
                // Storage
                Expanded(
                  child: _StatItem(
                    icon: Icons.storage,
                    label: 'Storage',
                    value: '${user!.storageUsedMB.toStringAsFixed(1)} MB',
                    isUnlimited: false,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            // Storage Progress Bar
            if (!user!.isPremium) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (user!.storageUsedPercent / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${user!.storageUsedMB.toStringAsFixed(1)} MB of 100 MB used',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isUnlimited;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isUnlimited,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            isUnlimited ? '∞' : value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer Loading for Usage Stats
class _UsageStatsShimmer extends StatelessWidget {
  const _UsageStatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
