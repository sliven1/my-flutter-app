import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:p7/models/weather_model.dart';
import 'package:p7/service/weather_sevice.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

  class _WeatherPageState extends State<WeatherPage> {

  final _weatherService = WeatherService('86bd626c4125ab2acf581ba4102cb0b8');
  Weather? _weather;

  _fetchWeather() async {
    String cityName = await _weatherService.getCorrectCity();

    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    }
    catch (e) {
      print(e);
    }
  }

  String getWeatherAnimation(String? mainCondition) {
    switch (mainCondition?.toLowerCase()) {
      case 'clear':
        return 'assets/clear.json';
      case 'clouds':
      // у вас partly-cloudy.json
        return 'assets/partly-cloudy.json';
      case 'mist':
        return 'assets/mist.json';
      case 'rain':
      case 'drizzle': // если захотите обработать морось отдельно
        return 'assets/rain.json';
      case 'snow':
        return 'assets/snow.json';
      case 'thunderstorm':
        return 'assets/thunderstorm.json';
      default:
      // на случай неизвестного условия
        return 'assets/clear.json';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          centerTitle: true,
          title: Text("W E A T H E R"),
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_weather?.cityName ?? "loading city",
              style: TextStyle(
                fontSize: 26,
                color: Theme.of(context).colorScheme.primary
              )),


              Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),

              Text('${_weather?.temperature.round()}°С',
                  style: TextStyle(
                  fontSize: 48,
                  color: Theme.of(context).colorScheme.primary
              )),

              Text(_weather?.mainCondition ?? "",
                  style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary
                  )),
            ],
          ),
        ),
      );
    }
  }
