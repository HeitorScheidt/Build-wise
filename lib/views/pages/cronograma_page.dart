import 'dart:async'; // Import necessário para Timer
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/schedule/schedule_bloc.dart';
import 'package:build_wise/blocs/schedule/schedule_event.dart';
import 'package:build_wise/blocs/schedule/schedule_state.dart';
import 'package:build_wise/models/schedule_model.dart';
import 'package:intl/intl.dart';

class CronogramaPage extends StatefulWidget {
  final String userId;

  CronogramaPage({required this.userId});

  @override
  _CronogramaPageState createState() => _CronogramaPageState();
}

class _CronogramaPageState extends State<CronogramaPage> {
  bool isListView = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<ScheduleBloc>().add(LoadScheduleEntries(widget.userId));

    // Inicia o timer para verificar tarefas expiradas a cada minuto
    _timer = Timer.periodic(Duration(minutes: 1), (_) {
      _checkExpiredTasks();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo da tela em branco
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Cronograma', style: appWidget.headerLineTextFieldStyle()),
        actions: [
          DropdownButton<String>(
            value: isListView ? 'List' : 'Calendar',
            items: <String>['List', 'Calendar'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                isListView = newValue == 'List';
              });
            },
          ),
        ],
      ),
      body: BlocListener<ScheduleBloc, ScheduleState>(
        listener: (context, state) {
          if (state is ScheduleSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Recarrega a lista de tarefas para atualizar a interface
            context
                .read<ScheduleBloc>()
                .add(LoadScheduleEntries(widget.userId));
          }
        },
        child: BlocBuilder<ScheduleBloc, ScheduleState>(
          builder: (context, state) {
            if (state is ScheduleLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is ScheduleLoaded) {
              final urgentTasks = state.entries
                  .where((e) =>
                      e.priority == 'Urgent' && !e.isExpired && !e.isCompleted)
                  .toList();
              final highTasks = state.entries
                  .where((e) =>
                      e.priority == 'High' && !e.isExpired && !e.isCompleted)
                  .toList();
              final normalTasks = state.entries
                  .where((e) =>
                      e.priority == 'Normal' && !e.isExpired && !e.isCompleted)
                  .toList();
              final overdueTasks = state.entries
                  .where((e) => e.isExpired && !e.isCompleted)
                  .toList();
              final completedTasks =
                  state.entries.where((e) => e.isCompleted).toList();

              return ListView(
                children: [
                  _buildTaskCategory('URGENTE', urgentTasks, Colors.red),
                  _buildTaskCategory('ALTA', highTasks, Colors.orange),
                  _buildTaskCategory('NORMAL', normalTasks, Colors.blue),
                  if (overdueTasks.isNotEmpty)
                    _buildTaskCategory('ATRASADAS', overdueTasks, Colors.grey),
                  if (completedTasks.isNotEmpty)
                    _buildTaskCategory(
                        'COMPLETAS', completedTasks, Colors.green),
                ],
              );
            } else if (state is ScheduleError) {
              return Center(child: Text(state.message));
            }
            return Container();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEntryDialog(context);
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: AppColors.primaryColor,
        shape: CircleBorder(),
      ),
    );
  }

  Widget _buildTaskCategory(
      String title, List<ScheduleEntry> tasks, Color color) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(color: color)),
      children: tasks.map((task) {
        return GestureDetector(
          onTap: () => _showEditEntryDialog(context, task),
          child: Card(
            color: Colors.white, // Fundo do container em branco
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              title: Text(task.title,
                  style:
                      appWidget.normalTextFieldStyle().copyWith(fontSize: 20)),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy HH:mm').format(task.startDateTime)} - '
                '${DateFormat('dd/MM/yyyy HH:mm').format(task.endDateTime)}\n'
                'Responsável: ${task.responsible}',
                style: appWidget.normalTextFieldStyle().copyWith(fontSize: 16),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      task.isCompleted = true;
                      context
                          .read<ScheduleBloc>()
                          .add(UpdateScheduleEntry(widget.userId, task));
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.primaryColor),
                    onPressed: () {
                      context
                          .read<ScheduleBloc>()
                          .add(DeleteScheduleEntry(widget.userId, task.id));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _checkExpiredTasks() {
    final now = DateTime.now();
    context.read<ScheduleBloc>().add(CheckExpiredTasks(widget.userId, now));
  }

  void _showAddEntryDialog(BuildContext context) {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _responsibleController = TextEditingController();
    String? _selectedPriority = 'Normal';
    DateTime? _startDateTime;
    DateTime? _endDateTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Adicionar tarefa'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Título'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Descrição'),
                    ),
                    TextField(
                      controller: _responsibleController,
                      decoration: InputDecoration(labelText: 'Responsável'),
                    ),
                    DropdownButton<String>(
                      value: _selectedPriority,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                      items: <String>['Urgent', 'High', 'Normal']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    ListTile(
                      title: Text('Data inicial'),
                      subtitle: Text(_startDateTime != null
                          ? DateFormat('dd/MM/yyyy HH:mm')
                              .format(_startDateTime!)
                          : 'Selecione a data inicial'),
                      onTap: () async {
                        final pickedDate = await _selectDateTime(context);
                        setState(() {
                          _startDateTime = pickedDate;
                        });
                      },
                    ),
                    ListTile(
                      title: Text('Data final'),
                      subtitle: Text(_endDateTime != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(_endDateTime!)
                          : 'Selecione a data final'),
                      onTap: () async {
                        final pickedDate = await _selectDateTime(context);
                        setState(() {
                          _endDateTime = pickedDate;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Salvar'),
                  onPressed: () {
                    if (_titleController.text.isNotEmpty &&
                        _responsibleController.text.isNotEmpty &&
                        _startDateTime != null &&
                        _endDateTime != null &&
                        _selectedPriority != null) {
                      final newEntry = ScheduleEntry(
                        id: '',
                        startDateTime: _startDateTime!,
                        endDateTime: _endDateTime!,
                        responsible: _responsibleController.text,
                        title: _titleController.text,
                        description: _descriptionController.text,
                        priority: _selectedPriority!,
                        isExpired: false,
                        isCompleted: false,
                      );
                      context
                          .read<ScheduleBloc>()
                          .add(AddScheduleEntry(widget.userId, newEntry));
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEntryDialog(BuildContext context, ScheduleEntry entry) {
    final _titleController = TextEditingController(text: entry.title);
    final _descriptionController =
        TextEditingController(text: entry.description);
    final _responsibleController =
        TextEditingController(text: entry.responsible);
    String? _selectedPriority = entry.priority;
    DateTime _startDateTime = entry.startDateTime;
    DateTime _endDateTime = entry.endDateTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar tarefa'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Título'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Descrição'),
                    ),
                    TextField(
                      controller: _responsibleController,
                      decoration: InputDecoration(labelText: 'Responsável'),
                    ),
                    DropdownButton<String>(
                      value: _selectedPriority,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                      items: <String>['Urgent', 'High', 'Normal']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    ListTile(
                      title: Text('Data inicial'),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm')
                          .format(_startDateTime)),
                      onTap: () async {
                        final pickedDate = await _selectDateTime(context);
                        setState(() {
                          _startDateTime = pickedDate!;
                        });
                      },
                    ),
                    ListTile(
                      title: Text('Data final'),
                      subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(_endDateTime)),
                      onTap: () async {
                        final pickedDate = await _selectDateTime(context);
                        setState(() {
                          _endDateTime = pickedDate!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Salvar'),
                  onPressed: () {
                    if (_titleController.text.isNotEmpty &&
                        _responsibleController.text.isNotEmpty &&
                        _selectedPriority != null) {
                      final updatedEntry = ScheduleEntry(
                        id: entry.id,
                        startDateTime: _startDateTime,
                        endDateTime: _endDateTime,
                        responsible: _responsibleController.text,
                        title: _titleController.text,
                        description: _descriptionController.text,
                        priority: _selectedPriority!,
                        isExpired: entry.isExpired,
                        isCompleted: entry.isCompleted,
                      );
                      context.read<ScheduleBloc>().add(
                          UpdateScheduleEntry(widget.userId, updatedEntry));
                      Navigator.of(context).pop();
                    }
                  },
                ),
                TextButton(
                  child: Text('Excluir', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    context
                        .read<ScheduleBloc>()
                        .add(DeleteScheduleEntry(widget.userId, entry.id));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
