import '../models/task_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class TaskService {
  final ApiService apiService;

  TaskService(this.apiService);
  //Task List (GET https://dummyjson.com/todos)

  Future<List<TaskModel>> getTasks({int limit = 15, int skip = 0}) async {
    try {
      final response = await apiService.dio.get(
        ApiConstants.todos,
        queryParameters: {
          'limit': limit,
          'skip': skip,
        },
      );
      // The API returns a JSON object with a 'todos' key containing the list of tasks,Automatic JSON Parsing & Less Code
      final List<dynamic> todosJson = response.data['todos'];
      return todosJson.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks');
    }
  }
 // POST https://dummyjson.com/todos/add

  Future<TaskModel> addTask(TaskModel task) async {
    try {
      final response = await apiService.dio.post(
        ApiConstants.addTodo,
        data: {
          'todo': task.todo,
          'completed': task.completed,
          'userId': task.userId,
        },
      );
      // BFF PATTERN: The DummyJSON API only accepts 'todo', 'completed', and 'userId'.
      // When it replies with success, it forgets our custom fields. 
      // We immediately glue the local custom fields (priority, favorite, etc.) back onto the new task!
      return TaskModel.fromJson(response.data).copyWith(
        city: task.city,
        dueDate: task.dueDate,
        priority: task.priority,
        isFavorite: task.isFavorite,
      );
    } catch (e) {
      throw Exception('Failed to add task');
    }
  }
  // PUT https://dummyjson.com/todos/{id}

  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await apiService.dio.put(
        ApiConstants.todoById(task.id),
        data: {
          'todo': task.todo,
          'completed': task.completed,
        },
      );
      // PRESERVING HYBRID STATE:
      // Re-attach custom local fields before returning, so the UI doesn't lose the Favorite Star or Priority badge!
      return TaskModel.fromJson(response.data).copyWith(
        city: task.city,
        dueDate: task.dueDate,
        priority: task.priority,
        isFavorite: task.isFavorite,
      );
    } catch (e) {
      throw Exception('Failed to update task');
    }
  }
  //DELETE https://dummyjson.com/todos/{id}

  Future<void> deleteTask(int id) async {
    try {
      await apiService.dio.delete(ApiConstants.todoById(id));
    } catch (e) {
      throw Exception('Failed to delete task');
    }
  }
}
