import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:meu_app/DataBase.dart';
import 'package:meu_app/reminder.dart';

class TaskCreateScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? taskToEdit;

  const TaskCreateScreen({
    super.key,
    required this.userId,
    this.taskToEdit,
  });

  @override
  _TaskCreateScreenState createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _reminderEnabled = false;
  DateTime? _reminderDateTime;
  int? _selectedTagId;
  Color _selectedTagColor = Colors.grey;
  List<Map<String, dynamic>> _tags = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchTags();
    if (widget.taskToEdit != null) {
      _loadTaskData(widget.taskToEdit!);
    }
  }

  void _loadTaskData(Map<String, dynamic> task) {
    _nameController.text = task['name'];
    _descriptionController.text = task['description'] ?? '';
    _reminderEnabled = task['reminder'] == 1;
    _reminderDateTime = DateTime.tryParse(task['reminder_datetime']);
    _selectedTagId = task['tag_id'];
    _selectedTagColor = _getColorFromHex(task['tag_color'].toString());
  }

  Future<void> _fetchTags() async {
    final db = await DB.instance.database;
    final result = await db.query('tags');
    setState(() {
      _tags = result;
      if (_tags.isNotEmpty) {
        final defaultTag = _tags.firstWhere(
              (tag) => tag['name'] == 'None',
          orElse: () => _tags.first,
        );
        _selectedTagId ??= defaultTag['id'];
        _selectedTagColor = _getColorFromHex(defaultTag['color'].toString());
      }
    });
  }
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final task = {
      'user_id': widget.userId,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'complete': 0,
      'reminder': _reminderEnabled ? 1 : 0,
      'reminder_datetime': _reminderDateTime?.toIso8601String() ?? "",
      'tag_id': _selectedTagId ?? 1,
      'tag_color': _selectedTagColor.value.toRadixString(16).padLeft(8, '0'),
    };

    try {
      int taskId;

      if (widget.taskToEdit != null) {
        await DB.instance.updateTask(widget.taskToEdit!['id'], task);
        taskId = widget.taskToEdit!['id'];
      } else {
        taskId = await DB.instance.insertTask(task);
      }

      // Configurar ou cancelar lembrete com base no estado
      if (_reminderEnabled && _reminderDateTime != null) {
        await ReminderService.scheduleReminder(
          id: taskId,
          title: "Lembrete: ${task['name'] ?? 'Tarefa sem nome'}",
          body: (task['description'] is String && (task['description'] as String).isNotEmpty)
              ? task['description'] as String
              : 'Você tem uma tarefa!',
          scheduledTime: _reminderDateTime!,
        );
      } else {
        await ReminderService.cancelReminder(taskId);
      }


      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar a tarefa: $e')),
      );
    }
  }


  Future<void> _deleteTask() async {
    if (widget.taskToEdit != null) {
      await DB.instance.deleteTask(widget.taskToEdit!['id']);
      Navigator.pop(context, true);
    }
  }

  void _pickReminderDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _reminderDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _createNewTag() {
    final TextEditingController tagNameController = TextEditingController();
    Color pickedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Nova Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tagNameController,
                  decoration: const InputDecoration(labelText: 'Nome da Tag'),
                ),
                const SizedBox(height: 10),
                ColorPicker(
                  pickerColor: pickedColor,
                  onColorChanged: (color) {
                    setState(() {
                      pickedColor = color;
                    });
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (tagNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('O nome da tag é obrigatório!')),
                  );
                  return;
                }

                final newTag = {
                  'name': tagNameController.text.trim(),
                  'color': pickedColor.value.toRadixString(16).padLeft(8, '0'),
                };

                await DB.instance.insertTag(newTag);
                _fetchTags();
                Navigator.of(context).pop();
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  Color _getColorFromHex(String colorString) {
    return Color(int.parse(colorString, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit != null ? 'Editar Tarefa' : 'Criar Tarefa'),
        actions: widget.taskToEdit != null
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTask,
          ),
        ]
            : [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Tarefa'),
                maxLength: 25,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome'
                    : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Ativar lembrete'),
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
              ),
              if (_reminderEnabled)
                TextButton.icon(
                  onPressed: _pickReminderDateTime,
                  icon: const Icon(Icons.alarm),
                  label: Text(
                    _reminderDateTime == null
                        ? 'Escolha data e hora'
                        : DateFormat('dd/MM/yyyy HH:mm').format(_reminderDateTime!),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Categoria',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedTagId,
                      hint: const Text('Selecione uma tag'),
                      items: _tags.map((tag) {
                        return DropdownMenuItem<int>(
                          value: tag['id'],
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                color: Color(
                                  int.parse(tag['color'].toString(), radix: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(tag['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTagId = newValue;
                          final selectedTag = _tags.firstWhere(
                                (tag) => tag['id'] == newValue,
                            orElse: () => {'color': '0xFFFFFF'},
                          );
                          _selectedTagColor = _getColorFromHex(selectedTag['color'].toString());
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _createNewTag,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTask,
                child: Text(widget.taskToEdit != null ? 'Salvar' : 'Criar Tarefa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
