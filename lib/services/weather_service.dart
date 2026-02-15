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

  final double temperatureF;
  final double humidity;
  final double barometricPressureInHg;
  final String windDirection;
  final double windSpeedMph;
  final String weatherConditions;

  bool get isValid {
    return !temperatureF.isNaN && !humidity.isNaN && !windSpeedMph.isNaN;
  }
}

class WeatherService {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  Future<WeatherData?> fetchWeather({
    String? latitude,
    String? longitude,
    String? zipCode,
  }) async {
    debugPrint(
      '🌤️ WeatherService: fetchWeather called with '
      'zip=$zipCode, latitude=$latitude, longitude=$longitude',
    );
    String location;
    if (zipCode != null && zipCode.isNotEmpty) {
      location = zipCode;
      debugPrint('🌤️ WeatherService: Using zip code: $location');
    } else if (latitude != null && longitude != null) {
      location = '$latitude,$longitude';
      debugPrint('🌤️ WeatherService: Using coordinates: $location');
    } else {
      debugPrint('❌ WeatherService: No location provided');
      return null;
    }

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        debugPrint('🌤️ WeatherService: Attempt ${attempt + 1}/$maxRetries for location: $location');
        final weather = await _fetchWeatherOnce(location);
        if (weather != null && weather.isValid) {
          debugPrint('✅ WeatherService: Valid weather data received on attempt ${attempt + 1}');
          return weather;
        }
        debugPrint('⚠️ Weather attempt ${attempt + 1} failed validation');
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      } catch (e, st) {
        debugPrint('❌ Weather attempt ${attempt + 1} error: $e');
        debugPrint('❌ Weather attempt ${attempt + 1} stack trace: $st');
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      }
    }
    debugPrint('❌ WeatherService: All $maxRetries attempts failed for location: $location');
    return null;
  }

  Future<WeatherData?> _fetchWeatherOnce(String location) async {
    debugPrint('🌤️ WeatherService: Fetching from wttr.in for: $location');
    final encodedLocation = Uri.encodeComponent(location);
    final url = Uri.parse('https://wttr.in/$encodedLocation?format=j1');
    debugPrint('🌤️ WeatherService: URL: $url');
    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () => http.Response('Timeout', 408),
    );

    debugPrint('🌤️ WeatherService: Response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      debugPrint('❌ WeatherService: Bad status code: ${response.statusCode}');
      final bodySnippet = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
      debugPrint('❌ WeatherService: Response body snippet: $bodySnippet');
      return null;
    }

    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      debugPrint('🌤️ WeatherService: JSON parsed successfully');
      final current = data['current_condition'] as List;
      if (current.isEmpty) {
        debugPrint('❌ WeatherService: current_condition is empty');
        return null;
      }

      final currentWeather = current[0] as Map<String, dynamic>;
      
      // Parse temperature (Fahrenheit)
      final tempF = double.tryParse(currentWeather['temp_F']?.toString() ?? '0') ?? 0.0;
      debugPrint('🌤️ WeatherService: Temperature: $tempF°F');
      
      // Parse humidity
      final humidity = double.tryParse(currentWeather['humidity']?.toString() ?? '0') ?? 0.0;
      
      // Parse barometric pressure (convert from millibars to inHg)
      final pressureMb = double.tryParse(currentWeather['pressure']?.toString() ?? '0') ?? 0.0;
      final pressureInHg = pressureMb * 0.02953; // Convert mb to inHg
      
      // Parse wind direction (16-point compass)
      final windDir = currentWeather['winddir16Point']?.toString() ?? 'N';
      
      // Parse wind speed (mph)
      final windSpeedMph = double.tryParse(currentWeather['windspeedMiles']?.toString() ?? '0') ?? 0.0;
      
      // Parse weather conditions
      final weatherDesc = currentWeather['weatherDesc'] as List?;
      final conditions = weatherDesc != null && weatherDesc.isNotEmpty
          ? (weatherDesc[0] as Map<String, dynamic>)['value']?.toString() ?? 'Unknown'
          : 'Unknown';

      debugPrint('🌤️ WeatherService: Parsed data - Temp: $tempF°F, Humidity: $humidity%, Pressure: $pressureInHg inHg, Wind: $windSpeedMph mph $windDir, Conditions: $conditions');

      return WeatherData(
        temperatureF: tempF,
        humidity: humidity,
        barometricPressureInHg: pressureInHg,
        windDirection: windDir,
        windSpeedMph: windSpeedMph,
        weatherConditions: conditions,
      );
    } catch (e, st) {
      debugPrint('❌ Weather parsing error: $e');
      debugPrint('❌ Weather parsing stack trace: $st');
      debugPrint('❌ Response body snippet: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      return null;
    }
  }
}
