import 'package:flutter/foundation.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/services/purchase_service.dart';

enum TrialPhase {
  notStarted,
  silent, // Days 1-10
  reminder, // Days 11-13
  lastDay, // Day 14
  gracePeriod, // Day 15
  expired, // Day 16+
}

class TrialService extends ChangeNotifier {
  TrialService(this._settingsRepository, this._purchaseService);

  final SettingsRepository _settingsRepository;
  final PurchaseService _purchaseService;

  static const String _trialReceiptDateKey = 'trial_receipt_date';
  static const String _debugTrialStartDateKey = 'trial_start_date';
  static const int trialDays = 14;
  static const int graceDays = 1;
  static const int totalDays = trialDays + graceDays;

  DateTime? _trialReceiptDate;
  DateTime? _debugTrialStartDate; // Only used in debug mode
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Get trial start date - uses locally stored date or debug override
  DateTime? get trialStartDate {
    // In debug mode, allow manual override
    if (kDebugMode && _debugTrialStartDate != null) {
      return _debugTrialStartDate;
    }
    // Otherwise use locally stored trial date
    return _trialReceiptDate;
  }

  Future<void> init() async {
    final receiptDateString = await _settingsRepository.getString(
      _trialReceiptDateKey,
    );
    if (receiptDateString != null && receiptDateString.isNotEmpty) {
      try {
        _trialReceiptDate = DateTime.parse(receiptDateString);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing trial receipt date: $e');
        }
        _trialReceiptDate = null;
      }
    }
    // In debug mode, load debug override date if set
    if (kDebugMode) {
      final dateString = await _settingsRepository.getString(
        _debugTrialStartDateKey,
      );
      if (dateString != null && dateString.isNotEmpty) {
        try {
          _debugTrialStartDate = DateTime.parse(dateString);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing debug trial start date: $e');
          }
          _debugTrialStartDate = null;
        }
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Starts the trial locally on first app use.
  Future<void> startTrialAutomatically() async {
    if (!_isInitialized) {
      await init();
    }
    if (trialStartDate != null) {
      return;
    }
    final now = DateTime.now();
    _trialReceiptDate = now;
    await _settingsRepository.setString(
      _trialReceiptDateKey,
      now.toIso8601String(),
    );
    notifyListeners();
  }

  /// Debug only - manually set trial date for testing
  Future<void> setTrialStartDate(DateTime date) async {
    if (!kDebugMode) return;

    _debugTrialStartDate = date;
    await _settingsRepository.setString(
      _debugTrialStartDateKey,
      date.toIso8601String(),
    );
    notifyListeners();
  }

  /// Debug only - clear debug trial date
  Future<void> clearTrialStartDate() async {
    if (!kDebugMode) return;

    _debugTrialStartDate = null;
    await _settingsRepository.setString(_debugTrialStartDateKey, '');
    notifyListeners();
  }

  /// Debug only - kept for backward compatibility
  @Deprecated('Use clearTrialStartDate() instead')
  Future<void> resetTrial() async {
    await clearTrialStartDate();
  }

  bool hasTrialStarted() {
    return trialStartDate != null;
  }

  int getDaysElapsed() {
    final startDate = trialStartDate;
    if (startDate == null) return 0;
    final now = DateTime.now();
    final difference = now.difference(startDate);
    return difference.inDays;
  }

  int getDaysRemaining() {
    // If user has lifetime access, return -1 (unlimited)
    if (_purchaseService.hasLifetimeAccess()) {
      return -1;
    }

    final startDate = trialStartDate;

    // Trial not started yet
    if (startDate == null) {
      return trialDays;
    }

    final elapsed = getDaysElapsed();
    return trialDays - elapsed;
  }

  bool isTrialActive() {
    // Lifetime users always have access
    if (_purchaseService.hasLifetimeAccess()) {
      return true;
    }

    final daysRemaining = getDaysRemaining();
    return daysRemaining > 0;
  }

  bool isInGracePeriod() {
    // Lifetime users don't need grace period
    if (_purchaseService.hasLifetimeAccess()) {
      return false;
    }

    final startDate = trialStartDate;
    if (startDate == null) return false;

    final elapsed = getDaysElapsed();
    return elapsed >= trialDays && elapsed < totalDays;
  }

  bool isTrialExpired() {
    // Lifetime users never expire
    if (_purchaseService.hasLifetimeAccess()) {
      return false;
    }

    final startDate = trialStartDate;
    if (startDate == null) return false;

    final elapsed = getDaysElapsed();
    return elapsed >= totalDays;
  }

  TrialPhase getCurrentPhase() {
    // Lifetime users are never in trial
    if (_purchaseService.hasLifetimeAccess()) {
      return TrialPhase.notStarted;
    }

    final startDate = trialStartDate;
    if (startDate == null) {
      return TrialPhase.notStarted;
    }

    final elapsed = getDaysElapsed();

    if (elapsed < 10) {
      return TrialPhase.silent; // Days 0-9
    } else if (elapsed < 13) {
      return TrialPhase.reminder; // Days 10-12
    } else if (elapsed < 14) {
      return TrialPhase.lastDay; // Day 13
    } else if (elapsed < 15) {
      return TrialPhase.gracePeriod; // Day 14
    } else {
      return TrialPhase.expired; // Day 15+
    }
  }

  String getTrialStatusMessage() {
    if (_purchaseService.hasLifetimeAccess()) {
      return 'Lifetime access';
    }

    final startDate = trialStartDate;
    if (startDate == null) {
      return 'Trial not started';
    }

    final phase = getCurrentPhase();
    final daysRemaining = getDaysRemaining();

    switch (phase) {
      case TrialPhase.notStarted:
        return 'Trial not started';
      case TrialPhase.silent:
        return '$daysRemaining days remaining in trial';
      case TrialPhase.reminder:
        return '$daysRemaining days remaining in trial';
      case TrialPhase.lastDay:
        return 'Trial ends tomorrow';
      case TrialPhase.gracePeriod:
        return 'Trial expired - 1 grace day remaining';
      case TrialPhase.expired:
        return 'Trial and grace period expired';
    }
  }

  bool shouldShowBanner() {
    if (_purchaseService.hasLifetimeAccess()) {
      return false;
    }
    final phase = getCurrentPhase();
    return phase == TrialPhase.reminder;
  }

  bool shouldShowLastDayDialog() {
    if (_purchaseService.hasLifetimeAccess()) {
      return false;
    }
    final phase = getCurrentPhase();
    return phase == TrialPhase.lastDay;
  }

  bool shouldShowGracePeriodDialog() {
    if (_purchaseService.hasLifetimeAccess()) {
      return false;
    }
    final phase = getCurrentPhase();
    return phase == TrialPhase.gracePeriod;
  }

  bool shouldShowHardBlock() {
    if (_purchaseService.hasLifetimeAccess()) {
      return false;
    }
    final phase = getCurrentPhase();
    return phase == TrialPhase.expired;
  }
}
