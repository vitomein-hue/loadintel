import 'dart:async';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loadintel/core/utils/fps_stats.dart';
import 'package:loadintel/core/widgets/keyboard_safe_page.dart';
import 'package:loadintel/domain/models/firearm.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/features/build_load/build_load_screen.dart';
import 'package:loadintel/features/down_range/down_range_screen.dart';
import 'package:loadintel/features/range_test/models/range_test_entry.dart';
import 'package:loadintel/services/weather_service.dart';
import 'package:provider/provider.dart';

class RangeTestScreen extends StatefulWidget {
  const RangeTestScreen({super.key, this.initialLoads = const []});

  final List<LoadRecipe> initialLoads;

  @override
  State<RangeTestScreen> createState() => _RangeTestScreenState();
}

class _RangeTestScreenState extends State<RangeTestScreen> {
  final List<RangeTestLoadEntry> _entries = [];
  final Map<String, RangeTestEntryController> _controllers = {};
  final TextEditingController _sessionNotesController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  bool _isLoadingWeather = false;
  bool _weatherExpanded = false;
  bool _weatherCaptured = false;
  bool _weatherSaved = false;
  int _weatherRequestId = 0;

  String? _activeLoadId;
  late Future<List<Firearm>> _firearmsFuture;

  void _safeSetState(String source, VoidCallback update) {
    if (!mounted) {
      debugPrint('⚠️ $source: Skipping setState because widget is unmounted');
      return;
    }
    setState(update);
  }

