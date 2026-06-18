import '../models/weather_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class WeatherService {
  final ApiService apiService;

  WeatherService(this.apiService);

  Future<WeatherModel> getWeather(double latitude, double longitude) async {
    try {
      final response = await apiService.dio.get(
        ApiConstants.forecast,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current_weather': 'true',
        },
      );
      final current = response.data['current_weather'];
      return WeatherModel.fromJson(current);
    } catch (e) {
      throw Exception('Failed to fetch weather');
    }
  }
  Future<Map<String, double>?> getCoordinates(String city) async {
    try {
      final response = await apiService.dio.get(
        ApiConstants.geocoding,
        queryParameters: {
          'name': city,
          'count': 1,
          'language': 'en',
          'format': 'json',
        },
      );
      
      final results = response.data['results'] as List<dynamic>?;
      if (results != null && results.isNotEmpty) {
        final location = results.first;
        return {
          'latitude': (location['latitude'] as num).toDouble(),
          'longitude': (location['longitude'] as num).toDouble(),
        };
      }
      return null; // City not found
    } catch (e) {
      return null;
    }
  }
}
