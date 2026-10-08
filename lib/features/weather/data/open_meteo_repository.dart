import '../../../core/network/api_client.dart';
import '../domain/weather.dart';

/// Recent past days are model estimates, not station observations.
class OpenMeteoRepository implements WeatherRepository {
  OpenMeteoRepository(this.api);
  final ApiClient api;
  @override
  Future<WeatherReport> load(Coordinates coordinates) async {
    final json = await api.get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${coordinates.latitude}',
        'longitude': '${coordinates.longitude}',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum',
        'timezone': 'auto',
        'past_days': '5',
        'forecast_days': '6',
      }),
    );
    final days = parseDaily(json['daily'] as Map<String, dynamic>);
    if (days.length != 11) {
      throw const ApiException(
        'Weather service returned incomplete daily data.',
      );
    }
    final past = days.sublist(0, 5);
    var history = past
        .map(
          (day) => DailyWeather(
            date: day.date,
            minimum: day.minimum,
            maximum: day.maximum,
            precipitation: day.precipitation,
            code: day.code,
            estimated: true,
          ),
        )
        .toList();
    // Historical reanalysis can lag several days. Keep explicitly marked
    // recent model estimates for dates not yet available in the archive.
    try {
      final archive = await api.get(
        Uri.https('archive-api.open-meteo.com', '/v1/archive', {
          'latitude': '${coordinates.latitude}',
          'longitude': '${coordinates.longitude}',
          'start_date': past.first.date.toIso8601String().split('T').first,
          'end_date': past.last.date.toIso8601String().split('T').first,
          'daily':
              'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum',
          'timezone': 'auto',
        }),
      );
      final daily = archive['daily'] as Map<String, dynamic>;
      final dates = daily['time'] as List;
      final byDate = <DateTime, DailyWeather>{};
      for (var i = 0; i < dates.length; i++) {
        const fields = [
          'temperature_2m_min',
          'temperature_2m_max',
          'precipitation_sum',
          'weather_code',
        ];
        if (fields.any((key) => (daily[key] as List)[i] == null)) continue;
        final oneDay = <String, dynamic>{
          'time': [dates[i]],
          for (final key in fields) key: [(daily[key] as List)[i]],
        };
        final day = parseDaily(oneDay).single;
        byDate[day.date] = day;
      }
      history = history.map((day) => byDate[day.date] ?? day).toList();
    } catch (_) {
      // A history outage must never prevent the required forecast from loading.
    }
    // API calendar dates use the requested location's timezone. Skip today.
    return WeatherReport(
      forecast: days.sublist(6, 11),
      history: history.reversed.toList(),
      source: 'Open-Meteo',
    );
  }

  static List<DailyWeather> parseDaily(Map<String, dynamic> daily) {
    final dates = daily['time'] as List<dynamic>;
    return List.generate(dates.length, (i) {
      double value(String key) {
        final v = (daily[key] as List<dynamic>)[i];
        if (v == null) {
          throw const ApiException('Daily data is not available yet.');
        }
        return (v as num).toDouble();
      }

      return DailyWeather(
        date: DateTime.parse(dates[i] as String),
        minimum: value('temperature_2m_min'),
        maximum: value('temperature_2m_max'),
        precipitation: value('precipitation_sum'),
        code: value('weather_code').toInt(),
      );
    });
  }
}
