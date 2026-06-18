import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import 'service_providers.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, AsyncValue<List<TaskModel>>>((ref) {
  return TaskNotifier(ref);
});

class TaskNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final Ref ref;
  List<TaskModel> _allTasks = [];

  bool hasMore = true;
  bool isFetchingMore = false;
  static const int _limit = 15;
  
  String _currentQuery = '';
  String _currentFilter = 'All';

  TaskNotifier(this.ref) : super(const AsyncValue.loading());

  Future<String?> fetchTasks() async {
    state = const AsyncValue.loading();
    hasMore = true;
    try {
      final taskService = ref.read(taskServiceProvider);
      final localService = ref.read(localStorageServiceProvider);

      final fetchedTasks = await taskService.getTasks(limit: _limit, skip: 0);
      
      // Filter out tasks the user deleted locally (since API won't know about them)
      final activeFetched = fetchedTasks.where((t) => !localService.isTaskDeleted(t.id)).toList();
      
      // HYBRID STATE: Prepend tasks the user added locally
      // This seamlessly merges real API data with local offline data
      final addedTasks = localService.getAddedTasks();
      _allTasks = [...addedTasks, ...activeFetched];
      
      if (fetchedTasks.length < _limit) hasMore = false;
      
      // Cache this fresh hybrid list so the user has it if they go offline
      await localService.cacheTasks(_allTasks);
      _applyCurrentFilter();
    } catch (e) {
      try {
        // OFFLINE SUPPORT FALLBACK: The API failed, so we read the Hive cache
        final localService = ref.read(localStorageServiceProvider);
        final cached = localService.getCachedTasks();
        if (cached.isNotEmpty) {
          _allTasks = cached;
          _applyCurrentFilter();
          return 'You are offline. Showing saved data.';
        } else {
          state = AsyncValue.error('You are offline. Showing saved data. (No cached data)', StackTrace.current);
          return null;
        }
      } catch (_) {
         state = AsyncValue.error(e, StackTrace.current);
         return null;
      }
    }
    return null;
  }

  Future<void> fetchMoreTasks() async {
    if (isFetchingMore || !hasMore || state is! AsyncData) return;
    
    isFetchingMore = true;
    try {
      final taskService = ref.read(taskServiceProvider);
      final localService = ref.read(localStorageServiceProvider);
      
      final newTasks = await taskService.getTasks(limit: _limit, skip: _allTasks.length - localService.getAddedTasks().length);
      if (newTasks.length < _limit) {
        hasMore = false;
      }
      
      final activeNew = newTasks.where((t) => !localService.isTaskDeleted(t.id)).toList();
      _allTasks.addAll(activeNew);
      await localService.cacheTasks(_allTasks);
      _applyCurrentFilter();
    } catch (e) {
      // Ignore pagination errors to not disrupt UI
    } finally {
      isFetchingMore = false;
    }
  }

  Future<void> addTask(TaskModel task) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      final localService = ref.read(localStorageServiceProvider);
      
      final newTask = await taskService.addTask(task);
      _allTasks.insert(0, newTask); // Add to top
      await localService.saveTaskLocally(newTask);
      await localService.saveAddedTask(newTask); // Save permanently as local addition
      _applyCurrentFilter();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      final localService = ref.read(localStorageServiceProvider);
      
      TaskModel updatedTask;
      if (localService.isTaskAddedLocally(task.id)) {
        updatedTask = task; // Skip API call because DummyJSON throws 404 for mock IDs
      } else {
        updatedTask = await taskService.updateTask(task);
      }
      
      final index = _allTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _allTasks[index] = updatedTask;
        await localService.saveTaskLocally(updatedTask);
        if (localService.isTaskAddedLocally(task.id)) {
          await localService.saveAddedTask(updatedTask);
        }
        _applyCurrentFilter();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      final localService = ref.read(localStorageServiceProvider);
      
      if (!localService.isTaskAddedLocally(id)) {
        await taskService.deleteTask(id);
      }
      
      final taskToBin = _allTasks.firstWhere((t) => t.id == id);
      await localService.saveToBin(taskToBin);
      
      _allTasks.removeWhere((t) => t.id == id);
      await localService.deleteTaskLocally(id);
      _applyCurrentFilter();
    } catch (e) {
      rethrow;
    }
  }

  void filterTasks(String query, String filterType) {
    _currentQuery = query;
    _currentFilter = filterType;
    _applyCurrentFilter();
  }

  void _applyCurrentFilter() {
    if (state is! AsyncData && state is! AsyncError && _allTasks.isEmpty) return;
    
    final localService = ref.read(localStorageServiceProvider);
    
    if (_currentFilter == 'Bin') {
      var binTasks = localService.getDeletedTasks();
      if (_currentQuery.isNotEmpty) {
        binTasks = binTasks.where((t) => t.todo.toLowerCase().contains(_currentQuery.toLowerCase())).toList();
      }
      state = AsyncValue.data(binTasks);
      return;
    }
    
    var filtered = List<TaskModel>.from(_allTasks);
    
    if (_currentQuery.isNotEmpty) {
      filtered = filtered.where((t) => t.todo.toLowerCase().contains(_currentQuery.toLowerCase())).toList();
    }
    
    if (_currentFilter == 'Pending') {
      filtered = filtered.where((t) => !t.completed).toList();
    } else if (_currentFilter == 'Completed') {
      filtered = filtered.where((t) => t.completed).toList();
    } else if (_currentFilter == 'Favorites') {
      filtered = filtered.where((t) => t.isFavorite).toList();
    }
    
    state = AsyncValue.data(filtered);
  }

  Future<void> restoreTask(int id) async {
    final localService = ref.read(localStorageServiceProvider);
    await localService.restoreFromBin(id);
    fetchTasks(); // Refetch to rebuild the main list cleanly
  }
}
