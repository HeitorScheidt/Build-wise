import 'package:build_wise/models/schedule_model.dart';

abstract class ScheduleState {}

class ScheduleLoading extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final List<ScheduleEntry> entries;

  ScheduleLoaded(this.entries);
}

class ScheduleError extends ScheduleState {
  final String message;

  ScheduleError(this.message);
}

// Novo estado para indicar sucesso em uma ação
class ScheduleSuccess extends ScheduleState {
  final String message;

  ScheduleSuccess(this.message);
}
