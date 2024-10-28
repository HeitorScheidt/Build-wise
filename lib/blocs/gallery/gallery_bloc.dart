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

        // Filtra fotos inválidas (com URL nula ou vazia)
        final validPhotos = photos
            .where((photo) => photo.url != null && photo.url.isNotEmpty)
            .toList();

        if (validPhotos.isEmpty) {
          emit(GalleryError("No valid photos available"));
        } else {
          emit(GalleryLoaded(validPhotos));
        }
      } catch (e) {
        emit(GalleryError("Error loading photos: ${e.toString()}"));
      }
    });

    // Evento para adicionar fotos
    on<AddPhoto>((event, emit) async {
      try {
        if (event.filePath.isNotEmpty) {
          await _galleryService.addPhoto(
              event.userId, event.projectId, event.filePath);
          add(LoadPhotos(event.userId,
              event.projectId)); // Recarrega as fotos após adicionar
        } else {
          emit(GalleryError("Invalid file path provided"));
        }
      } catch (e) {
        emit(GalleryError("Error adding photo: ${e.toString()}"));
      }
    });

    // Evento para deletar fotos
    on<DeletePhoto>((event, emit) async {
      try {
        if (event.photoUrl.isNotEmpty) {
          await _galleryService.deletePhoto(
              event.userId, event.projectId, event.photoId, event.photoUrl);
          add(LoadPhotos(event.userId,
              event.projectId)); // Recarrega as fotos após exclusão
        } else {
          emit(GalleryError("Invalid photo URL for deletion"));
        }
      } catch (e) {
        emit(GalleryError("Failed to delete photo: ${e.toString()}"));
      }
    });
  }
}
