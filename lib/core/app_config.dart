/// Compile-time configuration via `--dart-define` / `--dart-define-from-file`.
class AppConfig {
  AppConfig._();

  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: true,
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '',
  );

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
  static bool get hasOpenWeatherKey => openWeatherApiKey.isNotEmpty;
}
