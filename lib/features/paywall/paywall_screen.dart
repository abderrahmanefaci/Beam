import 'package:flutter/material.dart';
import 'package:beam/core/widgets/app_button.dart';
import 'package:beam/core/widgets/app_card.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  final List<Map<String, dynamic>> _plans = const [
    {
      'name': 'Free',
      'price': '\$0',
      'period': 'forever',
      'features': [
        '5 documents per month',
        'Basic AI analysis',
        'Community support',
      ],
      'isPopular': false,
    },
    {
      'name': 'Pro',
      'price': '\$9.99',
      'period': 'month',
      'features': [
        'Unlimited documents',
        'Advanced AI analysis',
        'Priority support',
        'Cloud storage',
        'Export to PDF',
      ],
      'isPopular': true,
    },
    {
      'name': 'Enterprise',
      'price': '\$29.99',
      'period': 'month',
      'features': [
        'Everything in Pro',
        'Team collaboration',
        'Advanced security',
        'API access',
        'Dedicated support',
      ],
      'isPopular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock the full power of Beam',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get unlimited access to AI-powered document analysis and premium features.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: plan['isPopular']
                          ? BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (plan['isPopular'])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Most Popular',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                plan['name'],
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${plan['price']}/${plan['period']}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (plan['features'] as List<String>).map((feature) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            text: plan['name'] == 'Free' ? 'Current Plan' : 'Subscribe',
                            onPressed: plan['name'] == 'Free'
                                ? null
                                : () {
                                    // TODO: Implement subscription
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Subscription to ${plan['name']} coming soon!')),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'All plans include:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Secure document storage\n• Mobile app access\n• Regular updates'),
            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Implement restore purchase
                },
                child: const Text('Restore Purchase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}