import 'package:geolocator/geolocator.dart';
import '../../features/weather/domain/weather.dart';
import '../network/api_client.dart';

abstract interface class LocationService {
  Future<Coordinates> locate();
}

class DeviceLocationService implements LocationService {
  @override
  Future<Coordinates> locate() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiException('Turn on location services and try again.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const ApiException(
        'Allow location access in browser or device settings, then retry.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return Coordinates(position.latitude, position.longitude);
  }
}
