import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../domain/weather.dart';

class WeatherTileProvider implements TileProvider {
  WeatherTileProvider(this.client, this.layer, this.apiKey, this.onError);
  final http.Client client;
  final String layer;
  final String apiKey;
  final VoidCallback onError;
  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null || y < 0 || y >= (1 << zoom)) return TileProvider.noTile;
    try {
      final wrappedX = x % (1 << zoom);
      final uri = Uri.https(
        'tile.openweathermap.org',
        '/map/$layer/$zoom/$wrappedX/$y.png',
        {'appid': apiKey},
      );
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        onError();
        return TileProvider.noTile;
      }
      return Tile(256, 256, Uint8List.fromList(response.bodyBytes));
    } catch (_) {
      onError();
      return TileProvider.noTile;
    }
  }
}

class WeatherMap extends StatefulWidget {
  const WeatherMap({super.key, required this.coordinates});
  final Coordinates coordinates;
  @override
  State<WeatherMap> createState() => _WeatherMapState();
}

class _WeatherMapState extends State<WeatherMap> {
  final client = http.Client();
  bool temperature = true;
  bool precipitation = false;
  bool tileError = false;
  double opacity = 0.75;
  GoogleMapController? mapController;
  late final temperatureProvider = WeatherTileProvider(
    client,
    'temp_new',
    AppConfig.openWeatherKey,
    failed,
  );
  late final precipitationProvider = WeatherTileProvider(
    client,
    'precipitation_new',
    AppConfig.openWeatherKey,
    failed,
  );
  bool get mapConfigured => AppConfig.googleMapsKey.isNotEmpty;
  bool get configured => mapConfigured && AppConfig.openWeatherKey.isNotEmpty;

  Future<void> retryTiles() async {
    setState(() => tileError = false);
    await mapController?.clearTileCache(
      TileOverlayId(temperature ? 'temperature' : 'precipitation'),
    );
  }

  void failed() {
    if (mounted && !tileError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !tileError) setState(() => tileError = true);
      });
    }
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supported = kIsWeb || defaultTargetPlatform == TargetPlatform.android;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather map',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Temperature & precipitation around your location'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Temperature'),
                  selected: temperature,
                  onSelected: configured
                      ? (v) => setState(() {
                          temperature = true;
                          precipitation = false;
                          tileError = false;
                        })
                      : null,
                ),
                ChoiceChip(
                  label: const Text('Precipitation'),
                  selected: precipitation,
                  onSelected: configured
                      ? (v) => setState(() {
                          precipitation = true;
                          temperature = false;
                          tileError = false;
                        })
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!mapConfigured || !supported)
              Container(
                constraints: const BoxConstraints(minHeight: 280),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xffe6efef),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      supported
                          ? 'Google Maps needs API credentials'
                          : 'Map available on Android and Web',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The map is unavailable. Please configure the map service and try again.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 360,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        EagerGestureRecognizer.new,
                      ),
                    },
                    onMapCreated: (controller) => mapController = controller,
                    key: ValueKey(
                      '${widget.coordinates.latitude},${widget.coordinates.longitude}',
                    ),
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        widget.coordinates.latitude,
                        widget.coordinates.longitude,
                      ),
                      zoom: 6,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('location'),
                        position: LatLng(
                          widget.coordinates.latitude,
                          widget.coordinates.longitude,
                        ),
                        infoWindow: const InfoWindow(title: 'Your location'),
                      ),
                    },
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tileOverlays: {
                      if (configured && temperature)
                        TileOverlay(
                          tileOverlayId: const TileOverlayId('temperature'),
                          tileProvider: temperatureProvider,
                          transparency: 1 - opacity,
                          zIndex: 1,
                        ),
                      if (configured && precipitation)
                        TileOverlay(
                          tileOverlayId: const TileOverlayId('precipitation'),
                          tileProvider: precipitationProvider,
                          transparency: 1 - opacity,
                          zIndex: 2,
                        ),
                    },
                  ),
                ),
              ),
            if (mapConfigured && !configured)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Weather layers are unavailable until the weather map service is configured.',
                ),
              ),
            if (configured && supported) ...[
              const SizedBox(height: 12),
              Text(
                temperature
                    ? 'Temperature: cooler areas to warmer areas'
                    : 'Precipitation: clear areas have little or no precipitation',
              ),
              Row(
                children: [
                  const Text('Layer opacity'),
                  Expanded(
                    child: Slider(
                      value: opacity,
                      min: 0.2,
                      max: 1,
                      divisions: 8,
                      label: '${(opacity * 100).round()}%',
                      onChanged: (value) => setState(() => opacity = value),
                    ),
                  ),
                ],
              ),
            ],
            if (tileError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weather layer could not load. Check the connection or weather service credentials.',
                    ),
                    TextButton.icon(
                      onPressed: retryTiles,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry layer'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Weather layers © OpenWeatherMap • Temperature: °C • Precipitation: mm',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