  void _showWeatherSnack(String message) {
    if (!mounted) {
      debugPrint('⚠️ Weather UI: Cannot show SnackBar, widget unmounted');
      return;
    }
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('⚠️ SnackBar failed (context disposed): $e');
    }
  }

  int _startWeatherRequest(String source) {
    _weatherRequestId += 1;
    final requestId = _weatherRequestId;
    debugPrint('🌦️ $source: Starting request #$requestId');
    _safeSetState('$source start', () {
      _isLoadingWeather = true;
    });
    return requestId;
  }

  bool _isWeatherRequestActive(int requestId, String source) {
    if (!mounted) {
      debugPrint('⚠️ $source: request #$requestId aborted (widget unmounted)');
      return false;
    }
    if (requestId != _weatherRequestId) {
      debugPrint('⚠️ $source: request #$requestId stale; active request is #$_weatherRequestId');
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _firearmsFuture = context.read<FirearmRepository>().listFirearms();
    for (final recipe in widget.initialLoads) {
      _addEntry(recipe);
    }
    if (_entries.isNotEmpty) {
      _activeLoadId = _entries.first.recipe.id;
    }
  }

  @override
  void dispose() {
    _weatherRequestId += 1;
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _sessionNotesController.dispose();
    super.dispose();
  }

  void _addEntry(LoadRecipe recipe) {
    if (_entries.any((entry) => entry.recipe.id == recipe.id)) {
      return;
    }
    final entry = RangeTestLoadEntry(
      recipe: recipe,
      firearmId: recipe.firearmId,
    );
    entry.distanceYds = 100;
    _entries.add(entry);
    final controller = RangeTestEntryController();
    controller.distanceController.text = '100';
    controller.roundsTestedController.text =
        entry.roundsTested?.toString() ?? '';
    _controllers[recipe.id] = controller;
  }

  void _removeEntry(String loadId) {
    _entries.removeWhere((entry) => entry.recipe.id == loadId);
    _controllers.remove(loadId)?.dispose();
    if (_activeLoadId == loadId) {
      _activeLoadId = _entries.isNotEmpty ? _entries.first.recipe.id : null;
    }
    setState(() {});
  }

  Future<void> _confirmRemoveEntry(RangeTestLoadEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove load from test'),
        content: Text('Remove ${entry.recipe.recipeName} from this range test?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _removeEntry(entry.recipe.id);
    }
  }

  RangeTestLoadEntry? _activeEntry() {
    if (_activeLoadId == null) {
      return null;
    }
    return _entries.firstWhere((entry) => entry.recipe.id == _activeLoadId);
  }

  Future<void> _pickLoads() async {
    final repo = context.read<LoadRecipeRepository>();
    final available = await repo.listNewLoads();
    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<List<LoadRecipe>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _LoadPickerSheet(
        existingIds: _entries.map((e) => e.recipe.id).toSet(),
        loads: available,
        onBuildLoads: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BuildLoadScreen()),
          );
        },
      ),
    );

    if (selected == null || selected.isEmpty) {
      return;
    }

    setState(() {
      for (final recipe in selected) {
        _addEntry(recipe);
      }
      _activeLoadId ??= selected.first.id;
    });
  }

  Future<void> _switchMode(RangeTestLoadEntry entry, FpsEntryMode mode) async {
    if (entry.fpsMode == mode) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch entry mode?'),
        content: const Text(
          'Switching entry mode clears current FPS inputs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final controller = _controllers[entry.recipe.id];
    controller?.resetFps();
    setState(() {
      entry.fpsMode = mode;
      entry.avgFps = null;
      entry.sdFps = null;
      entry.esFps = null;
      entry.shots = [];
    });
  }

  void _updateManualValues(RangeTestLoadEntry entry) {
    final controller = _controllers[entry.recipe.id];
    if (controller == null) {
      return;
    }
    setState(() {
      entry.avgFps = double.tryParse(controller.avgController.text.trim());
      entry.sdFps = double.tryParse(controller.sdController.text.trim());
      entry.esFps = double.tryParse(controller.esController.text.trim());
    });
  }

  void _updateShots(RangeTestLoadEntry entry) {
    final controller = _controllers[entry.recipe.id];
    if (controller == null) {
      return;
    }
    final shots = controller.shotControllers
        .map((controller) => double.tryParse(controller.text.trim()))
        .whereType<double>()
        .toList();
    final stats = shots.length >= 2 ? computeFpsStats(shots) : null;
    setState(() {
      entry.shots = shots;
      entry.avgFps = stats?.average;
      entry.sdFps = stats?.sd;
      entry.esFps = stats?.es;
    });
  }

  void _toggleDangerous(RangeTestLoadEntry entry, bool? selected) {
    setState(() {
      entry.isDangerous = selected ?? false;
      if (!entry.isDangerous) {
        entry.dangerReason = null;
        _controllers[entry.recipe.id]?.dangerReasonController.clear();
      }
    });
  }

  void _updateDangerReason(RangeTestLoadEntry entry, String value) {
    entry.dangerReason = value.trim().isEmpty ? null : value;
  }

  Future<void> _captureWeather() async {
    debugPrint('🌦️ Weather UI: Opening weather capture sheet');
    String zipValue = '';
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Retrieve Weather',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop(true);
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Use My Location'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Or enter ZIP code:'),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Zip code',
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: () {
                      final cleaned = zipValue.trim();
                      if (cleaned.length == 5) {
                        Navigator.of(sheetContext).pop(cleaned);
                      }
                    },
                    child: const Text('Done'),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  zipValue = value;
                },
                onSubmitted: (zipCode) {
                  final cleaned = zipCode.trim();
                  if (cleaned.length == 5) {
                    Navigator.of(sheetContext).pop(cleaned);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    if (result is String) {
      await _fetchWeatherFromZip(result);
    } else {
      await _fetchWeatherFromGPS();
    }
  }

  Future<void> _fetchWeatherFromZip(String zipCode) async {
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, aborting ZIP fetch');
      return;
    }

    final cleaned = zipCode.trim();
    if (cleaned.length != 5) {
      debugPrint('⚠️ ZIP: Invalid zip code: $zipCode');
      _showWeatherSnack('Enter a valid ZIP code');
      return;
    }

    final requestId = _startWeatherRequest('ZIP weather fetch');

    try {
      debugPrint('📮 Fetching weather for zip: $cleaned');

      final weather = await _weatherService.fetchWeather(
        zipCode: cleaned,
      );

      if (!mounted) return;
      if (!_isWeatherRequestActive(requestId, 'ZIP weather API call')) return;

      debugPrint('📮 Weather received: ${weather != null ? "Success" : "Null"}');

      if (weather == null) {
        _showWeatherSnack('Weather not available');
        _safeSetState('ZIP unavailable #$requestId', () {
          _isLoadingWeather = false;
        });
        return;
      }

      final activeEntry = _activeEntry();
      if (activeEntry != null) {
        activeEntry.temperatureF = weather.temperatureF;
        activeEntry.humidity = weather.humidity;
        activeEntry.barometricPressureInHg = weather.barometricPressureInHg;
        activeEntry.windDirection = weather.windDirection;
        activeEntry.windSpeedMph = weather.windSpeedMph;
        activeEntry.weatherConditions = weather.weatherConditions;
      }

      _safeSetState('ZIP success #$requestId', () {
        _isLoadingWeather = false;
        _weatherExpanded = true;
        _weatherCaptured = true;
      });
    } catch (e) {
      debugPrint('❌ ZIP error: $e');
      if (mounted) {
        _showWeatherSnack('Weather fetch failed');
        _safeSetState('ZIP error', () {
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _fetchWeatherFromGPS() async {
    debugPrint('🌍 Starting GPS weather fetch...');
    
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, aborting GPS fetch');
      return;
    }
    
    final requestId = _startWeatherRequest('GPS weather fetch');

    try {
      debugPrint('🌍 Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      debugPrint('🌍 Location services enabled: $serviceEnabled');
      if (!_isWeatherRequestActive(requestId, 'GPS weather services check')) return;
      if (!serviceEnabled) {
        _showWeatherSnack('Location services are disabled');
        _safeSetState('GPS weather services disabled #$requestId', () {
          _isLoadingWeather = false;
        });
        return;
      }

      debugPrint('🌍 Checking location permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      debugPrint('🌍 Current permission status: $permission');
      if (!_isWeatherRequestActive(requestId, 'GPS permission check')) return;
      
      if (permission == LocationPermission.denied) {
        debugPrint('🌍 Permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        debugPrint('🌍 Permission after request: $permission');
        if (!_isWeatherRequestActive(requestId, 'GPS permission request')) return;
        if (permission == LocationPermission.denied) {
          _showWeatherSnack('Location permission denied');
          _safeSetState('GPS permission denied #$requestId', () {
            _isLoadingWeather = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showWeatherSnack('Location permission permanently denied');
        _safeSetState('GPS permission denied forever #$requestId', () {
          _isLoadingWeather = false;
        });
        return;
      }

      debugPrint('🌍 Getting current GPS position...');
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
        if (!mounted) return;
      } on TimeoutException catch (e, st) {
        debugPrint('⚠️ GPS: Timed out waiting for current position: $e');
        debugPrint('⚠️ GPS: Timeout stack trace: $st');
      } catch (e, st) {
        debugPrint('⚠️ GPS: Current position lookup failed: $e');
        debugPrint('⚠️ GPS: Current position error stack trace: $st');
      }

      position ??= await Geolocator.getLastKnownPosition();
      if (!mounted) return;
      if (position == null) {
        _showWeatherSnack('Could not determine current location');
        _safeSetState('GPS no position #$requestId', () {
          _isLoadingWeather = false;
        });
        return;
      }

      debugPrint('🌍 Position acquired: ${position.latitude}, ${position.longitude}');
      if (!_isWeatherRequestActive(requestId, 'GPS position lookup')) return;
      
      debugPrint('🌍 Fetching weather for location...');
      final weather = await _weatherService.fetchWeather(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
      );
      if (!mounted) return;
      if (!_isWeatherRequestActive(requestId, 'GPS weather API call')) return;
      debugPrint('🌍 Weather data received: ${weather != null ? "Success" : "Null"}');

      if (weather == null) {
        debugPrint('⚠️ GPS: Weather data is null');
        _showWeatherSnack('Weather currently not available');
        _safeSetState('GPS weather unavailable #$requestId', () {
          _isLoadingWeather = false;
          _weatherExpanded = true;
          _weatherCaptured = true;
        });
        return;
      }

      debugPrint('✅ GPS: Weather data received successfully');
      final activeEntry = _activeEntry();
      if (activeEntry != null) {
        debugPrint('✅ GPS: Applying weather to active entry');
        activeEntry.temperatureF = weather.temperatureF;
        activeEntry.humidity = weather.humidity;
        activeEntry.barometricPressureInHg = weather.barometricPressureInHg;
        activeEntry.windDirection = weather.windDirection;
        activeEntry.windSpeedMph = weather.windSpeedMph;
        activeEntry.weatherConditions = weather.weatherConditions;
      } else {
        debugPrint('⚠️ GPS: No active entry found');
      }
      _safeSetState('GPS weather success #$requestId', () {
        _isLoadingWeather = false;
        _weatherExpanded = true;
        _weatherCaptured = true;
      });
      debugPrint('✅ GPS: Weather fetch complete');
    } catch (e, st) {
      debugPrint('❌ GPS: Error occurred: $e');
      debugPrint('❌ GPS: Stack trace: $st');
      if (!_isWeatherRequestActive(requestId, 'GPS weather error handler')) return;
      _showWeatherSnack('Failed to get location/weather: $e');
      _safeSetState('GPS weather error #$requestId', () {
        _isLoadingWeather = false;
      });
    }
  }


  void _saveWeather() {
    if (!mounted) {
      debugPrint('⚠️ Save weather: widget unmounted');
      return;
    }
    final activeEntry = _activeEntry();
    if (activeEntry == null) return;

    // Apply active entry's weather to all loads
    for (final entry in _entries) {
      entry.temperatureF = activeEntry.temperatureF;
      entry.humidity = activeEntry.humidity;
      entry.barometricPressureInHg = activeEntry.barometricPressureInHg;
      entry.windDirection = activeEntry.windDirection;
      entry.windSpeedMph = activeEntry.windSpeedMph;
      entry.weatherConditions = activeEntry.weatherConditions;
    }

    _safeSetState('Save weather', () {
      _weatherExpanded = false;
      _weatherSaved = true;
    });

    _showWeatherSnack('Weather saved to all loads');
  }

  bool _isBenchComplete(RangeTestLoadEntry entry) {
    if (entry.firearmId == null || entry.firearmId!.isEmpty) {
      return false;
    }
    if (entry.distanceYds == null) {
      return false;
    }
    if (entry.fpsMode == FpsEntryMode.manual) {
      return entry.avgFps != null;
    }
    return entry.shots.isNotEmpty;
  }

  bool get _allBenchComplete =>
      _entries.isNotEmpty && _entries.every(_isBenchComplete);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Range Test'),
      ),
      resizeToAvoidBottomInset: true,
      body: KeyboardSafePage(
        child: FutureBuilder<List<Firearm>>(
          future: _firearmsFuture,
          builder: (context, snapshot) {
            final firearms = snapshot.data ?? [];
            final activeEntry = _activeEntry();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selected Loads',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickLoads,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Loads'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: _entries.isEmpty
                      ? const Center(child: Text('No loads selected.'))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final isActive = entry.recipe.id == _activeLoadId;
                            return InputChip(
                              label: Text(
                                '${entry.recipe.recipeName} (${entry.recipe.powderChargeGr.toStringAsFixed(1)} gr)',
                              ),
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                              selected: isActive,
                              onSelected: (_) {
                                setState(() {
                                  _activeLoadId = entry.recipe.id;
                                });
                              },
                              onDeleted: () => _confirmRemoveEntry(entry),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                if (_entries.isNotEmpty && !_weatherSaved) ...[
                  ElevatedButton.icon(
                    onPressed: _isLoadingWeather ? null : _captureWeather,
                    icon: _isLoadingWeather
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud),
                    label: Text(_isLoadingWeather
                        ? 'Loading Weather...'
                        : 'Retrieve Weather'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (activeEntry != null &&
                    _weatherCaptured && !_weatherSaved)
                  Card(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        title: const Text('Weather Conditions'),
                        initiallyExpanded: _weatherExpanded,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _WeatherFields(
                                  entry: activeEntry,
                                  onChanged: () => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _saveWeather,
                                  child: const Text('Save for this range session'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (activeEntry != null &&
                    _weatherCaptured && !_weatherSaved)
                  const SizedBox(height: 16),
                if (activeEntry == null)
                  const Text('Add a load to begin bench data entry.'),
                if (activeEntry != null)
                  _BenchEntryCard(
                    entry: activeEntry,
                    firearms: firearms,
                    controller: _controllers[activeEntry.recipe.id]!,
                    onFirearmChanged: (value) {
                      setState(() {
                        activeEntry.firearmId = value;
                      });
                    },
                    onDistanceChanged: (value) {
                      setState(() {
                        activeEntry.distanceYds = value;
                      });
                    },
                    onRoundsTestedChanged: (value) {
                      setState(() {
                        activeEntry.roundsTested = value;
                      });
                    },
                    onModeChanged: (mode) => _switchMode(activeEntry, mode),
                    onManualChanged: () => _updateManualValues(activeEntry),
                    onShotsChanged: () => _updateShots(activeEntry),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Notes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _sessionNotesController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 4,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'Shared notes for this range test',
                          ),
                          onSubmitted: (_) =>
                              FocusScope.of(context).unfocus(),
                        ),
                        if (activeEntry != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: activeEntry.isDangerous,
                                onChanged: (value) =>
                                    _toggleDangerous(activeEntry, value),
                              ),
                              const Expanded(child: Text('Label load as dangerous')),
                            ],
                          ),
                          if (activeEntry.isDangerous) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _controllers[activeEntry.recipe.id]!
                                  .dangerReasonController,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Why is it dangerous?',
                                hintText: 'Pressure signs, heavy bolt lift, etc.',
                              ),
                              onChanged: (value) =>
                                  _updateDangerReason(activeEntry, value),
                              onSubmitted: (_) =>
                                  FocusScope.of(context).unfocus(),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                if (activeEntry != null && _weatherSaved) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        title: const Text('Weather Conditions (Saved)'),
                        initiallyExpanded: false,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _WeatherFields(
                              entry: activeEntry,
                              onChanged: () => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: KeyboardAwareBottomBar(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _allBenchComplete
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DownRangeScreen(
                          entries: _entries,
                          sessionNotes: _sessionNotesController.text.trim(),
                        ),
                      ),
                    );
                  }
                : null,
            child: const Text('Down Range'),
          ),
        ),
      ),
    );
  }
}

class _BenchEntryCard extends StatelessWidget {
  const _BenchEntryCard({
    required this.entry,
    required this.firearms,
    required this.controller,
    required this.onFirearmChanged,
    required this.onDistanceChanged,
    required this.onRoundsTestedChanged,
    required this.onModeChanged,
    required this.onManualChanged,
    required this.onShotsChanged,
  });

  final RangeTestLoadEntry entry;
  final List<Firearm> firearms;
  final RangeTestEntryController controller;
  final ValueChanged<String?> onFirearmChanged;
  final ValueChanged<double?> onDistanceChanged;
  final ValueChanged<int?> onRoundsTestedChanged;
  final ValueChanged<FpsEntryMode> onModeChanged;
  final VoidCallback onManualChanged;
  final VoidCallback onShotsChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.recipe.recipeName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: firearms.any((firearm) => firearm.id == entry.firearmId)
                  ? entry.firearmId
                  : null,
              decoration: const InputDecoration(labelText: 'Firearm'),
              items: firearms
                  .map(
                    (firearm) => DropdownMenuItem<String?>(
                      value: firearm.id,
                      child: Text(firearm.name),
                    ),
                  )
                  .toList(),
              onChanged: onFirearmChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Distance (yds)'),
              onChanged: (value) => onDistanceChanged(double.tryParse(value.trim())),
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.roundsTestedController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '# of rounds tested',
                helperText: 'How many rounds were fired in this test',
              ),
              onChanged: (value) => onRoundsTestedChanged(
                value.trim().isEmpty ? null : int.tryParse(value.trim()),
              ),
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: entry.fpsMode == FpsEntryMode.manual
                  ? OutlinedButton(
                      onPressed: () => onModeChanged(FpsEntryMode.shots),
                      child: const Text('Use Shot-by-shot'),
                    )
                  : OutlinedButton(
                      onPressed: () => onModeChanged(FpsEntryMode.manual),
                      child: const Text('Use Manual Summary'),
                    ),
            ),
            const SizedBox(height: 12),
            if (entry.fpsMode == FpsEntryMode.manual)
              Column(
                children: [
                  TextField(
                    controller: controller.avgController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'AVG FPS *'),
                    onChanged: (_) => onManualChanged(),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.sdController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'SD FPS'),
                    onChanged: (_) => onManualChanged(),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller.esController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'ES FPS'),
                    onChanged: (_) => onManualChanged(),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ],
              ),
            if (entry.fpsMode == FpsEntryMode.shots)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...controller.shotControllers.asMap().entries.map((entryPair) {
                    final index = entryPair.key;
                    final shotController = entryPair.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: shotController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Shot ${index + 1}'),
                        onChanged: (_) {
                          if (index == controller.shotControllers.length - 1 &&
                              shotController.text.trim().isNotEmpty) {
                            controller.addShotController();
                          }
                          onShotsChanged();
                        },
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                    );
                  }),
                  if (entry.shots.length >= 2)
                    Text(
                      'AVG ${entry.avgFps?.toStringAsFixed(1) ?? '-'} '
                      '| SD ${entry.sdFps?.toStringAsFixed(1) ?? '-'} '
                      '| ES ${entry.esFps?.toStringAsFixed(1) ?? '-'}',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadPickerSheet extends StatefulWidget {
  const _LoadPickerSheet({
    required this.loads,
    required this.existingIds,
    required this.onBuildLoads,
  });

  final List<LoadRecipe> loads;
  final Set<String> existingIds;
  final VoidCallback onBuildLoads;

  @override
  State<_LoadPickerSheet> createState() => _LoadPickerSheetState();
}

class _LoadPickerSheetState extends State<_LoadPickerSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final available = widget.loads
        .where((recipe) => !widget.existingIds.contains(recipe.id))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add Loads',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onBuildLoads();
                },
                child: const Text('Build Loads'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No additional new loads available.'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final recipe = available[index];
                  return CheckboxListTile(
                    value: _selectedIds.contains(recipe.id),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedIds.add(recipe.id);
                        } else {
                          _selectedIds.remove(recipe.id);
                        }
                      });
                    },
                    title: Text(recipe.recipeName),
                    subtitle: Text(recipe.cartridge),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          final selected = available
                              .where((recipe) => _selectedIds.contains(recipe.id))
                              .toList();
                          Navigator.of(context).pop(selected);
                        },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}

