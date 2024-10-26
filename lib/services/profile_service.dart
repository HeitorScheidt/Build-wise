import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  // Verifica se o usuário possui uma role
  Future<String?> getUserRole() async {
    if (user == null) {
      print("Usuário não autenticado.");
      return null;
    }

    try {
      // Verifica a role diretamente no usuário
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user!.uid).get();
      if (userSnapshot.exists && userSnapshot.data() != null) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        return userData.containsKey('role') ? userData['role'] : null;
      }
    } catch (e) {
      print("Erro ao buscar a role do usuário: $e");
    }
    return null;
  }

  // Faz o upload da imagem de perfil para o usuário
  Future<void> uploadProfileImage(File imageFile) async {
    if (user == null) {
      print("Usuário não autenticado.");
      return;
    }

    String docId = 'users/${user!.uid}';

    try {
      Reference storageReference = _storage.ref().child('$docId/profileImage');
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Atualiza o caminho correto com a URL da imagem
      await _firestore.collection('users').doc(user!.uid).update({
        'profileImageUrl': downloadUrl,
      });
      print("Upload de imagem de perfil concluído.");
    } catch (e) {
      print("Erro ao fazer o upload da imagem: $e");
    }
  }

  // Busca dados do perfil do usuário
// Método simplificado de buscar dados do perfil
// profile_service.dart
  Future<Map<String, dynamic>?> fetchProfileData() async {
    User? currentUser = FirebaseAuth.instance.currentUser; // Força atualização
    if (currentUser == null) {
      print("Usuário não autenticado.");
      return null;
    }
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userSnapshot.exists) {
        return userSnapshot.data() as Map<String, dynamic>?;
      } else {
        print("Usuário não encontrado.");
      }
    } catch (e) {
      print("Erro ao carregar os dados do perfil: $e");
    }
    return null;
  }

  // Salva os dados do perfil para o usuário
  Future<void> saveProfileData(Map<String, dynamic> data) async {
    User? currentUser = FirebaseAuth
        .instance.currentUser; // Garante que o usuário esteja atualizado
    if (currentUser == null) {
      print("Usuário não autenticado.");
      return;
    }

    try {
      // Atualiza dados do usuário no Firestore
      await _firestore.collection('users').doc(currentUser.uid).update(data);
      print("Dados do usuário atualizados com sucesso.");
    } catch (e) {
      print("Erro ao salvar os dados do perfil: $e");
    }
  }

  // Método para limpar o cache de perfil (se houver implementação de cache local)
  Future<void> clearProfileCache() async {
    // Se houver um cache local, implemente a lógica para limpar
    print("Cache de perfil limpo.");
  }
}
