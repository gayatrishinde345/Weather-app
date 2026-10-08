import 'package:flutter/material.dart';
import 'weather_controller.dart';
import 'widgets/daily_weather_section.dart';
import 'widgets/weather_map.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.controller});
  final WeatherController controller;
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList.list(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.wb_sunny_outlined,
                              color: Color(0xff186b68),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Weather Atlas',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: c.loading ? null : c.refresh,
                              tooltip: 'Refresh weather',
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff145d60), Color(0xff258681)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'YOUR LOCAL WEATHER',
                                style: TextStyle(
                                  color: Colors.white70,
                                  letterSpacing: 2,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'A clearer view of your week.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                c.coordinates == null
                                    ? 'Weather based on your device location'
                                    : 'Location  ${c.coordinates!.latitude.toStringAsFixed(3)}°, ${c.coordinates!.longitude.toStringAsFixed(3)}°',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (c.loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Finding your location and loading weather…',
                                ),
                              ],
                            ),
                          ),
                        if (c.error != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.location_off_outlined,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(c.error!, textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: c.loading ? null : c.refresh,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (c.report != null) ...[
                          DailyWeatherSection(
                            title: 'Next 5 days',
                            subtitle:
                                'Daily forecast · ${c.report!.source} · °C',
                            days: c.report!.forecast,
                          ),
                          const SizedBox(height: 32),
                          DailyWeatherSection(
                            title: 'Last 5 days',
                            subtitle:
                                'Open-Meteo · Historical reanalysis with recent model estimates',
                            days: c.report!.history,
                          ),
                          if (c.report!.historyError != null)
                            Text(c.report!.historyError!),
                          const SizedBox(height: 32),
                          const Text(
                            'Weather data: Open-Meteo (CC BY 4.0). Past days exclude today; forecasts begin tomorrow.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                        if (c.coordinates != null) ...[
                          const SizedBox(height: 24),
                          WeatherMap(coordinates: c.coordinates!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
