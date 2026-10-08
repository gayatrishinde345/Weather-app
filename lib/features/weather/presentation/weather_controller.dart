import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/location/location_service.dart';
import '../../../core/location/place_name_service.dart';
import '../../../core/network/api_client.dart';
import '../domain/weather.dart';

class WeatherController extends ChangeNotifier {
  WeatherController(this.repository, this.location, {this.placeNames});
  final WeatherRepository repository;
  final LocationService location;
  final PlaceNameService? placeNames;
  bool loading = false;
  bool _disposed = false;
  int _refreshId = 0;
  String? error;
  String? locationName;
  Coordinates? coordinates;
  WeatherReport? report;
  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    final refreshId = ++_refreshId;
    error = null;
    notifyListeners();
    try {
      final point = await location.locate();
      if (_disposed) return;
      coordinates = point;
      locationName = null;
      report = null;
      unawaited(_lookupName(point, refreshId));
      notifyListeners();
      final result = await repository.load(point);
      if (_disposed) return;
      report = result;
    } catch (e) {
      if (_disposed) return;
      error = e is ApiException
          ? e.message
          : 'Unable to load weather. Check your connection and location access, then retry.';
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _lookupName(Coordinates point, int refreshId) async {
    if (placeNames == null) return;
    try {
      final name = await placeNames!.lookup(point);
      if (_disposed || refreshId != _refreshId) return;
      locationName = name;
      notifyListeners();
    } catch (_) {
      // Weather remains available when the optional name lookup fails.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
