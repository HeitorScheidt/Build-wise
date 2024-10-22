import 'package:equatable/equatable.dart';

abstract class FileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchFiles extends FileEvent {
  final String userId;
  final String projectId;

  FetchFiles(this.userId, this.projectId);
}

class UploadFile extends FileEvent {
  final String userId;
  final String projectId;
  final String filePath;
  final String fileName;

  UploadFile(this.userId, this.projectId, this.filePath, this.fileName);
}

class DeleteFile extends FileEvent {
  final String userId;
  final String projectId;
  final String fileId;
  final String fileName;

  DeleteFile(this.userId, this.projectId, this.fileId, this.fileName);
}
