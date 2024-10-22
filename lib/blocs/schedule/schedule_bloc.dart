import 'package:build_wise/services/schedule_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleService _scheduleService;

  ScheduleBloc(this._scheduleService) : super(ScheduleLoading()) {
    // Handler para carregar as entradas do cronograma
    on<LoadScheduleEntries>((event, emit) async {
      emit(ScheduleLoading()); // Estado de carregamento
      try {
        // Chamando o método correto para carregar as entradas do cronograma
        final entries =
            await _scheduleService.loadScheduleEntries(event.userId);
        emit(ScheduleLoaded(entries)); // Estado de sucesso com as entradas
      } catch (e) {
        emit(ScheduleError("Erro ao carregar as tarefas: ${e.toString()}"));
      }
    });

    // Handler para adicionar uma nova entrada
    on<AddScheduleEntry>((event, emit) async {
      try {
        await _scheduleService.addScheduleEntry(event.userId, event.entry);
        // Recarregar as entradas após adicionar uma nova tarefa
        add(LoadScheduleEntries(event.userId));
        // Emitir mensagem de sucesso ao adicionar uma nova entrada
        emit(ScheduleSuccess("Tarefa criada com sucesso!"));
      } catch (e) {
        emit(ScheduleError("Erro ao adicionar a tarefa: ${e.toString()}"));
      }
    });

    // Handler para deletar uma entrada existente
    on<DeleteScheduleEntry>((event, emit) async {
      try {
        await _scheduleService.deleteScheduleEntry(event.userId, event.entryId);
        // Recarregar as entradas após deletar a tarefa
        add(LoadScheduleEntries(event.userId));
        emit(ScheduleSuccess("Tarefa deletada com sucesso!"));
      } catch (e) {
        emit(ScheduleError("Erro ao deletar a tarefa: ${e.toString()}"));
      }
    });

    // Handler para atualizar uma entrada existente
    on<UpdateScheduleEntry>((event, emit) async {
      try {
        await _scheduleService.updateScheduleEntry(event.userId, event.entry);
        // Recarregar as entradas após a atualização
        add(LoadScheduleEntries(event.userId));
        emit(ScheduleSuccess("Tarefa atualizada com sucesso!"));
      } catch (e) {
        emit(ScheduleError("Erro ao atualizar a tarefa: ${e.toString()}"));
      }
    });
  }
}
