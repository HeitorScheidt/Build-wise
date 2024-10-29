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

// Faz o upload da imagem de perfil para o Firebase Storage e atualiza a URL no Firestore
  Future<void> uploadProfileImage(File imageFile) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("Usuário não autenticado.");
      return;
    }

    String userId = currentUser.uid;
    String storagePath = 'users/$userId/profileImage';

    try {
      // Define a referência no Firebase Storage
      print("Iniciando upload para o Storage...");
      Reference storageReference = _storage.ref().child(storagePath);

      // Realiza o upload da imagem com timeout
      UploadTask uploadTask = storageReference.putFile(
        imageFile,
        SettableMetadata(
          cacheControl: "public,max-age=300", // Cache para 5 minutos
        ),
      );

      // Timeout após 2 minutos
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          print("Timeout do upload - tentando novamente...");
          throw FirebaseException(
            plugin: 'firebase_storage',
            message:
                'O upload excedeu o tempo limite. Por favor, tente novamente.',
          );
        },
      );

      print("Upload concluído. Obtendo URL...");

      // Obtém a URL pública da imagem
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("URL da imagem obtida: $downloadUrl");

      // Atualiza o Firestore com a URL da imagem de perfil
      print("Salvando URL no Firestore...");
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': downloadUrl,
      });

      print("Upload de imagem de perfil concluído e URL salva no Firestore.");
    } catch (e) {
      print("Erro ao fazer o upload da imagem: $e");
    }
  }

  // Busca dados do perfil do usuário com verificação e criação do campo profileImageUrl
  Future<Map<String, dynamic>?> fetchProfileData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Usuário não autenticado.");
      return null;
    }

    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        // Verifica a existência do campo profileImageUrl
        if (!userData.containsKey('profileImageUrl') ||
            userData['profileImageUrl'] == null) {
          userData['profileImageUrl'] = '';
          // Atualiza o Firestore com o valor padrão para evitar erros futuros
          await _firestore.collection('users').doc(currentUser.uid).update({
            'profileImageUrl': userData['profileImageUrl'],
          });
        }

        return userData;
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
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Usuário não autenticado.");
      return;
    }

    try {
      await _firestore.collection('users').doc(currentUser.uid).update(data);
      print("Dados do usuário atualizados com sucesso.");
    } catch (e) {
      print("Erro ao salvar os dados do perfil: $e");
    }
  }

  // Método para limpar o cache de perfil (se houver implementação de cache local)
  Future<void> clearProfileCache() async {
    print("Cache de perfil limpo.");
  }
}