class RangeTestEntryController {
  RangeTestEntryController()
      : distanceController = TextEditingController(),
        roundsTestedController = TextEditingController(),
        avgController = TextEditingController(),
        sdController = TextEditingController(),
        esController = TextEditingController(),
        shotControllers = [TextEditingController()],
        dangerReasonController = TextEditingController();

  final TextEditingController distanceController;
  final TextEditingController roundsTestedController;
  final TextEditingController avgController;
  final TextEditingController sdController;
  final TextEditingController esController;
  final List<TextEditingController> shotControllers;
  final TextEditingController dangerReasonController;

  void addShotController() {
    shotControllers.add(TextEditingController());
  }

  void resetFps() {
    avgController.clear();
    sdController.clear();
    esController.clear();
    for (final controller in shotControllers) {
      controller.dispose();
    }
    shotControllers
      ..clear()
      ..add(TextEditingController());
  }

  void dispose() {
    distanceController.dispose();
    roundsTestedController.dispose();
    avgController.dispose();
    sdController.dispose();
    esController.dispose();
    dangerReasonController.dispose();
    for (final controller in shotControllers) {
      controller.dispose();
    }
  }
}

class _WeatherFields extends StatefulWidget {
  const _WeatherFields({
    required this.entry,
    required this.onChanged,
  });

