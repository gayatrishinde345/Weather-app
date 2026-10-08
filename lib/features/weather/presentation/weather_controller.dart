import 'package:flutter/foundation.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../domain/weather.dart';

class WeatherController extends ChangeNotifier {
  WeatherController(this.repository, this.location);
  final WeatherRepository repository;
  final LocationService location;
  bool loading = false;
  bool _disposed = false;
  String? error;
  Coordinates? coordinates;
  WeatherReport? report;
  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final point = await location.locate();
      final result = await repository.load(point);
      if (_disposed) return;
      coordinates = point;
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
