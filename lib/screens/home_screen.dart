import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tmapp/providers/service_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/weather_card.dart';
import '../widgets/task_weather_badge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ARCHITECTURE: ScrollController manages infinite list loading,
  // while _searchController handles user input for filtering.
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // STATE MANAGEMENT: We use _filter to track the current dropdown selection locally,
  // and pass it to Riverpod to handle the actual logic.
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    // PAGINATION LOGIC:
    // This listener watches the scroll position. When the user scrolls near the bottom,
    // it automatically asks Riverpod to fetch the next batch of tasks.
    _scrollController.addListener(() {
      if (_filter == 'Bin' || _filter == 'Favorites') return; // Do not paginate for local-only filters
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(taskProvider.notifier).fetchMoreTasks();
      }
    });
    Future.microtask(() async {
      final msg = await ref.read(taskProvider.notifier).fetchTasks();
      if (msg != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.orange,
        ));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Task Manager', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF1E293B)),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const WeatherCard(city: ''), // Default city
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (val) => ref.read(taskProvider.notifier).filterTasks(val, _filter),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filter,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      items: ['All', 'Pending', 'Completed', 'Favorites', 'Bin']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f == 'All' ? 'All Tasks' : f, style: const TextStyle(fontWeight: FontWeight.w500))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _filter = val);
                          ref.read(taskProvider.notifier).filterTasks(_searchController.text, val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: taskState.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks found.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    final msg = await ref.read(taskProvider.notifier).fetchTasks();
                    if (msg != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(msg),
                        backgroundColor: Colors.orange,
                      ));
                    }
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: tasks.length + ((ref.read(taskProvider.notifier).hasMore && _filter != 'Bin' && _filter != 'Favorites') ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == tasks.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final task = tasks[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: _filter == 'Bin'
                              ? const Icon(Icons.delete_outline, color: Colors.grey)
                              : Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
                                    value: task.completed,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    activeColor: Colors.blueAccent,
                                    side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(taskProvider.notifier).updateTask(task.copyWith(completed: val));
                                      }
                                    },
                                  ),
                                ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.todo,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                    decoration: task.completed && _filter != 'Bin' ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              if (_filter != 'Bin')
                                IconButton(
                                  icon: Icon(
                                    task.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: task.isFavorite ? Colors.redAccent : Colors.grey.shade400,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    ref.read(taskProvider.notifier).updateTask(task.copyWith(isFavorite: !task.isFavorite));
                                  },
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (task.city != null && task.city!.isNotEmpty) ...[
                                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Location: ${task.city}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  if (!ref.read(localStorageServiceProvider).isTaskAddedLocally(task.id)) ...[
                                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ID: ${task.userId}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                              if (task.city != null && task.city!.isNotEmpty || ref.read(localStorageServiceProvider).isTaskAddedLocally(task.id))
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      if (task.city != null && task.city!.isNotEmpty)
                                        TaskWeatherBadge(city: task.city!),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: task.priority == 'High' ? Colors.red.withOpacity(0.1) : (task.priority == 'Medium' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: task.priority == 'High' ? Colors.red.shade300 : (task.priority == 'Medium' ? Colors.orange.shade300 : Colors.green.shade300), width: 1),
                                        ),
                                        child: Text(task.priority, style: TextStyle(fontSize: 10, color: task.priority == 'High' ? Colors.red : (task.priority == 'Medium' ? Colors.orange : Colors.green), fontWeight: FontWeight.w600)),
                                      ),
                                      if (ref.read(localStorageServiceProvider).isTaskAddedLocally(task.id))
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.blue.shade300, width: 1),
                                          ),
                                          child: Text('Added by you (ID: ${task.userId})', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600)),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: _filter == 'Bin' ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(_filter == 'Bin' ? Icons.restore : Icons.delete, color: _filter == 'Bin' ? Colors.green : Colors.redAccent, size: 20),
                              onPressed: () {
                                if (_filter == 'Bin') {
                                  ref.read(taskProvider.notifier).restoreTask(task.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task restored!')));
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Move to Bin'),
                                      content: const Text('Are you sure you want to move this task to the Bin?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () {
                                            ref.read(taskProvider.notifier).deleteTask(task.id);
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to Bin')));
                                          },
                                          child: const Text('Move', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          onTap: () => context.push('/edit-task/${task.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.offline_bolt, color: Colors.orange, size: 48),
                      const SizedBox(height: 16),
                      Text(err.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(taskProvider.notifier).fetchTasks(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-task'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
