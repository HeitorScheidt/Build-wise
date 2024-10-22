import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/project_file.dart';

class FileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadFile(
      String userId, String projectId, String filePath, String fileName) async {
    final ref = _storage
        .ref()
        .child('user/$userId/projects/$projectId/projectFiles/$fileName');
    final uploadTask = await ref.putFile(File(filePath));
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    final fileSize = (await uploadTask.ref.getMetadata())
        .size; // Corrigido de 'sizeBytes' para 'size'

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('projectFiles')
        .add({
      'name': fileName,
      'size': fileSize,
      'downloadUrl': downloadUrl,
    });
  }

  Future<List<ProjectFile>> fetchFiles(String userId, String projectId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('projectFiles')
        .get();

    return snapshot.docs.map((doc) {
      return ProjectFile.fromSnapshot(doc.data(), doc.id);
    }).toList();
  }

  Future<void> deleteFile(
      String userId, String projectId, String fileId, String fileName) async {
    final ref = _storage
        .ref()
        .child('user/$userId/projects/$projectId/projectFiles/$fileName');
    await ref.delete();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('projectFiles')
        .doc(fileId)
        .delete();
  }
}
