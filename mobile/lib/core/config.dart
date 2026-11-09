/// Base URL of the Laravel API.
/// Android emulator: http://10.0.2.2:8000/api (default)
/// Override with: flutter run --dart-define=API_URL=http://192.168.1.5:8000/api
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);
