import 'package:flutter/material.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:provider/provider.dart';

class Paywall {
  static Future<void> show(BuildContext context) async {
    final service = context.read<PurchaseService>();
    final rootContext = context;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Load Intel Pro'),
        content: const Text(
          'Free users can save up to 6 loads. Upgrade to Pro for unlimited loads.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!service.isAvailable) {
                _showStoreUnavailable(rootContext);
                return;
              }
              await service.restorePurchases();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Restore Purchases'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!service.canPurchase) {
                _showStoreUnavailable(rootContext);
                return;
              }
              await service.buyPro();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  static void _showStoreUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Store unavailable right now. Please try again later.'),
      ),
    );
  }
}
