import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';

// Default false to keep billing enabled in production. Override in beta builds.
const bool androidBetaMode = bool.fromEnvironment(
  'BETA_MODE',
  defaultValue: false,
);

class PurchaseService extends ChangeNotifier {
  PurchaseService(this._settingsRepository);

  static const String proLifetimeProductId = 'com.vitomein.loadintel.lifetime';
  static const String _devOverrideRaw = String.fromEnvironment(
    'PRO_OVERRIDE',
    defaultValue: 'auto',
  );
  static final ProEntitlementOverride _devOverride = _parseDevOverride(
    _devOverrideRaw,
  );

  static ProEntitlementOverride _parseDevOverride(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'forceon':
      case 'force_on':
      case 'force-on':
      case 'on':
      case 'true':
      case '1':
        return ProEntitlementOverride.forceOn;
      case 'forceoff':
      case 'force_off':
      case 'force-off':
      case 'off':
      case 'false':
      case '0':
        return ProEntitlementOverride.forceOff;
      default:
        return ProEntitlementOverride.auto;
    }
  }

  final SettingsRepository _settingsRepository;
  final InAppPurchase _iap = InAppPurchase.instance;
  final Completer<void> _initCompleter = Completer<void>();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _proProduct;
  bool _isAvailable = false;
  bool _isProEntitled = false;
  bool _isInitialized = false;

  bool get isAvailable => _isAvailable;
  bool get isProEntitled => _isProEntitled;
  ProductDetails? get proProduct => _proProduct;
  bool get canPurchase =>
      _isStoreEnabled && _isAvailable && _proProduct != null;
  bool get isInitialized => _isInitialized;
  Future<void> get initializationDone => _initCompleter.future;

  bool get _isStoreEnabled =>
      Platform.isIOS || (Platform.isAndroid && !androidBetaMode);

  Future<void> init() async {
    try {
      if (kDebugMode) {
        debugPrint('🔵 PurchaseService.init() - Starting initialization');
      }
      await refreshEntitlement();
      if (!_isStoreEnabled) {
        if (kDebugMode) {
          debugPrint(
            '🟡 Store disabled for this platform. Using local trial tracking.',
          );
        }
        _isAvailable = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }
      _isAvailable = await _iap.isAvailable();
      if (kDebugMode) {
        debugPrint('🔵 Store available: $_isAvailable');
      }
      if (!_isAvailable) {
        if (kDebugMode) {
          debugPrint('🔴 Store not available - aborting init');
        }
        _isInitialized = true; // Mark as initialized even if unavailable
        notifyListeners();
        return;
      }

      // Load products
      await _loadProducts();

      _subscription ??= _iap.purchaseStream.listen(_onPurchaseUpdated);

      _isInitialized = true;
      notifyListeners();
      if (kDebugMode) {
        debugPrint(
          '🔵 PurchaseService.init() - Completed (initialized: $_isInitialized)',
        );
      }
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
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
    if (!_isAvailable || !_isStoreEnabled) {
      return;
    }
    await _iap.restorePurchases();
  }


  /// Load products from the store
  Future<void> _loadProducts() async {
    if (kDebugMode) {
      debugPrint('🔵 _loadProducts() called');
    }
    if (!_isStoreEnabled) {
      return;
    }
    try {
      final response = await _iap.queryProductDetails({proLifetimeProductId});

      if (kDebugMode) {
        debugPrint('🔵 Products found: ${response.productDetails.length}');
        debugPrint('🔵 Not found IDs: ${response.notFoundIDs}');
      }

      for (final product in response.productDetails) {
        if (kDebugMode) {
          debugPrint(
            '🔵 Product: ${product.id} - ${product.title} - ${product.price}',
          );
        }
        if (product.id == proLifetimeProductId) {
          _proProduct = product;
          if (kDebugMode) {
            debugPrint('✅ Lifetime product loaded');
          }
        }
      }

      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Products not found in store: ${response.notFoundIDs}');
        }
        if (Platform.isIOS) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ Ensure StoreKit Configuration is selected in Xcode scheme',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔴 Error loading products: $e');
      }
    }
  }


  /// Purchases lifetime access to Load Intel
  /// Renamed from buyPro for clarity
  Future<bool> buyLifetimeAccess() async {
    if (!_isStoreEnabled) {
      if (kDebugMode) {
        debugPrint('Store purchases not supported on this platform');
      }
      return false;
    }
    if (!_isAvailable) {
      if (kDebugMode) {
        debugPrint('Store not available');
      }
      return false;
    }

    if (_proProduct == null) {
      if (kDebugMode) {
        debugPrint('Lifetime product not loaded');
      }
      return false;
    }

    try {
      final param = PurchaseParam(productDetails: _proProduct!);
      final success = await _iap.buyNonConsumable(purchaseParam: param);
      if (kDebugMode) {
        debugPrint('Lifetime purchase initiated: $success');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error purchasing lifetime access: $e');
      }
      rethrow;
    }
  }

  /// Checks if user has purchased lifetime access
  /// Renamed from isProEntitled for clarity
  bool hasLifetimeAccess() {
    return _isProEntitled;
  }

  /// Legacy method - kept for backward compatibility
  @Deprecated('Use buyLifetimeAccess() instead')
  Future<void> buyPro() async {
    await buyLifetimeAccess();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    if (!_isStoreEnabled) {
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '\ud83d\udce6 Purchase stream received ${purchases.length} purchases',
      );
    }
    for (final purchase in purchases) {
      if (kDebugMode) {
        debugPrint(
          '\ud83d\udce6 Purchase: ${purchase.productID} - Status: ${purchase.status}',
        );
        debugPrint(
          '\ud83d\udce6 Transaction date: ${purchase.transactionDate}',
        );
        debugPrint(
          '\ud83d\udce6 Pending complete: ${purchase.pendingCompletePurchase}',
        );
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Handle lifetime purchase
        if (purchase.productID == proLifetimeProductId) {
          if (kDebugMode) {
            debugPrint('\u2705 Lifetime purchase received');
          }
          await _settingsRepository.setProEntitled(true);
          _setProEntitled(true);
        }

      } else if (purchase.status == PurchaseStatus.error) {
        if (kDebugMode) {
          debugPrint('\u274c Purchase error: ${purchase.error}');
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (kDebugMode) {
          debugPrint('\u26a0\ufe0f Purchase canceled by user');
        }
      } else if (purchase.status == PurchaseStatus.pending) {
        if (kDebugMode) {
          debugPrint('\u23f3 Purchase pending');
        }
      }

      if (purchase.pendingCompletePurchase) {
        if (kDebugMode) {
          debugPrint('\ud83d\udce6 Completing purchase...');
        }
        await _iap.completePurchase(purchase);
        if (kDebugMode) {
          debugPrint('\u2705 Purchase completed');
        }
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
