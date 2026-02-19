import 'package:flutter/material.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:provider/provider.dart';

class TrialDialog {
  static Future<void> showLastDayDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _UpgradeDialog(
        title: 'Trial Ends Tomorrow',
        message:
            'Your 14-day trial expires in 24 hours. Upgrade now to lifetime access for just {price}.',
        remindText: 'Remind Me Tomorrow',
        upgradeText: 'Upgrade for {price}',
      ),
    );
  }

  static Future<void> showGracePeriodDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _UpgradeDialog(
        title: 'Trial Expired',
        message:
            'Your trial has ended. You have 1 grace day to upgrade for {price} and keep your data.',
        remindText: 'Continue for 1 More Day',
        upgradeText: 'Upgrade for {price}',
      ),
    );
  }

  static Future<void> showUpgradeDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _UpgradeDialog(
        title: 'Upgrade to Lifetime Access',
        message:
            'Get lifetime access to Load Intel for just {price} - a one-time purchase.',
        remindText: 'Not Now',
        upgradeText: 'Upgrade for {price}',
        showRestore: true,
      ),
    );
  }
}

class _UpgradeDialog extends StatefulWidget {
  const _UpgradeDialog({
    required this.title,
    required this.message,
    required this.remindText,
    required this.upgradeText,
    this.showRestore = false,
  });

  final String title;
  final String message;
  final String remindText;
  final String upgradeText;
  final bool showRestore;

  @override
  State<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<_UpgradeDialog> {
  bool _isLoading = false;
  bool _isRestoring = false;

  Future<void> _handleUpgrade() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final service = context.read<PurchaseService>();

      if (!service.canPurchase) {
        _showError('Store unavailable right now. Please try again later.');
        return;
      }

      final success = await service.buyLifetimeAccess();

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully upgraded to lifetime access!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError('Purchase failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    if (_isRestoring) return;

    setState(() => _isRestoring = true);

    try {
      final service = context.read<PurchaseService>();

      if (!service.isAvailable) {
        _showError('Store unavailable right now. Please try again later.');
        return;
      }

      await service.restorePurchases();

      if (mounted) {
        Navigator.of(context).pop();
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = context.watch<PurchaseService>();
    final priceLabel = purchaseService.proProduct?.price ?? '\$9.99';
    final message = widget.message.replaceAll('{price}', priceLabel);
    final upgradeText = widget.upgradeText.replaceAll('{price}', priceLabel);

    return AlertDialog(
      title: Text(widget.title),
      content: Text(message),
      actions: [
        if (widget.showRestore)
          TextButton(
            onPressed: _isLoading || _isRestoring ? null : _handleRestore,
            child: _isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Restore Purchases'),
          ),
        TextButton(
          onPressed: _isLoading || _isRestoring
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(widget.remindText),
        ),
        ElevatedButton(
          onPressed: _isLoading || _isRestoring ? null : _handleUpgrade,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(upgradeText),
        ),
      ],
    );
  }
}
