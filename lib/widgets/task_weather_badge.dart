import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weather_provider.dart';

class TaskWeatherBadge extends ConsumerWidget {
  final String city;

  const TaskWeatherBadge({super.key, required this.city});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (city.isEmpty) return const SizedBox.shrink();

    final weatherState = ref.watch(weatherProvider(city));

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300, width: 1),
      ),
      child: weatherState.when(
        data: (weather) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny, size: 10, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              '${weather.temperature}°C',
              style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        loading: () => const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1),
        ),
        error: (err, stack) => const Text('Offline', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ),
    );
  }
}
