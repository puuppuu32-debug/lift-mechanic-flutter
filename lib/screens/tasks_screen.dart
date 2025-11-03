import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _currentFilter = 'all';

  final Map<String, String> _filterLabels = {
    'all': 'Все',
    'new': 'Новые',
    'in-progress': 'В работе',
    'completed': 'Выполненные',
    'rejected': 'Отказанные',
  };

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateTaskStatus(Task task, String newStatus) async {
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.updateTaskStatus(task.id, newStatus);
      
      String statusText = _getStatusText(newStatus);
      _showSnackBar('Задание "${task.title}" обновлено: $statusText');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new': return 'Новое';
      case 'in-progress': return 'В работе';
      case 'completed': return 'Выполнено';
      case 'rejected': return 'Отказано';
      default: return 'Неизвестно';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new': return Colors.red;
      case 'in-progress': return Colors.orange;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }

  List<Widget> _getTaskActions(Task task) {
    switch (task.status) {
      case 'new':
        return [
          ElevatedButton(
            onPressed: () => _updateTaskStatus(task, 'in-progress'),
            child: Text('Принять в работу'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
          OutlinedButton(
            onPressed: () => _showRejectDialog(task),
            child: Text('Отказаться'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
            ),
          ),
        ];
      case 'in-progress':
        return [
          ElevatedButton(
            onPressed: () => _updateTaskStatus(task, 'completed'),
            child: Text('Завершить работу'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
          OutlinedButton(
            onPressed: () => _updateTaskStatus(task, 'new'),
            child: Text('Сбросить статус'),
          ),
        ];
      case 'completed':
      case 'rejected':
        return [
          OutlinedButton(
            onPressed: () => _updateTaskStatus(task, 'new'),
            child: Text('Сбросить статус'),
          ),
        ];
      default:
        return [];
    }
  }

  void _showRejectDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Причина отказа'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Укажите причину отказа...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTaskStatus(task, 'rejected');
            },
            child: Text('Подтвердить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  bool _filterTask(Task task) {
    switch (_currentFilter) {
      case 'new': return task.status == 'new';
      case 'in-progress': return task.status == 'in-progress';
      case 'completed': return task.status == 'completed';
      case 'rejected': return task.status == 'rejected';
      default: return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Задания')),
        body: Center(child: Text('Пользователь не авторизован')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Мои задания'),
        backgroundColor: Color(0xFF667eea),
      ),
      body: Column(
        children: [
          // Фильтры
          Container(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterLabels.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: _currentFilter == entry.key,
                      onSelected: (selected) {
                        setState(() {
                          _currentFilter = entry.key;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Список заданий
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: Provider.of<FirestoreService>(context).getTasks(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
                }

                final tasks = snapshot.data ?? [];
                final filteredTasks = tasks.where(_filterTask).toList();

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          _currentFilter == 'all' 
                            ? 'Нет заданий' 
                            : 'Нет заданий с фильтром "${_filterLabels[_currentFilter]}"',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(task.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(task.status),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text('📍 Адрес: ${task.address}'),
                            SizedBox(height: 4),
                            Text('🛗 Лифт: ${task.elevator}'),
                            SizedBox(height: 4),
                            Text('📅 Срок: ${task.deadline}'),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _getTaskActions(task),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}