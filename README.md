# Weather Atlas

A Flutter Web/Android assignment application using the user's device location. Features are limited to five future daily forecasts, five recent historical days, temperature/precipitation weather layers on Google Maps, responsive layouts and PWA installation.

## Run

Requires Flutter with Dart 3.9.2 or newer and Chrome / an Android emulator or device.

```powershell
flutter pub get
flutter run -d chrome
```

The default weather provider is **Open-Meteo**, an open-source API with no API key for non-commercial use. Allow location access. Web geolocation requires localhost or HTTPS. Denied permissions, disabled location, timeouts and API failures offer a retry action. No sample weather is substituted for real data.

## Configure Google Maps and OpenWeatherMap

Google Maps is required by the assignment and is not an open-source service. OpenWeatherMap tile layers also require an API key. The map integration is implemented; credentials cannot be supplied by the project.

1. Copy `config.example.json` to `config.json` (ignored by Git).
2. Set `OPENWEATHER_API_KEY` from https://home.openweathermap.org/api_keys for Weather Maps 1.0.
3. Enable Maps JavaScript API for Web and Maps SDK for Android in Google Cloud, with the required billing configuration. Set `GOOGLE_MAPS_API_KEY`. Use separate restricted keys/config files for each platform: HTTP referrer restrictions for your website, Android package/SHA-1 restrictions for Android.
4. Keep `USE_OPENWEATHER` as `false` for the open-source weather provider. Set it to `true` to use OpenWeatherMap's five-day forecast API for assignment alignment. History continues to use Open-Meteo.
5. Run via the helper so the same Google key is passed to Dart and the Web bootstrap / Android manifest:

```powershell
./tool/run.ps1 -Action run -Device chrome
./tool/run.ps1 -Action run -Device emulator-5554
./tool/run.ps1 -Action web
./tool/run.ps1 -Action apk
```

For a different config file: `./tool/run.ps1 -Action web -Config config.web.json`. Keep any additional credential files outside version control. Client API keys are visible in compiled applications; use provider-side restrictions and quotas. No private server credentials belong here. Android reads the Google key from Flutter's base64-encoded dart-defines at build time. Web's helper writes the ignored `web/maps-config.json` before building. For macOS/Linux, write that JSON with the Google key and use `flutter run/build --dart-define-from-file=config.json` directly.

Select Temperature or Precipitation to view one clear weather layer at a time. Use Layer opacity to keep roads and labels readable. OpenWeatherMap Weather Maps 1.0 tiles use `temp_new` / `precipitation_new`. Google Maps can display with only its Google key; the weather layers require the OpenWeatherMap key as well. Failed weather tiles offer Retry layer. The map remains available when forecast loading fails after location is found. Google Maps authentication/billing errors also appear in browser/device logs. Live Maps rendering needs real credentials and must be verified on both platforms before submission.

## Weather data and requirement tradeoffs

- Forecast dates start tomorrow; history ends yesterday, using the API's location timezone rather than the device timezone.
- Open-Meteo requests six forecast days and five past days. It also calls the **Historical Weather API** (`archive-api.open-meteo.com/v1/archive`) for those five past calendar days.
- Historical reanalysis is an estimate derived from observations and models, not measured station actuals. Archive data can lag: recent unavailable days fall back to recent forecast-model data and each such card says **Model estimate**. An archive outage leaves forecasts available. This is the open-source alternative requested by the candidate; the employer's original provider/actual-observation requirement is not identical. The assignment explicitly allows skipping historical integration when access is unavailable.
- Optional OpenWeatherMap mode aggregates three-hour forecast intervals into daily minimum/maximum temperature and total rain/snow. The last day can be incomplete, shown as **Partial day**. Daily condition represents the middle interval, not a guaranteed all-day condition.
- Free Open-Meteo access is for non-commercial use; check licensing before using this assignment commercially.

