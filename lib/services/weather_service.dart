import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  const WeatherData({
    required this.temperatureF,
    required this.humidity,
    required this.barometricPressureInHg,
    required this.windDirection,
    required this.windSpeedMph,
    required this.weatherConditions,
  });

  final double? temperatureF;
  final double? humidity;
  final double? barometricPressureInHg;
  final String? windDirection;
  final double? windSpeedMph;
  final String? weatherConditions;

  bool get isValid {
    return temperatureF != null ||
        humidity != null ||
        barometricPressureInHg != null ||
        windSpeedMph != null ||
        (windDirection != null && windDirection!.isNotEmpty) ||
        (weatherConditions != null && weatherConditions!.isNotEmpty);
  }
}

class WeatherService {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Map<String, String> _headers = {
    'User-Agent': 'LoadIntel/1.0',
    'Accept': 'application/json, application/geo+json',
  };

  Future<WeatherData?> fetchWeather({
    String? latitude,
    String? longitude,
    String? zipCode,
  }) async {
    debugPrint(
      'WeatherService: fetchWeather called with '
      'zip=$zipCode, latitude=$latitude, longitude=$longitude',
    );

    final hasZip = zipCode != null && zipCode.trim().isNotEmpty;
    final hasCoords =
        latitude != null && longitude != null && latitude.trim().isNotEmpty && longitude.trim().isNotEmpty;
    if (!hasZip && !hasCoords) {
      debugPrint('WeatherService: No location provided');
      return null;
    }

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        debugPrint('WeatherService: Attempt ${attempt + 1}/$maxRetries');
        final weather = await _fetchWeatherOnce(
          latitude: latitude,
          longitude: longitude,
          zipCode: zipCode,
        );
        if (weather != null && weather.isValid) {
          debugPrint('WeatherService: Valid weather data received on attempt ${attempt + 1}');
          return weather;
        }
        debugPrint('WeatherService: Attempt ${attempt + 1} failed validation');
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      } catch (e, st) {
        debugPrint('WeatherService: Attempt ${attempt + 1} error: $e');
        debugPrint('WeatherService: Attempt ${attempt + 1} stack trace: $st');
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      }
    }
    debugPrint('WeatherService: All $maxRetries attempts failed');
    return null;
  }

  Future<WeatherData?> _fetchWeatherOnce({
    String? latitude,
    String? longitude,
    String? zipCode,
  }) async {
    final latLng = await _resolveLatLng(
      latitude: latitude,
      longitude: longitude,
      zipCode: zipCode,
    );
    if (latLng == null) {
      debugPrint('WeatherService: Unable to resolve location to lat/lon');
      return null;
    }

    final gridPoint = await _fetchGridPoint(latLng);
    if (gridPoint == null) {
      debugPrint('WeatherService: Failed to resolve NOAA grid point');
      return null;
    }

    final stationUrl = await _fetchStationUrl(gridPoint);
    if (stationUrl == null) {
      debugPrint('WeatherService: Failed to get NOAA station URL');
      return null;
    }

    final observation = await _fetchLatestObservation(stationUrl);
    if (observation == null) {
      debugPrint('WeatherService: Failed to get latest observation');
      return null;
    }

    return _parseObservation(observation);
  }

  Future<_LatLng?> _resolveLatLng({
    String? latitude,
    String? longitude,
    String? zipCode,
  }) async {
    if (latitude != null && longitude != null) {
      final lat = double.tryParse(latitude);
      final lon = double.tryParse(longitude);
      if (lat == null || lon == null) {
        debugPrint('WeatherService: Invalid lat/lon values: $latitude, $longitude');
        return null;
      }
      debugPrint('WeatherService: Using coordinates: $lat,$lon');
      return _LatLng(lat: lat, lon: lon);
    }

    if (zipCode == null || zipCode.trim().isEmpty) {
      debugPrint('WeatherService: No location provided');
      return null;
    }

    final trimmedZip = zipCode.trim();
    debugPrint('WeatherService: Resolving zip code: $trimmedZip');
    return _geocodeZip(trimmedZip);
  }

  Future<_LatLng?> _geocodeZip(String zipCode) async {
    final zippo = await _geocodeZipWithZippopotam(zipCode);
    if (zippo != null) {
      return zippo;
    }
    return _geocodeZipWithNominatim(zipCode);
  }

  Future<_LatLng?> _geocodeZipWithZippopotam(String zipCode) async {
    final url = Uri.parse('https://api.zippopotam.us/us/$zipCode');
    debugPrint('WeatherService: Zippopotam URL: $url');

    final response = await http.get(url, headers: _headers).timeout(
      requestTimeout,
      onTimeout: () => http.Response('Timeout', 408),
    );

    debugPrint('WeatherService: Zippopotam response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      debugPrint('WeatherService: Zippopotam bad status code: ${response.statusCode}');
      _logBodySnippet('Zippopotam', response.body);
      return null;
    }
    if (response.body.trim().isEmpty) {
      debugPrint('WeatherService: Zippopotam empty response body');
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final places = data['places'] as List?;
    if (places == null || places.isEmpty) {
      debugPrint('WeatherService: Zippopotam places empty');
      return null;
    }

    final first = places.first as Map<String, dynamic>;
    final lat = double.tryParse(first['latitude']?.toString() ?? '');
    final lon = double.tryParse(first['longitude']?.toString() ?? '');
    if (lat == null || lon == null) {
      debugPrint('WeatherService: Zippopotam parse failed for zip $zipCode');
      return null;
    }

    debugPrint('WeatherService: Zippopotam resolved $zipCode -> $lat,$lon');
    return _LatLng(lat: lat, lon: lon);
  }

  Future<_LatLng?> _geocodeZipWithNominatim(String zipCode) async {
    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'postalcode': zipCode,
      'country': 'US',
      'format': 'json',
      'limit': '1',
    });
    debugPrint('WeatherService: Geocoding URL: $url');

    final response = await http.get(url, headers: _headers).timeout(
      requestTimeout,
      onTimeout: () => http.Response('Timeout', 408),
    );

    debugPrint('WeatherService: Geocode response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      debugPrint('WeatherService: Geocode bad status code: ${response.statusCode}');
      _logBodySnippet('Geocode', response.body);
      return null;
    }
    if (response.body.trim().isEmpty) {
      debugPrint('WeatherService: Geocode empty response body');
      return null;
    }

    final data = json.decode(response.body);
    if (data is! List || data.isEmpty) {
      debugPrint('WeatherService: Geocode result empty');
      return null;
    }

    final first = data.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) {
      debugPrint('WeatherService: Geocode parse failed for zip $zipCode');
      return null;
    }

    debugPrint('WeatherService: Geocode resolved $zipCode -> $lat,$lon');
    return _LatLng(lat: lat, lon: lon);
  }

  Future<_GridPoint?> _fetchGridPoint(_LatLng latLng) async {
    final url = Uri.parse('https://api.weather.gov/points/${latLng.lat},${latLng.lon}');
    debugPrint('WeatherService: NOAA points URL: $url');
    final response = await http.get(url, headers: _headers).timeout(
      requestTimeout,
      onTimeout: () => http.Response('Timeout', 408),
    );

    debugPrint('WeatherService: NOAA points status: ${response.statusCode}');
    if (response.statusCode != 200) {
      debugPrint('WeatherService: NOAA points bad status code: ${response.statusCode}');
      _logBodySnippet('NOAA points', response.body);
      return null;
    }
    if (response.body.trim().isEmpty) {
      debugPrint('WeatherService: NOAA points empty response body');
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final properties = data['properties'] as Map<String, dynamic>?;
    if (properties == null) {
      debugPrint('WeatherService: NOAA points missing properties');
      return null;
    }

    final gridId = properties['gridId']?.toString();
    final gridX = (properties['gridX'] as num?)?.toInt();
    final gridY = (properties['gridY'] as num?)?.toInt();
    if (gridId == null || gridX == null || gridY == null) {
      debugPrint('WeatherService: NOAA points missing grid info');
      return null;
    }

    debugPrint('WeatherService: NOAA grid: $gridId $gridX,$gridY');
    return _GridPoint(gridId: gridId, gridX: gridX, gridY: gridY);
  }

  Future<String?> _fetchStationUrl(_GridPoint gridPoint) async {
    final url = Uri.parse(
      'https://api.weather.gov/gridpoints/${gridPoint.gridId}/${gridPoint.gridX},${gridPoint.gridY}/stations',
    );
    debugPrint('WeatherService: NOAA stations URL: $url');
    final response = await http.get(url, headers: _headers).timeout(
      requestTimeout,
      onTimeout: () => http.Response('Timeout', 408),
    );

    debugPrint('WeatherService: NOAA stations status: ${response.statusCode}');
    if (response.statusCode != 200) {
      debugPrint('WeatherService: NOAA stations bad status code: ${response.statusCode}');
      _logBodySnippet('NOAA stations', response.body);
      return null;
    }
    if (response.body.trim().isEmpty) {
      debugPrint('WeatherService: NOAA stations empty response body');
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List?;
    if (features == null || features.isEmpty) {
      debugPrint('WeatherService: NOAA stations list empty');
      return null;
    }

    final first = features.first as Map<String, dynamic>;
    final stationUrl = first['id']?.toString();
    if (stationUrl != null && stationUrl.isNotEmpty) {
      debugPrint('WeatherService: NOAA station URL: $stationUrl');
      return stationUrl;
    }

    final properties = first['properties'] as Map<String, dynamic>?;
    final stationId = properties?['stationIdentifier']?.toString();
    if (stationId == null || stationId.isEmpty) {
      debugPrint('WeatherService: NOAA station identifier missing');
      return null;
    }

    final fallbackUrl = 'https://api.weather.gov/stations/$stationId';
    debugPrint('WeatherService: NOAA station fallback URL: $fallbackUrl');
    return fallbackUrl;
  }

  Future<Map<String, dynamic>?> _fetchLatestObservation(String stationUrl) async {
    final normalized = stationUrl.endsWith('/observations/latest')
        ? stationUrl
        : '${stationUrl.replaceAll(RegExp(r'/+$'), '')}/observations/latest';
    final url = Uri.parse(normalized);
    debugPrint('WeatherService: NOAA observation URL: $url');
    final response = await http.get(url, headers: _headers).timeout(
      requestTimeout,
      onTimeout: () => http.Response('Timeout', 408),
    );

    debugPrint('WeatherService: NOAA observation status: ${response.statusCode}');
    if (response.statusCode != 200) {
      debugPrint('WeatherService: NOAA observation bad status code: ${response.statusCode}');
      _logBodySnippet('NOAA observation', response.body);
      return null;
    }
    if (response.body.trim().isEmpty) {
      debugPrint('WeatherService: NOAA observation empty response body');
      return null;
    }
    if (kDebugMode) {
      final bodySnippet = response.body.length > 2000
          ? response.body.substring(0, 2000)
          : response.body;
      debugPrint('WeatherService: NOAA observation body (truncated): $bodySnippet');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final properties = data['properties'] as Map<String, dynamic>?;
    if (properties == null) {
      debugPrint('WeatherService: NOAA observation missing properties');
      return null;
    }
    return properties;
  }

  WeatherData? _parseObservation(Map<String, dynamic> properties) {
    try {
      final tempRaw = properties['temperature']?['value'];
      final tempValue = _parseDoubleOrNull(tempRaw, label: 'temperature');
      final tempUnit = properties['temperature']?['unitCode']?.toString();
      final tempF = _convertTemperatureToF(tempValue, tempUnit);

      final humidity = _parseDoubleOrNull(
        properties['relativeHumidity']?['value'],
        label: 'relativeHumidity',
      );

      final pressureValue = _parseDoubleOrNull(
        properties['barometricPressure']?['value'],
        label: 'barometricPressure',
      );
      final pressureUnit = properties['barometricPressure']?['unitCode']?.toString();
      final pressureInHg = _convertPressureToInHg(pressureValue, pressureUnit);

      final windSpeedValue = _parseDoubleOrNull(
        properties['windSpeed']?['value'],
        label: 'windSpeed',
      );
      final windSpeedUnit = properties['windSpeed']?['unitCode']?.toString();
      final windSpeedMph = _convertWindSpeedToMph(windSpeedValue, windSpeedUnit);

      final windDirectionDegrees = _parseDoubleOrNull(
        properties['windDirection']?['value'],
        label: 'windDirection',
      );
      final windDir = windDirectionDegrees == null
          ? 'N/A'
          : _degreesToCardinal(windDirectionDegrees);

      final conditions = properties['textDescription']?.toString().trim();
      final safeConditions = (conditions == null || conditions.isEmpty)
          ? null
          : conditions;

      final hasAny = tempF != null ||
          humidity != null ||
          pressureInHg != null ||
          windSpeedMph != null ||
          windDir != null ||
          safeConditions != null;
      if (!hasAny) {
        debugPrint('WeatherService: NOAA observation missing all fields');
        return null;
      }

      final isValid = tempF != null ||
          humidity != null ||
          pressureInHg != null ||
          windSpeedMph != null ||
          windDir != null ||
          safeConditions != null;
      debugPrint(
        'WeatherService: Parsed NOAA data - Temp: $tempF°F, Humidity: $humidity%, '
        'Pressure: $pressureInHg inHg, Wind: $windSpeedMph mph $windDir, '
        'Conditions: ${safeConditions ?? "N/A"}, isValid=$isValid',
      );

      return WeatherData(
        temperatureF: tempF,
        humidity: humidity,
        barometricPressureInHg: pressureInHg,
        windDirection: windDir,
        windSpeedMph: windSpeedMph,
        weatherConditions: safeConditions,
      );
    } catch (e, st) {
      debugPrint('Weather parsing error: $e');
      debugPrint('Weather parsing stack trace: $st');
      return null;
    }
  }

  void _logBodySnippet(String label, String body) {
    final bodySnippet = body.length > 200 ? body.substring(0, 200) : body;
    debugPrint('WeatherService: $label response body snippet: $bodySnippet');
  }

  double? _parseDoubleOrNull(dynamic value, {required String label}) {
    if (value == null) {
      debugPrint('WeatherService: $label missing');
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      debugPrint('WeatherService: $label invalid');
      return null;
    }
    return parsed;
  }

  double? _convertTemperatureToF(double? value, String? unitCode) {
    if (value == null) {
      return null;
    }
    if (unitCode != null && unitCode.contains('degF')) {
      return value;
    }
    return (value * 9 / 5) + 32;
  }

  double? _convertPressureToInHg(double? value, String? unitCode) {
    if (value == null) {
      return null;
    }
    if (unitCode != null && unitCode.contains('Pa')) {
      return value / 3386.39;
    }
    if (unitCode != null && unitCode.contains('hPa')) {
      return (value * 100) / 3386.39;
    }
    return value / 3386.39;
  }

  double? _convertWindSpeedToMph(double? value, String? unitCode) {
    if (value == null) {
      return null;
    }
    if (unitCode == null || unitCode.contains('m_s-1')) {
      return value * 2.23694;
    }
    if (unitCode.contains('km_h-1')) {
      return value * 0.621371;
    }
    if (unitCode.contains('kn')) {
      return value * 1.15078;
    }
    if (unitCode.contains('mi_h-1')) {
      return value;
    }
    return value * 2.23694;
  }

  String _degreesToCardinal(double degrees) {
    final normalized = ((degrees % 360) + 360) % 360;
    const directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final index = ((normalized + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}

class _LatLng {
  const _LatLng({required this.lat, required this.lon});

  final double lat;
  final double lon;
}

class _GridPoint {
  const _GridPoint({
    required this.gridId,
    required this.gridX,
    required this.gridY,
  });

  final String gridId;
  final int gridX;
  final int gridY;
}
