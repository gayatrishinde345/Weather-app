import 'package:flutter/material.dart';
import '../../domain/weather.dart';

String weatherLabel(int code) => switch (code) {
  0 => 'Clear sky',
  1 || 2 => 'Partly cloudy',
  3 => 'Overcast',
  45 || 48 => 'Fog',
  >= 51 && <= 57 => 'Drizzle',
  >= 61 && <= 67 => 'Rain',
  >= 71 && <= 77 => 'Snow',
  >= 80 && <= 82 => 'Rain showers',
  85 || 86 => 'Snow showers',
  >= 95 => 'Thunderstorm',
  _ => 'Unknown conditions',
};
IconData weatherIcon(int code) => switch (code) {
  0 => Icons.wb_sunny_outlined,
  1 || 2 || 3 => Icons.cloud_outlined,
  45 || 48 => Icons.blur_on,
  >= 71 && <= 77 || 85 || 86 => Icons.ac_unit,
  >= 95 => Icons.thunderstorm_outlined,
  _ => Icons.water_drop_outlined,
};
String dayLabel(DateTime date) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${names[date.weekday - 1]}, ${date.day}/${date.month}';
}

class DailyWeatherSection extends StatelessWidget {
  const DailyWeatherSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.days,
  });
  final String title;
  final String subtitle;
  final List<DailyWeather> days;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(subtitle),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 5
              : constraints.maxWidth >= 550
              ? 3
              : 2;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: days
                .map(
                  (day) => SizedBox(
                    width: width,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayLabel(day.date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Icon(
                              weatherIcon(day.code),
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${day.maximum.round()}° / ${day.minimum.round()}°',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(weatherLabel(day.code)),
                            const SizedBox(height: 12),
                            Text('${day.precipitation.toStringAsFixed(1)} mm'),
                            if (day.estimated)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Model estimate',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            if (day.partial)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text('Partial day'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}