API references: [Open-Meteo forecast](https://open-meteo.com/en/docs), [Open-Meteo history](https://open-meteo.com/en/docs/historical-weather-api), [OpenWeatherMap forecast](https://openweathermap.org/api/forecast5), [weather tiles](https://openweathermap.org/api/weathermaps), [Google Maps setup](https://developers.google.com/maps/documentation/javascript/get-api-key). Open-Meteo attribution is displayed in the app (CC BY 4.0); Google Maps retains its attribution.

## Structure and design

```text
lib/
  main.dart                         # Entry point
  app/app.dart                      # Composition, dependency injection, theme
  core/
    config/app_config.dart          # Compile-time provider/key settings
    location/location_service.dart  # Device permissions and coordinates
    network/api_client.dart         # HTTP, timeouts and status errors
  features/weather/
    domain/weather.dart             # Models and repository contract
    data/                           # Provider implementations and parsing
    presentation/
      weather_controller.dart       # View model: loading, report, errors
      weather_screen.dart           # Responsive screen
      widgets/                      # Forecast cards and Google Maps overlays
 test/                              # Unit and widget tests
 tool/run.ps1                       # Cross-platform configuration wiring
 web/                               # Manifest, bootstrap and PWA shell worker
```

Feature-first layered architecture with repository interfaces and MVVM using Flutter's `ChangeNotifier`/`ListenableBuilder`. Dependencies are injected through the composition root. HTTP and location services can be replaced by test doubles. No additional state framework is needed for one screen. Browser/Android implementation details stay outside the domain.

## Validate

```powershell
dart format lib test
flutter analyze
flutter test
flutter build web --pwa-strategy=none
flutter build apk --debug
```

Tests cover local calendar aggregation, partial forecasts, API errors, missing values, denied location and responsive screen rendering at 360, 768 and 1200 pixels. Before submission, also test permission allow/deny on a real browser and Android device, toggle both weather layers with valid keys, and check installation from an HTTPS deployment.

## PWA

Build with `./tool/run.ps1 -Action web`, then serve `build/web` over HTTPS (localhost for development). Chrome/Edge: use **Install app** in the browser menu; Android Chrome: **Install app / Add to home screen**. The manifest provides standalone display and icons. A custom service worker caches the shell and uses network-first updates. Weather/location and third-party map data require an internet connection; cached shell assets do not promise fully offline weather or map use. When changing the shell, increment the cache version in `web/sw.js`. Do not simultaneously enable Flutter's legacy generated service worker.

## Git

This workspace is inside an existing parent repository containing other projects and already staged changes. No unrelated files or existing index entries were modified intentionally, and no broad commit was created. Commit only this application's reviewed files; do not run an unrestricted `git add .` from the parent directory.

Suggested focused commits in a dedicated assignment repository:
1. `chore: configure Flutter platforms and API settings`
2. `feat: add location-based forecast and history repositories`
3. `feat: add responsive weather dashboard and map layers`
4. `test: cover API parsing, permission errors and layouts`
5. `docs: document setup and PWA installation`

Keep `pubspec.lock` tracked for reproducible app dependency versions. `config.json`, generated map configuration and build outputs are ignored. Android release currently uses the scaffold's debug signing for local evaluation; configure your own signing before Play Store distribution.

## Assignment acknowledgment (copy into your reply)

Thank you for sharing the assignment. I acknowledge receipt of the requirements for a Flutter Web/Android weather application with location-based forecasts, recent historical weather and temperature/precipitation layers on Google Maps. I will complete the forecast and maps integrations and document any historical API access limitations.

## Validation on this workspace

- `flutter analyze`: no issues.
- `flutter test`: all 9 tests passed.
- Release Web build: passed; output is `build/web`.
- Android debug APK with Java entry point: passed (ARM64). Output: `build/app/outputs/flutter-apk/app-debug.apk`.
- Live forecast request returned 11 daily entries and live historical request returned 5 entries.
- Service worker and built bootstrap passed JavaScript syntax checks.

Windows setup notes discovered here: enable Developer Mode if Flutter reports missing symlink support. The machine's `JAVA_HOME` points at a `bin` directory; Java tools expect the JDK root. Flutter itself selected Android Studio's bundled runtime correctly. If Android builds report a Gradle project lock, finish the other build before retrying; the validation build used a separate project cache to avoid interfering with it. Live Google Maps rendering and on-device permission prompts still require manual testing with your keys/device.

Application code is Dart, with a Java Android entry point and Groovy Gradle scripts. The application does not apply a Kotlin plugin or contain Kotlin source. Third-party Flutter plugins and Flutter tooling may internally use Kotlin. Incremental compilation for those plugin dependencies is disabled to avoid Windows errors when the project and Pub cache are on different drives.

The root Gradle settings pin a compiler version only for third-party plugin compatibility (`apply false`). The Java application module does not apply that plugin. This is required by Google Maps' Flutter dependency, not by custom application code.
Android build tools use AGP 8.13.2 and Gradle 8.13 for the current Google Maps dependency. Reference: https://developer.android.com/build/releases/agp-8-13-0-release-notes. Android validation succeeded with the installed JDK at `C:\Program Files\Java\jdk-21` and an isolated Gradle project cache. The generated debug APK targets ARM64 devices; use the normal Flutter build commands above for your desired device targets.

