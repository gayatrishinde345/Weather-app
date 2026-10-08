class AppConfig {
  static const openWeatherKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  static const googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const useOpenWeather = bool.fromEnvironment('USE_OPENWEATHER');
}
