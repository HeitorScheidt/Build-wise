import 'dart:convert';
import 'package:build_wise/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createUser(UserModel userModel) async {
    try {
      if (userModel.password == null || userModel.password!.isEmpty) {
        throw Exception("A senha é obrigatória para criar o usuário.");
      }

      // Criação do usuário no Firebase Authentication com uma senha não nula
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: userModel.password!,
      );

      User? user = userCredential.user;
      String newUserId = user!.uid;

      // Salva UserModel convertido em Map diretamente no Firestore com emailVerified como falso
      await _firestore.collection('users').doc(newUserId).set(
            userModel.toMap()..['emailVerified'] = false,
          );

      // Envia o e-mail de verificação
      await user.sendEmailVerification();

      print(
          "Usuário criado com sucesso e e-mail de verificação enviado: $newUserId");

      // Atualiza o documento do arquiteto para incluir o novo cliente ou funcionário
      if (userModel.role == 'Cliente') {
        await _firestore.collection('users').doc(userModel.architectId).update({
          'clients': FieldValue.arrayUnion(
              [newUserId]), // Adiciona ao array de clients
        });
        print("Cliente salvo no campo 'clients' do arquiteto.");

        // Adiciona o cliente na subcoleção de cada projeto relevante
        if (userModel.projectIds.isNotEmpty) {
          await Future.wait(userModel.projectIds.map((projectId) async {
            return updateProjectClients(projectId, newUserId);
          }));
        }
      } else if (userModel.role == 'Funcionário') {
        await _firestore.collection('users').doc(userModel.architectId).update({
          'employees': FieldValue.arrayUnion(
              [newUserId]), // Adiciona ao array de employees
        });
        print("Funcionário salvo no campo 'employees' do arquiteto.");

        // Adiciona o funcionário na subcoleção de cada projeto relevante
        if (userModel.projectIds.isNotEmpty) {
          await Future.wait(userModel.projectIds.map((projectId) async {
            return updateProjectEmployees(projectId, newUserId);
          }));
        }
      }

      return newUserId;
    } catch (e) {
      print('Erro ao criar usuário ou salvar dados: $e');
      throw Exception('Erro ao criar usuário ou salvar dados.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserProjectsByArchitectId(
      String architectId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('projects')
        .where('architectId', isEqualTo: architectId) // Filtra pelo architectId
        .get();

    if (snapshot.docs.isEmpty) {
      print(
          "Nenhum projeto encontrado no Firestore para o architectId $architectId.");
    }

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] ?? 'Projeto sem nome',
            })
        .toList();
  }

  Future<String?> getArchitectIdForClient() async {
    // Implementação para buscar o architectId associado ao cliente
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data()?[
        'architectId']; // Retorna o architectId armazenado no Firestore
  }

  Future<List<String>?> getProjectIdsForClient() async {
    // Implementação para buscar os projectIds associados ao cliente
    final userId = _auth.currentUser?.uid;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return List<String>.from(userDoc.data()?['projects'] ?? []);
  }

  Future<void> updateProjectEmployees(String projectId, String userId) async {
    await _firestore.collection('projects').doc(projectId).update({
      'employees': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> updateProjectClients(String projectId, String userId) async {
    await _firestore.collection('projects').doc(projectId).update({
      'clients': FieldValue.arrayUnion([userId])
    });
  }

  Future<List<Map<String, dynamic>>> fetchUserProjects(String userId) async {
    QuerySnapshot snapshot = await _firestore.collection('projects').get();

    if (snapshot.docs.isEmpty) {
      print("Nenhum projeto encontrado no Firestore para o usuário $userId.");
    }

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] ?? 'Projeto sem nome',
            })
        .toList();
  }

  Future<Map<String, String>> verifyCEP(String cep) async {
    final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('erro')) {
        throw Exception('CEP inválido');
      }

      return {
        'rua': data['logradouro'] ?? '',
        'bairro': data['bairro'] ?? '',
        'logradouro': data['logradouro'] ?? '',
        'cidade': data['localidade'] ?? '',
        'uf': data['uf'] ?? '',
      };
    } else {
      throw Exception('Falha ao buscar o CEP');
    }
  }

  Future<String?> getUserRole() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('role')) {
        return userDoc['role'];
      }
    } catch (e) {
      print("Erro ao obter o role do usuário: $e");
    }
    return null;
  }

  Future<void> reloadProjects(String userId) async {
    await fetchUserProjects(userId);
  }
}
