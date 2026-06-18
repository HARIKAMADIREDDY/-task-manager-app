import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/weather_model.dart';

class LocalStorageService {
  // THE 4 HIVE BOXES ARCHITECTURE:
  // We use separate boxes to keep our local overrides organized without destroying the original API data.
  static const String taskBoxName = 'tasksBoxV2'; // 1. Cache for the main API task list
  static const String weatherBoxName = 'weatherBox'; // 2. Cache for weather data to save API calls
  static const String deletedTasksBoxName = 'deletedTasksBoxV2'; // 3. The "Trash Bin" for soft-deleted tasks
  static const String addedTasksBoxName = 'addedTasksBoxV2'; // 4. Safe storage for tasks added locally (so they don't get wiped by API refresh)

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskModelAdapter());
    await Hive.openBox<TaskModel>(taskBoxName);
    await Hive.openBox<String>(weatherBoxName);
    await Hive.openBox<TaskModel>(deletedTasksBoxName);
    await Hive.openBox<TaskModel>(addedTasksBoxName);
  }

  // --- Task Operations ---
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final box = Hive.box<TaskModel>(taskBoxName);
    await box.clear();
    for (var task in tasks) {
      await box.put(task.id, task);
    }
  }

  List<TaskModel> getCachedTasks() {
    final box = Hive.box<TaskModel>(taskBoxName);
    return box.values.toList();
  }

  Future<void> saveTaskLocally(TaskModel task) async {
    final box = Hive.box<TaskModel>(taskBoxName);
    await box.put(task.id, task);
  }

  Future<void> deleteTaskLocally(int id) async {
    final box = Hive.box<TaskModel>(taskBoxName);
    await box.delete(id);
  }
  
  Future<void> clearTasks() async {
    final box = Hive.box<TaskModel>(taskBoxName);
    await box.clear();
  }

  // --- Bin (Deleted) Operations ---
  Future<void> saveToBin(TaskModel task) async {
    final box = Hive.box<TaskModel>(deletedTasksBoxName);
    await box.put(task.id, task);
  }

  Future<void> restoreFromBin(int id) async {
    final box = Hive.box<TaskModel>(deletedTasksBoxName);
    await box.delete(id);
  }

  List<TaskModel> getDeletedTasks() {
    final box = Hive.box<TaskModel>(deletedTasksBoxName);
    return box.values.toList();
  }

  bool isTaskDeleted(int id) {
    final box = Hive.box<TaskModel>(deletedTasksBoxName);
    return box.containsKey(id);
  }

  // --- Added Tasks Operations ---
  // Tasks added by the user are saved here permanently because the DummyJSON API 
  // will delete them on refresh. This box protects user-generated data.
  Future<void> saveAddedTask(TaskModel task) async {
    final box = Hive.box<TaskModel>(addedTasksBoxName);
    await box.put(task.id, task);
  }

  List<TaskModel> getAddedTasks() {
    final box = Hive.box<TaskModel>(addedTasksBoxName);
    return box.values.toList();
  }

  bool isTaskAddedLocally(int id) {
    final box = Hive.box<TaskModel>(addedTasksBoxName);
    return box.containsKey(id);
  }

  // --- Weather Operations ---
  Future<void> cacheWeather(String city, WeatherModel weather) async {
    final box = Hive.box<String>(weatherBoxName);
    await box.put(city, jsonEncode(weather.toJson()));
  }

  WeatherModel? getCachedWeather(String city) {
    final box = Hive.box<String>(weatherBoxName);
    final data = box.get(city);
    if (data != null) {
      return WeatherModel.fromJson(jsonDecode(data));
    }
    return null;
  }
}
