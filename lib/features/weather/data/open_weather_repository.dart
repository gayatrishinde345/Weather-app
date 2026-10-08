import 'dart:math' as math;
import '../../../core/network/api_client.dart';
import '../domain/weather.dart';
import 'open_meteo_repository.dart';

class OpenWeatherRepository implements WeatherRepository {
  OpenWeatherRepository(this.api, this.apiKey, this.history);
  final ApiClient api;
  final String apiKey;
  final OpenMeteoRepository history;
  @override
  Future<WeatherReport> load(Coordinates coordinates) async {
    if (apiKey.isEmpty) {
      throw const ApiException('Configure OPENWEATHER_API_KEY.');
    }
    final json = await api.get(
      Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
        'lat': '${coordinates.latitude}',
        'lon': '${coordinates.longitude}',
        'appid': apiKey,
        'units': 'metric',
      }),
    );
    final forecast = aggregate(json);
    try {
      final past = await history.load(coordinates);
      return WeatherReport(
        forecast: forecast,
        history: past.history,
        source: 'OpenWeatherMap',
      );
    } catch (_) {
      return WeatherReport(
        forecast: forecast,
        history: const [],
        source: 'OpenWeatherMap',
        historyError: 'Recent history is currently unavailable.',
      );
    }
  }

  /// Aggregate three-hour slots by location day; mark incomplete final days.
  static List<DailyWeather> aggregate(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final offset = (json['city']['timezone'] as num).toInt();
    final groups = <DateTime, List<Map<String, dynamic>>>{};
    final slots = (json['list'] as List).cast<Map<String, dynamic>>();
    if (slots.isEmpty) throw const ApiException('No forecast data available.');
    DateTime localDate(int timestamp) {
      final local = DateTime.fromMillisecondsSinceEpoch(
        (timestamp + offset) * 1000,
        isUtc: true,
      );
      return DateTime(local.year, local.month, local.day);
    }

    final today = localDate(
      (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000,
    );
    for (final slot in slots) {
      final date = localDate((slot['dt'] as num).toInt());
      if (date.isAfter(today)) (groups[date] ??= []).add(slot);
    }
    final dates = groups.keys.toList()..sort();
    return dates.take(5).map((date) {
      final day = groups[date]!;
      double rain(Map<String, dynamic> slot) =>
          ((slot['rain']?['3h'] ?? 0) as num).toDouble() +
          ((slot['snow']?['3h'] ?? 0) as num).toDouble();
      final id = (day[day.length ~/ 2]['weather'][0]['id'] as num).toInt();
      final code = switch (id) {
        < 300 => 95,
        < 400 => 51,
        < 600 => 61,
        < 700 => 71,
        < 800 => 45,
        800 => 0,
        _ => 3,
      };
      return DailyWeather(
        date: date,
        minimum: day
            .map((s) => (s['main']['temp_min'] as num).toDouble())
            .reduce(math.min),
        maximum: day
            .map((s) => (s['main']['temp_max'] as num).toDouble())
            .reduce(math.max),
        precipitation: day.map(rain).reduce((a, b) => a + b),
        code: code,
        partial: day.length < 8,
      );
    }).toList();
  }
}
