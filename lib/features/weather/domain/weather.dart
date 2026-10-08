class Coordinates {
  const Coordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.minimum,
    required this.maximum,
    required this.precipitation,
    required this.code,
    this.partial = false,
    this.estimated = false,
  });
  final DateTime date;
  final double minimum;
  final double maximum;
  final double precipitation;
  final int code;
  final bool partial;
  final bool estimated;
}

class WeatherReport {
  const WeatherReport({
    required this.forecast,
    required this.history,
    required this.source,
    this.historyError,
  });
  final List<DailyWeather> forecast;
  final List<DailyWeather> history;
  final String source;
  final String? historyError;
}

abstract interface class WeatherRepository {
  Future<WeatherReport> load(Coordinates coordinates);
}
