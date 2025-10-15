import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:p7/models/weather_model.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  // Базовый URL
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiKey;
  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    final uri = Uri.parse(
      '$_baseUrl'
          '?q=$cityName'
          '&appid=$apiKey'
          '&units=metric',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather: ${response.statusCode}');
    }
  }

  Future<String> getCorrectCity() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return Future.error(
        'Location services are disabled. Opening settings...',
      );
    }
    // Разрешения
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // текущие координаты
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Обратное геокодирование в список Placemark
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return placemarks.isNotEmpty
        ? (placemarks.first.locality ?? '')
        : '';
  }
}