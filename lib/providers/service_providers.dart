import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_service.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../services/weather_service.dart';

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final tokenService = ref.read(tokenServiceProvider);
  return ApiService(tokenService);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final tokenService = ref.read(tokenServiceProvider);
  return AuthService(apiService, tokenService);
});

final taskServiceProvider = Provider<TaskService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return TaskService(apiService);
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return WeatherService(apiService);
});
