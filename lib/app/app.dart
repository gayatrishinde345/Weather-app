import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/location/location_service.dart';
import '../core/location/place_name_service.dart';
import '../core/network/api_client.dart';
import '../features/weather/data/open_meteo_repository.dart';
import '../features/weather/data/open_weather_repository.dart';
import '../features/weather/presentation/weather_controller.dart';
import '../features/weather/presentation/weather_screen.dart';

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});
  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final client = http.Client();
  late final WeatherController controller;
  @override
  void initState() {
    super.initState();
    final api = ApiClient(client);
    final meteo = OpenMeteoRepository(api);
    controller = WeatherController(
      AppConfig.useOpenWeather
          ? OpenWeatherRepository(api, AppConfig.openWeatherKey, meteo)
          : meteo,
      DeviceLocationService(),
      placeNames: PhotonPlaceNameService(api),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Weather Atlas',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff186b68)),
      scaffoldBackgroundColor: const Color(0xfff4f7f8),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    ),
    home: WeatherScreen(controller: controller),
  );
}
