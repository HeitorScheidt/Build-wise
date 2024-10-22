import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/project/project_event.dart';
import 'package:build_wise/blocs/project/project_state.dart';
import 'package:build_wise/services/project_service.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectService projectService;

  ProjectBloc(this.projectService) : super(ProjectInitial()) {
    on<LoadProjectsEvent>(_onLoadProjects);
    on<CreateProjectEvent>(_onCreateProject);
  }

  // Método para carregar os projetos com base no projectIds
  Future<void> _onLoadProjects(
      LoadProjectsEvent event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    try {
      // Verifica se projectIds foram passados, se sim, use-os
      final projects = await projectService.getProjectsByIds(event.projectIds);
      if (projects.isEmpty) {
        emit(ProjectEmpty());
      } else {
        emit(ProjectLoaded(projects));
      }
    } catch (e) {
      emit(ProjectError('Erro ao carregar projetos: ${e.toString()}'));
    }
  }

  // Método para criar um projeto
  Future<void> _onCreateProject(
      CreateProjectEvent event, Emitter<ProjectState> emit) async {
    try {
      await projectService.createProject(event.projectData, event.userId);
      // Após a criação do projeto, recarregue a lista de projetos
      add(LoadProjectsEvent(
          [event.projectData.id])); // Passa o ID como uma lista
    } catch (e) {
      emit(ProjectError('Erro ao criar projeto: ${e.toString()}'));
    }
  }
}
