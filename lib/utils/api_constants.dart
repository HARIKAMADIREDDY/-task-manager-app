class ApiConstants {
  static const String dummyJsonBaseUrl = 'https://dummyjson.com';
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';

  // Auth Endpoints
  static const String login = '$dummyJsonBaseUrl/auth/login';
  static const String refresh = '$dummyJsonBaseUrl/auth/refresh';
  static const String authMe = '$dummyJsonBaseUrl/auth/me';

  // Task Endpoints
  static const String todos = '$dummyJsonBaseUrl/todos';
  static String todoById(int id) => '$dummyJsonBaseUrl/todos/$id';
  static const String addTodo = '$dummyJsonBaseUrl/todos/add';

  // Weather & Geocoding Endpoint
  static const String forecast = '$openMeteoBaseUrl/forecast';
  static const String geocoding = 'https://geocoding-api.open-meteo.com/v1/search';
}