import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather_model.dart';
import 'service_providers.dart';

final weatherProvider = StateNotifierProvider.family<WeatherNotifier, AsyncValue<WeatherModel>, String>((ref, location) {
  return WeatherNotifier(ref, location);
});

class WeatherNotifier extends StateNotifier<AsyncValue<WeatherModel>> {
  final Ref ref;
  final String location;

  WeatherNotifier(this.ref, this.location) : super(const AsyncValue.loading()) {
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    state = const AsyncValue.loading();
    try {
      final weatherService = ref.read(weatherServiceProvider);
      final localService = ref.read(localStorageServiceProvider);

      // Dynamically fetch coordinates for the requested city!
      final targetCity = location.isEmpty ? 'Hyderabad' : location;
      final coords = await weatherService.getCoordinates(targetCity);
      
      if (coords == null) {
        state = AsyncValue.error('City not found.', StackTrace.current);
        return;
      }
      
      double lat = coords['latitude']!;
      double lon = coords['longitude']!;
      
      final weather = await weatherService.getWeather(lat, lon);
      await localService.cacheWeather(targetCity, weather);
      state = AsyncValue.data(weather);
    } catch (e) {
      try {
        final localService = ref.read(localStorageServiceProvider);
        final cached = localService.getCachedWeather(location.isEmpty ? 'Hyderabad' : location);
        if (cached != null) {
          state = AsyncValue.data(cached);
        } else {
          state = AsyncValue.error('Offline and no cached data.', StackTrace.current);
        }
      } catch (_) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}
