import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/weather_card.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  final int taskId;
  const EditTaskScreen({super.key, required this.taskId});

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _cityController;
  late bool _completed;
  late String _selectedCity;
  DateTime? _dueDate;
  String _priority = 'Low';
  bool _isFavorite = false;
  TaskModel? _task;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _cityController = TextEditingController();
    _completed = false;
    _selectedCity = '';
    
    Future.microtask(() {
      final tasks = ref.read(taskProvider).value ?? [];
      final task = tasks.firstWhere((t) => t.id == widget.taskId);
      setState(() {
        _task = task;
        _titleController.text = task.todo;
        _cityController.text = task.city ?? '';
        _selectedCity = task.city ?? '';
        _completed = task.completed;
        _dueDate = task.dueDate;
        _priority = task.priority;
        _isFavorite = task.isFavorite;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _updateTask() {
    if (_formKey.currentState!.validate() && _task != null) {
      final updatedTask = _task!.copyWith(
        todo: _titleController.text.trim(),
        completed: _completed,
        city: _selectedCity.isEmpty ? null : _selectedCity,
        dueDate: _dueDate,
        priority: _priority,
        isFavorite: _isFavorite,
      );

      ref.read(taskProvider.notifier).updateTask(updatedTask).then((_) {
        context.pop();
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Task')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City (Optional)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCity = _cityController.text.trim();
                      });
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: const Text('Check Weather'),
                  )
                ],
              ),
              if (_selectedCity.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: WeatherCard(city: _selectedCity),
                ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dueDate == null ? 'Select Due Date (Optional)' : 'Due Date: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Completed'),
                value: _completed,
                onChanged: (val) => setState(() => _completed = val),
              ),
              const Divider(),
              Row(
                children: [
                  const Text('Priority:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _priority,
                    items: ['Low', 'Medium', 'High']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.redAccent : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateTask,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('Update Task', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
