import 'package:flutter/material.dart';
import 'package:loadintel/services/trial_service.dart';
import 'package:provider/provider.dart';

class TrialIntroScreen extends StatelessWidget {
  const TrialIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trialService = context.watch<TrialService>();
    final canStartTrial = !trialService.hasTrialStarted();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.assessment_outlined,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to Load Intel',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Track your reloading data, test loads at the range, and find the perfect ammunition for your firearms.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      const _FeatureTile(
                        icon: Icons.science_outlined,
                        title: 'Build Load Recipes',
                        subtitle: 'Document every component and measurement',
                      ),
                      const SizedBox(height: 16),
                      const _FeatureTile(
                        icon: Icons.speed,
                        title: 'Range Testing',
                        subtitle:
                            'Track velocity, accuracy, and weather conditions',
                      ),
                      const SizedBox(height: 16),
                      const _FeatureTile(
                        icon: Icons.analytics_outlined,
                        title: 'Data Analysis',
                        subtitle: 'Compare loads and optimize performance',
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: canStartTrial
                            ? () async {
                                try {
                                  await trialService.startTrialAutomatically();
                                  if (context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Start Free 14-Day Trial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Skip for now'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No credit card required • Cancel anytime',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
