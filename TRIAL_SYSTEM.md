# Trial System Implementation

## Overview
Load Intel now uses a 14-day time-based trial system with a 1-day grace period instead of the previous load-count-based limit.

## Trial Phases

### Phase 1: Not Started (TrialPhase.notStarted)
- Trial hasn't been activated yet
- Auto-starts on first app launch
- No restrictions

### Phase 2: Silent Period (Days 0-9) (TrialPhase.silent)
- Full app access
- No UI indicators
- Users enjoy the app without interruption

### Phase 3: Reminder Period (Days 10-12) (TrialPhase.reminder)
- Blue banner appears at top of Load History and Build Load screens
- Banner shows days remaining
- Tapping banner opens upgrade dialog
- Full app functionality maintained

### Phase 4: Last Day (Day 13) (TrialPhase.lastDay)
- Dialog appears on app launch warning trial ends tomorrow
- Users can continue using the app
- Upgrade button prominent

### Phase 5: Grace Period (Day 14) (TrialPhase.gracePeriod)
- Dialog appears on app launch with urgent message
- Last chance to upgrade with full access
- All features still available

### Phase 6: Expired (Day 15+) (TrialPhase.expired)
- Full-screen paywall blocks app access
- Only "Upgrade to Pro" and "Restore Purchase" buttons available
- No app functionality accessible until upgrade

## User Experience

### Pro Users
- Trial system completely bypassed
- No banners, dialogs, or restrictions
- Full lifetime access

### Free Users
1. **Days 1-10**: Enjoy the app fully
2. **Days 11-13**: See gentle reminder banner
3. **Day 14**: Receive last day warning dialog
4. **Day 15**: Receive grace period warning dialog
5. **Day 16+**: Hard paywall blocks all access

## Technical Implementation

### Files Created
- `lib/services/trial_service.dart` - Core trial logic and state management
- `lib/features/trial/trial_banner.dart` - Blue reminder banner (days 11-13)
- `lib/features/trial/trial_dialog.dart` - Warning dialogs (days 14-15)
- `lib/features/trial/trial_paywall.dart` - Full-screen paywall (day 16+)

### Files Modified
- `lib/app.dart` - Added TrialService provider and _TrialAwareHome wrapper
- `lib/features/load_history/load_history_screen.dart` - Added trial banner
- `lib/features/build_load/build_load_screen.dart` - Added trial banner
- `lib/features/backup_export/backup_export_screen.dart` - Added trial status card

### Files Deleted
- `lib/features/paywall/paywall.dart` - Old 6-load limit dialog
- `lib/core/utils/free_tier.dart` - Old 25-load limit logic

### Storage
Trial start date stored in settings table with key `trial_start_date`
- Format: ISO 8601 string
- Persists across app restarts
- Can be manually set in debug mode via Settings screen

## Testing

### Debug Controls (Settings Screen)
In debug mode, the Settings screen shows trial status with manual date controls:
- **Day 10 Button**: Set trial to day 10 (silent phase)
- **Day 13 Button**: Set trial to day 13 (last reminder day)
- **Day 14 Button**: Set trial to day 14 (last day dialog)
- **Day 15 Button**: Set trial to day 15 (grace period dialog)
- **Day 20 Button**: Set trial to day 20 (expired paywall)
- **Reset Button**: Clear trial date to start fresh

### Testing Workflow
1. Run app in debug mode
2. Navigate to Settings (gear icon on home screen)
3. See "Trial Status" card at top
4. Use debug buttons to test different phases
5. Navigate to Load History or Build Load to see banners
6. Restart app to see dialogs appear on days 14-15
7. Test hard paywall on day 16+

## Integration with Existing IAP
- Uses existing PurchaseService infrastructure
- Checks `purchaseService.isPro` before showing trial UI
- "Upgrade to Pro" buttons open existing purchase flow
- "Restore Purchase" uses existing restoration logic
- Trial bypassed completely for Pro users

## Auto-Start Behavior
- Trial automatically starts when `_TrialAwareHome` initializes
- Only starts if:
  - User is not Pro (`!purchaseService.isPro`)
  - Trial hasn't started yet (`!trialService.hasTrialStarted()`)
- Happens once per fresh install
- Date persists in settings database

## Calendar Reference
Example for trial starting on January 1:
- **Days 1-10** (Jan 1-10): Silent period
- **Days 11-13** (Jan 11-13): Banner reminders
- **Day 14** (Jan 14): Last day dialog
- **Day 15** (Jan 15): Grace period dialog
- **Day 16+** (Jan 16+): Hard paywall

Note: Day count is zero-indexed in code but presented as 1-indexed to users.
- `getDaysElapsed() == 0` = Day 1 for user
- `getDaysElapsed() == 13` = Day 14 for user (last day)
- `getDaysElapsed() == 14` = Day 15 for user (grace period)
- `getDaysElapsed() == 15` = Day 16 for user (expired)
