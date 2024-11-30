import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meu_app/DataBase.dart';
import 'package:meu_app/screens/task_create_screen.dart';

class MainScreen extends StatefulWidget {
  final String username;

  const MainScreen({required this.username, super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<List<Map<String, dynamic>>> _tasks;
  late Future<List<Map<String, dynamic>>> _completedTasks;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final int userId = int.tryParse(widget.username) ?? 0;

    setState(() {
      _tasks = DB.instance.getTasksByUser(userId).then(
            (tasks) => tasks.where((task) => task['complete'] == 0).toList(),
      );

      _completedTasks = DB.instance.getTasksByUser(userId).then(
            (tasks) => tasks.where((task) => task['complete'] == 1).toList(),
      );
    });
  }

  Future<void> _updateTaskStatus(int taskId, bool isCompleted) async {
    await DB.instance.updateTaskStatus(taskId, {'complete': isCompleted ? 1 : 0});
    _loadTasks();
  }

  Future<void> _editTask(Map<String, dynamic> task) async {
    final int userId = int.tryParse(widget.username) ?? 0;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskCreateScreen(
          userId: userId,
          taskToEdit: task,
        ),
      ),
    );
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas Tarefas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Em Andamento'),
              Tab(text: 'Concluídas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTaskList(_tasks, false),
            _buildTaskList(_completedTasks, true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final int userId = int.tryParse(widget.username) ?? 0;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskCreateScreen(userId: userId),
              ),
            ).then((_) {
              _loadTasks();
            });
          },
          tooltip: 'Criar Tarefa',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTaskList(Future<List<Map<String, dynamic>>> tasksFuture, bool isCompleted) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar tarefas.'));
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return const Center(child: Text('Nenhuma tarefa encontrada.'));
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskItem(task, isCompleted);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, bool isCompleted) {
    final bool hasReminder = task['reminder'] == 1 && task['reminder_datetime'] != null;

    String formattedReminderDate = '';
    if (hasReminder) {
      final DateTime reminderDate = DateTime.parse(task['reminder_datetime']);
      formattedReminderDate = DateFormat('dd/MM - HH:mm').format(reminderDate);
    }

    final Color tagColor = task['tag_color'] != null
        ? Color(int.parse(task['tag_color'].toString(), radix: 16)).withOpacity(0.3)
        : Colors.grey.withOpacity(0.3);

    return GestureDetector(
      onTap: () => _editTask(task),
      child: Dismissible(
        key: Key(task['id'].toString()),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          _updateTaskStatus(task['id'], !isCompleted);
        },
        background: Container(
          color: Colors.green,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
        ),
        child: Card(
          margin: const EdgeInsets.all(8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: tagColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task['description'] ?? 'Sem descrição',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task['tag_name'] ?? 'Sem Tag',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (hasReminder)
                            Row(
                              children: [
                                const Icon(Icons.access_alarm, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  formattedReminderDate,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => _updateTaskStatus(task['id'], !isCompleted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
