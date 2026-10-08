import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_app/core/network/api_client.dart';
import 'package:weather_app/features/weather/data/open_meteo_repository.dart';
import 'package:weather_app/features/weather/data/open_weather_repository.dart';
import 'package:weather_app/features/weather/domain/weather.dart';

void main() {
  test(
    'archive values replace estimates and missing recent values keep fallback',
    () async {
      final client = MockClient((request) async {
        final archive = request.url.host == 'archive-api.open-meteo.com';
        final count = archive ? 5 : 11;
        return http.Response(
          jsonEncode({
            'daily': {
              'time': List.generate(
                count,
                (i) => DateTime(
                  2026,
                  10,
                  3 + i,
                ).toIso8601String().split('T').first,
              ),
              'temperature_2m_min': List.generate(
                count,
                (i) => archive && i >= 3
                    ? null
                    : archive
                    ? 15
                    : 20,
              ),
              'temperature_2m_max': List.filled(count, 30),
              'precipitation_sum': List.filled(count, 1.5),
              'weather_code': List.filled(count, 0),
            },
          }),
          200,
        );
      });
      addTearDown(client.close);
      final report = await OpenMeteoRepository(
        ApiClient(client),
      ).load(const Coordinates(12, 77));
      expect(report.history.first.estimated, true);
      expect(report.history.first.minimum, 20);
      expect(report.history.last.estimated, false);
      expect(report.history.last.minimum, 15);
      expect(report.forecast.first.minimum, 20);
    },
  );
  test(
    'key-free API excludes today and returns five days in each direction',
    () async {
      final client = MockClient((request) async {
        if (request.url.host == 'archive-api.open-meteo.com') {
          return http.Response('Unavailable', 503);
        }
        expect(request.url.queryParameters['timezone'], 'auto');
        expect(request.url.queryParameters['past_days'], '5');
        return http.Response(
          jsonEncode({
            'daily': {
              'time': List.generate(
                11,
                (i) => DateTime(
                  2026,
                  10,
                  3 + i,
                ).toIso8601String().split('T').first,
              ),
              'temperature_2m_min': List.filled(11, 20),
              'temperature_2m_max': List.filled(11, 30),
              'precipitation_sum': List.filled(11, 1.5),
              'weather_code': List.filled(11, 0),
            },
          }),
          200,
        );
      });
      addTearDown(client.close);
      final result = await OpenMeteoRepository(
        ApiClient(client),
      ).load(const Coordinates(12, 77));
      expect(result.forecast.length, 5);
      expect(result.history.length, 5);
      expect(result.forecast.first.date, DateTime(2026, 10, 9));
      expect(result.history.first.date, DateTime(2026, 10, 7));
      expect(result.history.last.date, DateTime(2026, 10, 3));
      expect(result.history.every((day) => day.estimated), isTrue);
    },
  );
  test('OpenWeather aggregates local dates, rain, snow and partial days', () {
    final now = DateTime.utc(2026, 10, 8, 16);
    Map<String, dynamic> slot(DateTime date, double min, double max) => {
      'dt': date.millisecondsSinceEpoch ~/ 1000,
      'main': {'temp_min': min, 'temp_max': max},
      'weather': [
        {'id': 500},
      ],
      'rain': {'3h': 2},
      'snow': {'3h': 1},
    };
    final result = OpenWeatherRepository.aggregate({
      'city': {'timezone': 19800},
      'list': [
        slot(DateTime.utc(2026, 10, 8, 18), 19, 25),
        slot(DateTime.utc(2026, 10, 8, 21), 18, 27),
        slot(DateTime.utc(2026, 10, 9, 0), 20, 29),
      ],
    }, now: now);
    expect(result.length, 1);
    expect(result.single.date, DateTime(2026, 10, 9));
    expect(result.single.minimum, 18);
    expect(result.single.maximum, 29);
    expect(result.single.precipitation, 6);
    expect(result.single.partial, true);
  });
  test('HTTP auth errors are actionable without exposing API key', () async {
    final client = MockClient((_) async => http.Response('Unauthorized', 401));
    addTearDown(client.close);
    await expectLater(
      ApiClient(client).get(Uri.https('example.com', '/')),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('invalid'),
        ),
      ),
    );
  });
  test('missing daily data is not presented as zero', () {
    expect(
      () => OpenMeteoRepository.parseDaily({
        'time': ['2026-10-07'],
        'temperature_2m_min': [null],
      }),
      throwsA(isA<ApiException>()),
    );
  });
}
