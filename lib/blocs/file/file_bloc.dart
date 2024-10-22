import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/file_service.dart';
import 'file_event.dart';
import 'file_state.dart';

class FileBloc extends Bloc<FileEvent, FileState> {
  final FileService fileService;

  FileBloc(this.fileService) : super(FileLoading()) {
    on<FetchFiles>((event, emit) async {
      emit(FileLoading());
      try {
        final files =
            await fileService.fetchFiles(event.userId, event.projectId);
        emit(FileLoaded(files));
      } catch (e) {
        emit(FileError(e.toString()));
      }
    });

    on<UploadFile>((event, emit) async {
      try {
        await fileService.uploadFile(
            event.userId, event.projectId, event.filePath, event.fileName);
        add(FetchFiles(
            event.userId, event.projectId)); // Atualiza a lista de arquivos
      } catch (e) {
        emit(FileError(e.toString()));
      }
    });

    on<DeleteFile>((event, emit) async {
      try {
        await fileService.deleteFile(
            event.userId, event.projectId, event.fileId, event.fileName);
        add(FetchFiles(
            event.userId, event.projectId)); // Atualiza a lista de arquivos
      } catch (e) {
        emit(FileError(e.toString()));
      }
    });
  }
}
