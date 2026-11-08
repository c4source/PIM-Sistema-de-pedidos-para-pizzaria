class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'PIM_API_URL',
    defaultValue: 'http://10.0.2.2:5162',
  );
}
