import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/location/location_service.dart';
import 'package:weather_app/core/network/api_client.dart';
import 'package:weather_app/features/weather/domain/weather.dart';
import 'package:weather_app/features/weather/presentation/weather_controller.dart';
import 'package:weather_app/features/weather/presentation/weather_screen.dart';

class FakeLocation implements LocationService {
  FakeLocation({this.denied = false});
  final bool denied;
  @override
  Future<Coordinates> locate() async {
    if (denied) throw const ApiException('Location permission denied');
    return const Coordinates(12.9, 77.6);
  }
}

class FakeRepository implements WeatherRepository {
  int calls = 0;
  @override
  Future<WeatherReport> load(Coordinates coordinates) async {
    calls++;
    final days = List.generate(
      5,
      (i) => DailyWeather(
        date: DateTime(2026, 10, 9 + i),
        minimum: 20,
        maximum: 28,
        precipitation: 1.2,
        code: 61,
      ),
    );
    return WeatherReport(
      forecast: days,
      history: days,
      source: 'Test provider',
    );
  }
}

void main() {
  for (final width in [360.0, 768.0, 1200.0]) {
    testWidgets('weather dashboard fits width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = WeatherController(FakeRepository(), FakeLocation());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: WeatherScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Next 5 days'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Last 5 days'), 300);
      expect(find.text('Last 5 days'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Google Maps needs API credentials'),
        300,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('denied location offers retry without calling weather API', (
    tester,
  ) async {
    final repository = FakeRepository();
    final controller = WeatherController(
      repository,
      FakeLocation(denied: true),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: WeatherScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Location permission denied'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(repository.calls, 0);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(controller.loading, false);
  });
}
