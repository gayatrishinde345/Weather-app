import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_app/core/location/location_service.dart';
import 'package:weather_app/core/location/place_name_service.dart';
import 'package:weather_app/core/network/api_client.dart';
import 'package:weather_app/features/weather/domain/weather.dart';
import 'package:weather_app/features/weather/presentation/weather_controller.dart';
import 'widget_test.dart' show FakeRepository;

class MovingLocation implements LocationService {
  MovingLocation(this.points);
  final List<Coordinates> points;
  int index = 0;

  @override
  Future<Coordinates> locate() async => points[index++];
}

class LookupPlaceNames implements PlaceNameService {
  LookupPlaceNames(this.onLookup);
  final Future<String?> Function(Coordinates) onLookup;

  @override
  Future<String?> lookup(Coordinates coordinates) => onLookup(coordinates);
}

void main() {
  const nashik = Coordinates(20, 73.783);
  const pune = Coordinates(18.5204, 73.8567);

  test(
    'reverse lookup uses device coordinates and prefers the city to a POI',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'photon.komoot.io');
        expect(request.url.queryParameters['lat'], '20.0');
        expect(request.url.queryParameters['lon'], '73.783');
        return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {'city': 'Nashik', 'name': 'Nearby hospital'},
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      expect(
        await PhotonPlaceNameService(ApiClient(client)).lookup(nashik),
        'Nashik',
      );
    },
  );

  test('city name follows the device when the location changes', () async {
    final controller = WeatherController(
      FakeRepository(),
      MovingLocation([nashik, pune]),
      placeNames: LookupPlaceNames(
        (point) async => point == nashik ? 'Nashik' : 'Pune',
      ),
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.locationName, 'Nashik');
    await controller.refresh();
    expect(controller.coordinates, pune);
    expect(controller.locationName, 'Pune');
  });

  test(
    'slow lookup does not delay weather or overwrite a newer location',
    () async {
      final oldName = Completer<String?>();
      final controller = WeatherController(
        FakeRepository(),
        MovingLocation([nashik, pune]),
        placeNames: LookupPlaceNames(
          (point) => point == nashik ? oldName.future : Future.value('Pune'),
        ),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.loading, false);
      expect(controller.report, isNotNull);
      expect(controller.locationName, isNull);
      await controller.refresh();
      oldName.complete('Nashik');
      await Future<void>.delayed(Duration.zero);
      expect(controller.locationName, 'Pune');
      expect(controller.coordinates, pune);
    },
  );

  test(
    'a name lookup outage leaves weather and coordinates available',
    () async {
      final controller = WeatherController(
        FakeRepository(),
        MovingLocation([nashik]),
        placeNames: LookupPlaceNames(
          (_) async => throw Exception('Geocoder unavailable'),
        ),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.error, isNull);
      expect(controller.report, isNotNull);
      expect(controller.coordinates, nashik);
      expect(controller.locationName, isNull);
    },
  );
}
