import 'package:equatable/equatable.dart';
import 'package:build_wise/models/project_model.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object> get props => [];
}

class LoadProjectsEvent extends ProjectEvent {
  final List<String>
      projectIds; // Carrega projetos com base em uma lista de IDs

  const LoadProjectsEvent(this.projectIds);

  @override
  List<Object> get props => [projectIds];
}

class VerifyCepEvent extends ProjectEvent {
  final String cep;

  const VerifyCepEvent(this.cep);

  @override
  List<Object> get props => [cep];
}

class CreateProjectEvent extends ProjectEvent {
  final ProjectModel projectData;
  final String userId; // ID do usuário para criar o projeto

  const CreateProjectEvent({required this.projectData, required this.userId});

  @override
  List<Object> get props => [projectData, userId];
}
