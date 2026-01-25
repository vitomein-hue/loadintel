import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';

class PurchaseService {
  PurchaseService(this._settingsRepository);

  static const String lifetimeProductId = 'loadintel_lifetime';

  final SettingsRepository _settingsRepository;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _lifetimeProduct;
  bool _isAvailable = false;
  bool _isUnlocked = false;

  bool get isAvailable => _isAvailable;
  bool get isUnlocked => _isUnlocked;
  ProductDetails? get lifetimeProduct => _lifetimeProduct;

  Future<void> init() async {
    _isUnlocked = await _settingsRepository.isLifetimeUnlocked();
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      return;
    }

    final response = await _iap.queryProductDetails({lifetimeProductId});
    if (response.productDetails.isNotEmpty) {
      _lifetimeProduct = response.productDetails.first;
    }

    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdated);
  }

  Future<void> restore() async {
    if (!_isAvailable) {
      return;
    }
    await _iap.restorePurchases();
  }

  Future<void> buyLifetime() async {
    if (!_isAvailable || _lifetimeProduct == null) {
      return;
    }
    final param = PurchaseParam(productDetails: _lifetimeProduct!);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _settingsRepository.setLifetimeUnlocked(true);
        _isUnlocked = true;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }
}
