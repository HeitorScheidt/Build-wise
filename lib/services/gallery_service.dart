import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/photo_model.dart';

class GalleryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Photo>> getPhotos(String userId, String projectId) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gallery')
        .get();

    return snapshot.docs
        .map((doc) => Photo.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> addPhoto(
      String userId, String projectId, String filePath) async {
    try {
      final ref = _storage.ref(
          'gallery/$userId/$projectId/${DateTime.now().toIso8601String()}.jpg');
      File file = File(filePath);
      await ref.putFile(file);
      final fileUrl = await ref.getDownloadURL();

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('gallery')
          .add({'url': fileUrl});
    } catch (e) {
      throw Exception("Erro ao adicionar foto: $e");
    }
  }

  Future<void> deletePhoto(
      String userId, String projectId, String photoId, String photoUrl) async {
    try {
      if (photoUrl.isNotEmpty) {
        final ref = _storage.refFromURL(photoUrl);
        await ref.delete();
      } else {
        throw Exception("URL da foto está vazia ou inválida");
      }

      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('gallery')
          .doc(photoId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao excluir foto: $e');
    }
  }
}
