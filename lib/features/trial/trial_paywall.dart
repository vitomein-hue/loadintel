import 'package:flutter/material.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TrialPaywall extends StatefulWidget {
  const TrialPaywall({super.key});

  @override
  State<TrialPaywall> createState() => _TrialPaywallState();
}

class _TrialPaywallState extends State<TrialPaywall> {
  bool _isUpgrading = false;
  bool _isRestoring = false;

  Future<void> _handleUpgrade() async {
    if (_isUpgrading || _isRestoring) return;

    setState(() => _isUpgrading = true);

    try {
      final service = context.read<PurchaseService>();
      
      if (!service.canPurchase) {
        _showError('Store unavailable. Please check your connection.');
        return;
      }

      final success = await service.buyLifetimeAccess();
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully upgraded to lifetime access!'),
            backgroundColor: Colors.green,
          ),
        );
        // The app will automatically refresh and show main content
      }
    } catch (e) {
      _showError('Purchase failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUpgrading = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    if (_isUpgrading || _isRestoring) return;

    setState(() => _isRestoring = true);

    try {
      final service = context.read<PurchaseService>();
      
      if (!service.isAvailable) {
        _showError('Store unavailable. Please check your connection.');
        return;
      }

      await service.restorePurchases();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Restore failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PurchaseService>();
    final priceLabel = service.proProduct?.price ?? '\$9.99';
    final canInteract = !_isUpgrading && !_isRestoring;

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
                Icons.lock_outline,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                'Trial Ended',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your trial and grace period have expired. Upgrade to continue using Load Intel and keep all your data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: canInteract && service.canPurchase
                    ? _handleUpgrade
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUpgrading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Upgrade to Lifetime Access - $priceLabel',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: canInteract && service.isAvailable
                    ? _handleRestore
                    : null,
                child: _isRestoring
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Restore Purchases'),
              ),
              if (!service.isAvailable) ...[
                const SizedBox(height: 16),
                const Text(
                  'Store unavailable. Please check your connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 32),
              const Text(
                'By purchasing, you agree to our',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _launchUrl('https://vitomein-hue.github.io/loadintel-privacy/'),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '|',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  InkWell(
                    onTap: () => _launchUrl('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                    child: const Text(
                      'Terms of Use',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
