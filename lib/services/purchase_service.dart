import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';

class PurchaseService extends ChangeNotifier {
  PurchaseService(this._settingsRepository);

  static const String proLifetimeProductId = 'loadintel_pro_lifetime';
  static const ProEntitlementOverride _devOverride = ProEntitlementOverride.forceOn;

  final SettingsRepository _settingsRepository;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _proProduct;
  bool _isAvailable = false;
  bool _isProEntitled = false;

  bool get isAvailable => _isAvailable;
  bool get isProEntitled => _isProEntitled;
  ProductDetails? get proProduct => _proProduct;
  bool get canPurchase => _isAvailable && _proProduct != null;

  Future<void> init() async {
    await refreshEntitlement();
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      notifyListeners();
      return;
    }

    final response = await _iap.queryProductDetails({proLifetimeProductId});
    if (response.productDetails.isNotEmpty) {
      _proProduct = response.productDetails.first;
    }

    _subscription ??= _iap.purchaseStream.listen(_onPurchaseUpdated);
    notifyListeners();
  }

  Future<void> refreshEntitlement() async {
    if (kDebugMode) {
      if (_devOverride != ProEntitlementOverride.auto) {
        _setProEntitled(_devOverride == ProEntitlementOverride.forceOn);
        return;
      }
      final override = await _settingsRepository.getProEntitlementOverride();
      if (override == ProEntitlementOverride.forceOn) {
        _setProEntitled(true);
        return;
      }
      if (override == ProEntitlementOverride.forceOff) {
        _setProEntitled(false);
        return;
      }
    }
    var pro = await _settingsRepository.isProEntitled();
    if (!pro) {
      final legacy = await _settingsRepository.isLifetimeUnlocked();
      if (legacy) {
        await _settingsRepository.setProEntitled(true);
        pro = true;
      }
    }
    _setProEntitled(pro);
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      return;
    }
    await _iap.restorePurchases();
  }

  Future<void> buyPro() async {
    if (!_isAvailable || _proProduct == null) {
      return;
    }
    final param = PurchaseParam(productDetails: _proProduct!);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _settingsRepository.setProEntitled(true);
        _setProEntitled(true);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _setProEntitled(bool value) {
    if (_isProEntitled == value) {
      return;
    }
    _isProEntitled = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