  final RangeTestLoadEntry entry;
  final VoidCallback onChanged;

  @override
  State<_WeatherFields> createState() => _WeatherFieldsState();
}

class _WeatherFieldsState extends State<_WeatherFields> {
  late final TextEditingController _tempController;
  late final TextEditingController _humidityController;
  late final TextEditingController _pressureController;
  late final TextEditingController _windDirController;
  late final TextEditingController _windSpeedController;
  late final TextEditingController _conditionsController;

  String _displayNumber(double? value, int decimals) {
    if (value == null || value.isNaN) {
      return 'N/A';
    }
    return value.toStringAsFixed(decimals);
  }

  String _displayText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'N/A';
    }
    return trimmed;
  }

  double? _parseNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toUpperCase() == 'N/A') {
      return null;
    }
    return double.tryParse(trimmed);
  }

  String? _parseText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toUpperCase() == 'N/A') {
      return null;
    }
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _tempController = TextEditingController(
      text: _displayNumber(widget.entry.temperatureF, 1),
    );
    _humidityController = TextEditingController(
      text: _displayNumber(widget.entry.humidity, 0),
    );
    _pressureController = TextEditingController(
      text: _displayNumber(widget.entry.barometricPressureInHg, 2),
    );
    _windDirController = TextEditingController(
      text: _displayText(widget.entry.windDirection),
    );
    _windSpeedController = TextEditingController(
      text: _displayNumber(widget.entry.windSpeedMph, 1),
    );
    _conditionsController = TextEditingController(
      text: _displayText(widget.entry.weatherConditions),
    );
  }

  @override
  void dispose() {
    _tempController.dispose();
    _humidityController.dispose();
    _pressureController.dispose();
    _windDirController.dispose();
    _windSpeedController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _tempController,
          decoration: const InputDecoration(
            labelText: 'Temperature (°F)',
            hintText: '70',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            widget.entry.temperatureF = _parseNumber(value);
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _humidityController,
          decoration: const InputDecoration(
            labelText: 'Humidity (%)',
            hintText: '50',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            widget.entry.humidity = _parseNumber(value);
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pressureController,
          decoration: const InputDecoration(
            labelText: 'Barometric Pressure (inHg)',
            hintText: '29.92',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            widget.entry.barometricPressureInHg = _parseNumber(value);
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _windDirController,
          decoration: const InputDecoration(
            labelText: 'Wind Direction',
            hintText: 'N, NE, E, etc.',
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            widget.entry.windDirection = _parseText(value);
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _windSpeedController,
          decoration: const InputDecoration(
            labelText: 'Wind Speed (mph)',
            hintText: '5',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            widget.entry.windSpeedMph = _parseNumber(value);
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _conditionsController,
          decoration: const InputDecoration(
            labelText: 'Weather Conditions',
            hintText: 'Sunny, Cloudy, etc.',
          ),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) {
            widget.entry.weatherConditions = _parseText(value);
            widget.onChanged();
          },
        ),
      ],
    );
  }
}
