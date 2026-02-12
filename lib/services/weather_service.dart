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
    return temperatureF != 0.0 && weatherConditions.isNotEmpty;
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
    String location;
    if (zipCode != null && zipCode.isNotEmpty) {
      location = zipCode;
    } else if (latitude != null && longitude != null) {
      location = '$latitude,$longitude';
    } else {
      return null;
    }

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final weather = await _fetchWeatherOnce(location);
        if (weather != null && weather.isValid) {
          return weather;
        }
        debugPrint('Weather attempt ${attempt + 1} failed validation');
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        debugPrint('Weather attempt ${attempt + 1} error: $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      }
    }
    return null;
  }

  Future<WeatherData?> _fetchWeatherOnce(String location) async {
    final url = Uri.parse('https://wttr.in/$location?format=j1');
    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () => http.Response('Timeout', 408),
    );

    if (response.statusCode != 200) {
      return null;
    }

    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final current = data['current_condition'] as List;
      if (current.isEmpty) {
        return null;
      }

      final currentWeather = current[0] as Map<String, dynamic>;
      
      // Parse temperature (Fahrenheit)
      final tempF = double.tryParse(currentWeather['temp_F']?.toString() ?? '0') ?? 0.0;
      
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

      return WeatherData(
        temperatureF: tempF,
        humidity: humidity,
        barometricPressureInHg: pressureInHg,
        windDirection: windDir,
        windSpeedMph: windSpeedMph,
        weatherConditions: conditions,
      );
    } catch (e) {
      debugPrint('Weather parsing error: $e');
      return null;
    }
  }
}
