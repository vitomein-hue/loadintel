import 'package:flutter/material.dart';
import 'package:loadintel/services/trial_service.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:provider/provider.dart';

class TrialBanner extends StatefulWidget {
  const TrialBanner({
    super.key,
    required this.trialService,
  });

  final TrialService trialService;

  @override
  State<TrialBanner> createState() => _TrialBannerState();
}

class _TrialBannerState extends State<TrialBanner> {
  bool _isLoading = false;

  Future<void> _handleUpgrade() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final purchaseService = context.read<PurchaseService>();
      
      if (!purchaseService.canPurchase) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store unavailable. Please try again later.'),
            ),
          );
        }
        return;
      }

      final success = await purchaseService.buyLifetimeAccess();
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully upgraded to lifetime access!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.trialService.shouldShowBanner()) {
      return const SizedBox.shrink();
    }

    final daysRemaining = widget.trialService.getDaysRemaining();
    final message = daysRemaining == 1
        ? '1 day remaining in trial'
        : '$daysRemaining days remaining in trial';

    return Material(
      color: Colors.blue.shade100,
      child: InkWell(
        onTap: _isLoading ? null : _handleUpgrade,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (_isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.shade800,
                  ),
                )
              else
                Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, 
                color: Colors.blue.shade800, 
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
