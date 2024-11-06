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

class LoadProjectsByArchitectEvent extends ProjectEvent {
  final String architectId;

  LoadProjectsByArchitectEvent(this.architectId);
}

class DeleteProjectEvent extends ProjectEvent {
  final String projectId;

  const DeleteProjectEvent({required this.projectId});

  @override
  List<Object> get props => [projectId]; // Ensure List<Object> type
}

class VerifyCepEvent extends ProjectEvent {
  final String cep;

  const VerifyCepEvent(this.cep);

  @override
  List<Object> get props => [cep];
}

class CreateProjectEvent extends ProjectEvent {
  final ProjectModel projectData;

  const CreateProjectEvent({required this.projectData});

  @override
  List<Object> get props => [projectData];
}
