import 'package:build_wise/models/photo_model.dart';

abstract class GalleryState {}

class GalleryLoading extends GalleryState {}

class GalleryLoaded extends GalleryState {
  final List<Photo> photos;

  GalleryLoaded(this.photos);
}

class GalleryError extends GalleryState {
  final String errorMessage;

  GalleryError(this.errorMessage);
}
