import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/project/project_event.dart';
import 'package:build_wise/blocs/project/project_state.dart';
import 'package:build_wise/services/project_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectService projectService;

  ProjectBloc(this.projectService) : super(ProjectInitial()) {
    on<LoadProjectsEvent>(_onLoadProjects);
    on<CreateProjectEvent>(_onCreateProject);
    on<LoadProjectsByArchitectEvent>(_onLoadProjectsByArchitect);
  }

  // Método para formatar o valor em R$**,**
  String formatCurrency(String value) {
    // Remove caracteres que não sejam números
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return 'R\$ 0,00';

    // Formatação com preenchimento da direita para esquerda
    double parsedValue = double.tryParse(digitsOnly) ?? 0;
    parsedValue /= 100; // Para ajustar os dois últimos dígitos como centavos
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(parsedValue);
  }

  // Método para formatar a metragem quadrada com m²
  String formatSquareMeters(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return '0 m²';

    double parsedValue = double.tryParse(digitsOnly) ?? 0;
    return '${parsedValue.toStringAsFixed(0)} m²';
  }

  // Método para carregar projetos pelo architectId
  Future<void> _onLoadProjectsByArchitect(
      LoadProjectsByArchitectEvent event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    try {
      // Carrega os projetos que pertencem ao architectId
      final projects =
          await projectService.getProjectsByArchitectId(event.architectId);
      if (projects.isEmpty) {
        emit(ProjectEmpty());
      } else {
        emit(ProjectLoaded(projects));
      }
    } catch (e) {
      emit(ProjectError('Erro ao carregar projetos: ${e.toString()}'));
    }
  }

  // Método para carregar os projetos com base no projectIds
  Future<void> _onLoadProjects(
      LoadProjectsEvent event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    try {
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

  // Método para criar um projeto com architectId
  Future<void> _onCreateProject(
      CreateProjectEvent event, Emitter<ProjectState> emit) async {
    try {
      // Obter o architectId do usuário logado
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Configurar o architectId no projeto
      final projectData = event.projectData.copyWith(architectId: userId);

      await projectService.createProject(projectData);

      // Recarregar a lista de projetos após a criação
      add(LoadProjectsByArchitectEvent(userId));
    } catch (e) {
      emit(ProjectError('Erro ao criar projeto: ${e.toString()}'));
    }
  }
}
