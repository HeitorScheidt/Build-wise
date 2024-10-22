import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/services/work_diary_service.dart';
import 'package:build_wise/blocs/diary/work_diary_event.dart';
import 'package:build_wise/blocs/diary/work_diary_state.dart';
import 'package:build_wise/models/work_diary_entry.dart';

class WorkDiaryBloc extends Bloc<WorkDiaryEvent, WorkDiaryState> {
  final WorkDiaryService workDiaryService;

  WorkDiaryBloc(this.workDiaryService) : super(WorkDiaryLoading()) {
    // Evento para carregar entradas
    on<LoadWorkDiaryEntriesEvent>((event, emit) async {
      try {
        final entries = await workDiaryService.loadWorkDiaryEntries(
            event.userId, event.projectId);
        if (entries.isEmpty) {
          emit(WorkDiaryEmpty());
        } else {
          emit(WorkDiaryLoaded(entries));
        }
      } catch (e) {
        print('Error loading entries: $e'); // Add this for logging
        emit(WorkDiaryError('Error loading entries: $e'));
      }
    });

    // Evento para adicionar nova entrada
    on<AddWorkDiaryEntryEvent>((event, emit) async {
      emit(
          WorkDiaryLoading()); // Carregar enquanto a nova entrada está sendo adicionada
      try {
        await workDiaryService.addWorkDiaryEntry(
            event.userId, event.projectId, event.entry);

        // Após adicionar a nova entrada, recarregar todas as entradas e emitir o estado atualizado
        final updatedEntries = await workDiaryService.loadWorkDiaryEntries(
            event.userId, event.projectId);

        emit(WorkDiaryLoaded(
            updatedEntries)); // Emitir o estado de carregamento atualizado
      } catch (e) {
        emit(WorkDiaryError('Erro ao adicionar nova entrada: ${e.toString()}'));
      }
    });
  }
}
