import 'package:equatable/equatable.dart';
import '../../models/project_file.dart';

abstract class FileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FileLoading extends FileState {}

class FileLoaded extends FileState {
  final List<ProjectFile> files;

  FileLoaded(this.files);

  @override
  List<Object?> get props => [files];
}

class FileError extends FileState {
  final String message;

  FileError(this.message);

  @override
  List<Object?> get props => [message];
}
