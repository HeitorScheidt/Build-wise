import 'package:build_wise/models/schedule_model.dart';

abstract class ScheduleEvent {}

// Evento para carregar as entradas do cronograma
class LoadScheduleEntries extends ScheduleEvent {
  final String userId;

  LoadScheduleEntries(this.userId);
}

// Evento para adicionar uma nova entrada no cronograma
class AddScheduleEntry extends ScheduleEvent {
  final String userId;
  final ScheduleEntry entry;

  AddScheduleEntry(this.userId, this.entry);
}

// Evento para deletar uma entrada do cronograma
class DeleteScheduleEntry extends ScheduleEvent {
  final String userId;
  final String entryId;

  DeleteScheduleEntry(this.userId, this.entryId);
}

// **Novo evento para atualizar uma entrada existente no cronograma**

class UpdateScheduleEntry extends ScheduleEvent {
  final String userId;
  final ScheduleEntry entry;

  UpdateScheduleEntry(this.userId, this.entry);
}

// Novo evento para verificar tarefas expiradas
class CheckExpiredTasks extends ScheduleEvent {
  final String userId;
  final DateTime now;

  CheckExpiredTasks(this.userId, this.now);
}
