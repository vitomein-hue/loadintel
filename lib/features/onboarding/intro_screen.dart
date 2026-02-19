import 'package:flutter/material.dart';
import 'package:loadintel/core/theme/app_colors.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:loadintel/services/trial_service.dart';
import 'package:provider/provider.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _waitForInitialization();
  }

  Future<void> _waitForInitialization() async {
    debugPrint('📱 Waiting for PurchaseService initialization...');
    
    // Wait a moment for PurchaseService to initialize
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final purchaseService = context.read<PurchaseService>();
    
    // Wait up to 5 seconds for initialization
    int attempts = 0;
    while (!purchaseService.isInitialized && attempts < 10) {
      debugPrint('📱 Waiting for initialization... attempt ${attempts + 1}');
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
      
      debugPrint('📱 PurchaseService initialized: ${purchaseService.isInitialized}');
      debugPrint('📱 Trial product loaded: ${purchaseService.trialProduct != null}');
      
      if (!purchaseService.isInitialized) {
        debugPrint('⚠️ PurchaseService failed to initialize after 5 seconds');
      }
    }
  }

  Future<void> _startTrial() async {
    debugPrint('📱 IntroScreen._startTrial() called');
    setState(() {
      _isLoading = true;
    });

    try {
      final trialService = context.read<TrialService>();
      final purchaseService = context.read<PurchaseService>();

      debugPrint('📱 PurchaseService initialized: ${purchaseService.isInitialized}');
      debugPrint('📱 PurchaseService available: ${purchaseService.isAvailable}');
      debugPrint('📱 Trial product available: ${purchaseService.trialProduct != null}');
      debugPrint('📱 Trial already claimed: ${purchaseService.hasClaimedFreeTrial()}');

      // Check if trial already claimed
      if (purchaseService.hasClaimedFreeTrial()) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          await _showAlreadyClaimedDialog();
        }
        return;
      }

      // Attempt to start trial
      debugPrint('📱 Calling trialService.startTrial()');
      final success = await trialService.startTrial();
      debugPrint('📱 Trial start result: $success');

      if (!mounted) return;

      if (success) {
        // Mark intro as completed and navigate to main app
        debugPrint('✅ Trial started successfully');
        Navigator.of(context).pop(true);
      } else {
        debugPrint('❌ Trial start returned false');
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Purchase was not initiated. Please ensure StoreKit is configured and try again.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _startTrial: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      // Check if error is about already claimed trial
      if (e.toString().contains('already claimed')) {
        await _showAlreadyClaimedDialog();
      } else {
        // Show the actual error message for debugging
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        debugPrint('❌ Showing error dialog: $errorMsg');
        _showErrorDialog(errorMsg);
      }
    }
  }

  Future<void> _showAlreadyClaimedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trial Already Claimed'),
        content: const Text(
          'The free trial has already been claimed on this Apple ID.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = context.watch<PurchaseService>();
    final priceLabel = purchaseService.proProduct?.price ?? '\$9.99';

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              const SizedBox(height: 40),
              // Top Section - App Name and Tagline
              Column(
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Load Intel',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional load development tracking',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              // Middle Section - Feature Highlights
              Column(
                children: const [
                  _FeatureTile(
                    icon: Icons.bar_chart,
                    text: 'Track unlimited loads and components',
                  ),
                  SizedBox(height: 20),
                  _FeatureTile(
                    icon: Icons.assignment,
                    text: 'Record range test data with weather',
                  ),
                  SizedBox(height: 20),
                  _FeatureTile(
                    icon: Icons.analytics_outlined,
                    text: 'Analyze performance and trends',
                  ),
                  SizedBox(height: 20),
                  _FeatureTile(
                    icon: Icons.shield,
                    text: 'Never lose your data',
                  ),
                ],
              ),
              
              // Bottom Section - CTA Button
              Column(
                children: [
                  ElevatedButton(
                    onPressed: (_isLoading || _isInitializing) ? null : _startTrial,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: (_isLoading || _isInitializing)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Start 14-Day Free Trial',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isInitializing 
                        ? 'Loading store...'
                        : 'After 14 days, unlock lifetime access for just $priceLabel',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
