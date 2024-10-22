abstract class GalleryEvent {}

class LoadPhotos extends GalleryEvent {
  final String userId;
  final String projectId;

  LoadPhotos(this.userId, this.projectId);
}

class AddPhoto extends GalleryEvent {
  final String userId;
  final String projectId;
  final String filePath;

  AddPhoto(this.userId, this.projectId, this.filePath);
}

class DeletePhoto extends GalleryEvent {
  final String photoId;
  final String userId;
  final String projectId;
  final String photoUrl;

  DeletePhoto(this.photoId, this.userId, this.projectId, this.photoUrl);
}
