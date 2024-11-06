import 'package:equatable/equatable.dart';
import 'package:build_wise/models/project_model.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

// Estado inicial do projeto
class ProjectInitial extends ProjectState {}

// Estado de carregamento de projetos
class ProjectLoading extends ProjectState {}

// Estado quando os projetos foram carregados com sucesso
class ProjectLoaded extends ProjectState {
  final List<ProjectModel> projects;

  const ProjectLoaded(this.projects);

  @override
  List<Object?> get props => [projects];
}

// Estado de verificação de CEP
class CepVerifiedState extends ProjectState {
  final bool isValid;
  final Map<String, String> addressData;

  const CepVerifiedState(this.isValid, this.addressData);

  @override
  List<Object?> get props => [isValid, addressData];
}

// Estado quando não há projetos
class ProjectEmpty extends ProjectState {}

// Add ProjectDeletedState
class ProjectDeletedState extends ProjectState {}

// Define ProjectErrorState to handle errors
class ProjectErrorState extends ProjectState {
  final String message;

  ProjectErrorState(this.message);

  @override
  List<Object> get props => [message];
}

// Estado de erro ao carregar ou criar projetos
class ProjectError extends ProjectState {
  final String message;

  const ProjectError(this.message);

  @override
  List<Object?> get props => [message];
}
