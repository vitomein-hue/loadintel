import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';

// Set to false before Google Play Store production release.
const bool ANDROID_BETA_MODE = true;

class PurchaseService extends ChangeNotifier {
  PurchaseService(this._settingsRepository);

  static const String proLifetimeProductId = 'com.vitomein.loadintel.lifetime';
  static const String freeTrialProductId = 'com.vitomein.loadintel.14daytrial';
  static const String _devOverrideRaw =
      String.fromEnvironment('PRO_OVERRIDE', defaultValue: 'auto');
  static final ProEntitlementOverride _devOverride =
      _parseDevOverride(_devOverrideRaw);

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

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _proProduct;
  ProductDetails? _trialProduct;
  bool _isAvailable = false;
  bool _isProEntitled = false;
  bool _hasTrialReceipt = false;
  DateTime? _trialReceiptDate;
  bool _isInitialized = false;

  bool get isAvailable => _isAvailable;
  bool get isProEntitled => _isProEntitled;
  bool get hasTrialReceipt => _hasTrialReceipt;
  DateTime? get trialReceiptDate => _trialReceiptDate;
  ProductDetails? get proProduct => _proProduct;
  ProductDetails? get trialProduct => _trialProduct;
  bool get canPurchase =>
      _isStoreEnabled && _isAvailable && _proProduct != null;
  bool get canStartTrial => Platform.isAndroid
      ? _isInitialized &&
          !_hasTrialReceipt &&
          (!ANDROID_BETA_MODE
              ? _isAvailable && _trialProduct != null
              : true)
      : _isStoreEnabled &&
          _isInitialized &&
          _isAvailable &&
          _trialProduct != null &&
          !_hasTrialReceipt;
  bool get isInitialized => _isInitialized;

  bool get _isStoreEnabled =>
      Platform.isIOS || (Platform.isAndroid && !ANDROID_BETA_MODE);

