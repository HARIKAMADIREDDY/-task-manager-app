import 'package:hive/hive.dart';

class TaskModel {
  final int id;
  final String todo;
  final bool completed;
  final int userId;
  final String? city;
  final DateTime? dueDate;
  final String priority;
  final bool isFavorite;

  TaskModel({
    required this.id,
    required this.todo,
    required this.completed,
    required this.userId,
    this.city,
    this.dueDate,
    this.priority = 'Low',
    this.isFavorite = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      todo: json['todo'] ?? '',
      completed: json['completed'] ?? false,
      userId: json['userId'] ?? 0,
      priority: json['priority'] ?? 'Low',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todo': todo,
      'completed': completed,
      'userId': userId,
      'priority': priority,
      'isFavorite': isFavorite,
    };
  }
  
  TaskModel copyWith({
    int? id,
    String? todo,
    bool? completed,
    int? userId,
    String? city,
    DateTime? dueDate,
    String? priority,
    bool? isFavorite,
  }) {
    return TaskModel(
      id: id ?? this.id,
      todo: todo ?? this.todo,
      completed: completed ?? this.completed,
      userId: userId ?? this.userId,
      city: city ?? this.city,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    return TaskModel(
      id: reader.readInt(),
      todo: reader.readString(),
      completed: reader.readBool(),
      userId: reader.readInt(),
      city: reader.read() as String?,
      dueDate: reader.read() as DateTime?,
      priority: reader.readString(),
      isFavorite: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.todo);
    writer.writeBool(obj.completed);
    writer.writeInt(obj.userId);
    writer.write(obj.city);
    writer.write(obj.dueDate);
    writer.writeString(obj.priority);
    writer.writeBool(obj.isFavorite);
  }
}
