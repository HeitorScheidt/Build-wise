import 'package:build_wise/models/link_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LinkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para adicionar um link
  Future<void> addLink(
      String userId, String projectId, String roomName, String linkUrl) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('link')
        .doc(); // Gera o ID do documento

    final link = LinkModel(
      id: docRef.id, // Use o ID gerado
      roomName: roomName,
      linkUrl: linkUrl,
    );

    await docRef.set(link.toFirestore()); // Salvar no Firestore
  }

  // Método para atualizar um link
  Future<void> updateLink(String userId, String projectId, LinkModel link) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('link')
        .doc(link.id)
        .update(link.toFirestore());
  }

  // Método para excluir um link
  Future<void> deleteLink(String userId, String projectId, String linkId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('link')
        .doc(linkId)
        .delete();
  }

  // Método para buscar todos os links
  Stream<List<LinkModel>> getLinks(String userId, String projectId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('link')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LinkModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