  Future<void> init() async {
    debugPrint('🔵 PurchaseService.init() - Starting initialization');
    await refreshEntitlement();
    if (!_isStoreEnabled) {
      debugPrint(
        '🟡 Store disabled for this platform. Using local trial tracking.',
      );
      await _loadTrialReceiptFromLocal();
      _isAvailable = false;
      _isInitialized = true;
      notifyListeners();
      return;
    }
    _isAvailable = await _iap.isAvailable();
    debugPrint('🔵 Store available: $_isAvailable');
    if (!_isAvailable) {
      debugPrint('🔴 Store not available - aborting init');
      _isInitialized = true; // Mark as initialized even if unavailable
      notifyListeners();
      return;
    }

    // Load products
    await _loadProducts();

    // Check for existing trial receipt
    await _checkForTrialReceipt();
    debugPrint('🔵 Trial receipt check: $_hasTrialReceipt');

    _subscription ??= _iap.purchaseStream.listen(_onPurchaseUpdated);
    
    _isInitialized = true;
    notifyListeners();
    debugPrint('🔵 PurchaseService.init() - Completed (initialized: $_isInitialized)');
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

  Future<void> _checkForTrialReceipt() async {
    try {
      // Query past purchases to check for trial receipt
      if (_isStoreEnabled) {
        await _iap.restorePurchases();
      }
      await _loadTrialReceiptFromLocal();
    } catch (e) {
      debugPrint('Error checking for trial receipt: $e');
    }
  }

  Future<void> _loadTrialReceiptFromLocal() async {
    final hasReceipt =
        await _settingsRepository.getBool('has_trial_receipt') ?? false;
    final receiptDateStr =
        await _settingsRepository.getString('trial_receipt_date');

    _hasTrialReceipt = hasReceipt;
    if (receiptDateStr != null && receiptDateStr.isNotEmpty) {
      try {
        _trialReceiptDate = DateTime.parse(receiptDateStr);
      } catch (e) {
        debugPrint('Error parsing trial receipt date: $e');
      }
    }
  }

  Future<bool> _startLocalTrial() async {
    if (_hasTrialReceipt) {
      debugPrint('🔴 Free trial already claimed (local)');
      throw Exception('Free trial already claimed');
    }

    final now = DateTime.now();
    _hasTrialReceipt = true;
    _trialReceiptDate = now;
    await _settingsRepository.setBool('has_trial_receipt', true);
    await _settingsRepository.setString(
      'trial_receipt_date',
      now.toIso8601String(),
    );
    notifyListeners();
    return true;
  }

  /// Initiates purchase of free 14-day trial IAP
  /// Returns true if purchase initiated successfully
  /// Throws exception if user already claimed trial
  Future<bool> startFreeTrial() async {
    debugPrint('🟢 startFreeTrial() called');
    debugPrint('🟢 Product ID: $freeTrialProductId');
    debugPrint('🟢 Initialized: $_isInitialized');
    debugPrint('🟢 Store available: $_isAvailable');
    debugPrint('🟢 Trial product loaded: ${_trialProduct != null}');
    debugPrint('🟢 Has trial receipt: $_hasTrialReceipt');
    
    // Check if service is initialized
    if (!_isInitialized) {
      final error = 'PurchaseService not initialized yet. Please wait.';
      debugPrint('🔴 $error');
      throw Exception(error);
    }

    if (Platform.isAndroid && ANDROID_BETA_MODE) {
      return _startLocalTrial();
    }
    if (!_isStoreEnabled) {
      throw Exception('Free trial is not supported on this platform.');
    }
    
    if (!_isAvailable) {
      final error = 'Store not available. Please check your connection.';
      debugPrint('🔴 $error');
      throw Exception(error);
    }
    
    // If product not loaded, try loading it now
    if (_trialProduct == null) {
      debugPrint('🟡 Trial product not loaded, attempting to load now...');
      await _loadProducts();
      
      // Check again after loading
      if (_trialProduct == null) {
        final error =
            'Trial product ($freeTrialProductId) not found in the store. Please ensure product configuration is set up correctly.';
        debugPrint('🔴 $error');
        throw Exception(error);
      }
      debugPrint('✅ Trial product loaded successfully');
    }
    
    if (_hasTrialReceipt) {
      debugPrint('🔴 Free trial already claimed');
      throw Exception('Free trial already claimed');
    }
    
    try {
      debugPrint('🟢 Creating purchase param for: ${_trialProduct!.id}');
      debugPrint('🟢 Product details: ${_trialProduct!.title} - ${_trialProduct!.price}');
      final param = PurchaseParam(productDetails: _trialProduct!);
      
      debugPrint('🟢 Initiating purchase...');
      final success = await _iap.buyNonConsumable(purchaseParam: param);
      debugPrint('🟢 Purchase initiated: $success');
      return success;
    } catch (e, stackTrace) {
      debugPrint('🔴 Error starting free trial: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Load products from the store
  Future<void> _loadProducts() async {
    debugPrint('🔵 _loadProducts() called');
    if (!_isStoreEnabled) {
      return;
    }
    try {
      final response = await _iap.queryProductDetails({
        proLifetimeProductId,
        freeTrialProductId,
      });
      
      debugPrint('🔵 Products found: ${response.productDetails.length}');
      debugPrint('🔵 Not found IDs: ${response.notFoundIDs}');
      
      for (final product in response.productDetails) {
        debugPrint('🔵 Product: ${product.id} - ${product.title} - ${product.price}');
        if (product.id == proLifetimeProductId) {
          _proProduct = product;
          debugPrint('✅ Lifetime product loaded');
        } else if (product.id == freeTrialProductId) {
          _trialProduct = product;
          debugPrint('✅ Trial product loaded');
        }
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('⚠️ Products not found in store: ${response.notFoundIDs}');
        if (Platform.isIOS) {
          debugPrint('⚠️ Ensure StoreKit Configuration is selected in Xcode scheme');
        }
      }
    } catch (e) {
      debugPrint('🔴 Error loading products: $e');
    }
  }

  /// Checks if user has claimed the free trial
  bool hasClaimedFreeTrial() {
    return _hasTrialReceipt;
  }

  /// Gets the original purchase date of the trial from receipt
  /// Returns null if trial was never claimed
  DateTime? getTrialStartDate() {
    return _trialReceiptDate;
  }

  /// Purchases lifetime access to Load Intel
  /// Renamed from buyPro for clarity
  Future<bool> buyLifetimeAccess() async {
    if (!_isStoreEnabled) {
      debugPrint('Store purchases not supported on this platform');
      return false;
    }
    if (!_isAvailable) {
      debugPrint('Store not available');
      return false;
    }
    
    if (_proProduct == null) {
      debugPrint('Lifetime product not loaded');
      return false;
    }
    
    try {
      final param = PurchaseParam(productDetails: _proProduct!);
      final success = await _iap.buyNonConsumable(purchaseParam: param);
      debugPrint('Lifetime purchase initiated: $success');
      return success;
    } catch (e) {
      debugPrint('Error purchasing lifetime access: $e');
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
    debugPrint('\ud83d\udce6 Purchase stream received ${purchases.length} purchases');
    for (final purchase in purchases) {
      debugPrint('\ud83d\udce6 Purchase: ${purchase.productID} - Status: ${purchase.status}');
      debugPrint('\ud83d\udce6 Transaction date: ${purchase.transactionDate}');
      debugPrint('\ud83d\udce6 Pending complete: ${purchase.pendingCompletePurchase}');
      
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        
        // Handle lifetime purchase
        if (purchase.productID == proLifetimeProductId) {
          debugPrint('\u2705 Lifetime purchase received');
          await _settingsRepository.setProEntitled(true);
          _setProEntitled(true);
        }
        
        // Handle trial purchase (free)
        if (purchase.productID == freeTrialProductId) {
          debugPrint('\u2705 Trial purchase received');
          _hasTrialReceipt = true;
          final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(purchase.transactionDate ?? '0') ?? DateTime.now().millisecondsSinceEpoch,
          );
          _trialReceiptDate = purchaseDate;
          debugPrint('\u2705 Trial receipt date: $purchaseDate');
          
          // Store receipt info
          await _settingsRepository.setBool('has_trial_receipt', true);
          await _settingsRepository.setString(
            'trial_receipt_date',
            purchaseDate.toIso8601String(),
          );
          
          notifyListeners();
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('\u274c Purchase error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.canceled) {
        debugPrint('\u26a0\ufe0f Purchase canceled by user');
      } else if (purchase.status == PurchaseStatus.pending) {
        debugPrint('\u23f3 Purchase pending');
      }
      
      if (purchase.pendingCompletePurchase) {
        debugPrint('\ud83d\udce6 Completing purchase...');
        await _iap.completePurchase(purchase);
        debugPrint('\u2705 Purchase completed');
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
