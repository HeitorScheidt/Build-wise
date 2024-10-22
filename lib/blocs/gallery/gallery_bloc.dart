import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/gallery_service.dart';
import '../../models/photo_model.dart';
import 'gallery_event.dart';
import 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final GalleryService _galleryService;

  GalleryBloc(this._galleryService) : super(GalleryLoading()) {
    // Evento para carregar fotos
    on<LoadPhotos>((event, emit) async {
      emit(GalleryLoading());
      try {
        final photos =
            await _galleryService.getPhotos(event.userId, event.projectId);
        if (photos.isEmpty) {
          emit(GalleryError(
              "No photos available")); // Adiciona uma mensagem clara
        } else {
          emit(GalleryLoaded(photos));
        }
      } catch (e) {
        emit(GalleryError("Error loading photos: ${e.toString()}"));
      }
    });

    // Evento para adicionar fotos
    on<AddPhoto>((event, emit) async {
      try {
        await _galleryService.addPhoto(
            event.userId, event.projectId, event.filePath);
        add(LoadPhotos(event.userId,
            event.projectId)); // Recarrega as fotos após adicionar
      } catch (e) {
        emit(GalleryError("Error adding photo: ${e.toString()}"));
      }
    });

    // Evento para deletar fotos
    on<DeletePhoto>((event, emit) async {
      try {
        await _galleryService.deletePhoto(
            event.userId, event.projectId, event.photoId, event.photoUrl);
        add(LoadPhotos(
            event.userId, event.projectId)); // Recarrega as fotos após exclusão
      } catch (e) {
        emit(GalleryError("Failed to delete photo: ${e.toString()}"));
      }
    });
  }
}
