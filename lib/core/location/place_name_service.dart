import '../../features/weather/domain/weather.dart';
import '../network/api_client.dart';

abstract interface class PlaceNameService {
  Future<String?> lookup(Coordinates coordinates);
}

class PhotonPlaceNameService implements PlaceNameService {
  PhotonPlaceNameService(this.api);
  final ApiClient api;

  @override
  Future<String?> lookup(Coordinates coordinates) async {
    final json = await api
        .get(
          Uri.https('photon.komoot.io', '/reverse', {
            'lat': '${coordinates.latitude}',
            'lon': '${coordinates.longitude}',
            'lang': 'en',
            'limit': '1',
          }),
        )
        .timeout(const Duration(seconds: 8));
    final features = json['features'];
    if (features is! List || features.isEmpty) return null;
    final feature = features.first;
    if (feature is! Map) return null;
    final properties = feature['properties'];
    if (properties is! Map) return null;
    // Prefer the city over the name of a nearby business or street.
    for (final key in ['city', 'locality', 'district']) {
      final value = properties[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    if (properties['osm_key'] == 'place' &&
        const [
          'city',
          'town',
          'village',
          'hamlet',
        ].contains(properties['osm_value'])) {
      final name = properties['name'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    }
    return null;
  }
}
