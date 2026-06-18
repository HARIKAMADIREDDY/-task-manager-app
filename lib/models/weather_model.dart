class WeatherModel {
  final double temperature;
  final double windspeed;
  final int weathercode;
  final String time;

  WeatherModel({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
    required this.time,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      windspeed: (json['windspeed'] as num?)?.toDouble() ?? 0.0,
      weathercode: json['weathercode'] ?? 0,
      time: json['time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'windspeed': windspeed,
      'weathercode': weathercode,
      'time': time,
    };
  }

  String get condition {
    if (weathercode == 0) return 'Clear sky';
    if (weathercode <= 3) return 'Partly cloudy';
    if (weathercode <= 49) return 'Foggy';
    if (weathercode <= 69) return 'Rain';
    if (weathercode <= 79) return 'Snow';
    if (weathercode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}
