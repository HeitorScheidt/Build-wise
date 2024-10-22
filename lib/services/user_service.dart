import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Criação de usuário e salvamento diretamente em /Users/${userID}
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String lastName,
    required String cep,
    required bool isClient,
    List<String>? projectIds, // Lista de IDs de projetos (para clientes)
    String? address, // Campos de endereço
    String? bairro,
    String? logradouro,
    String? cidade,
    String? numero,
  }) async {
    try {
      // Obtém o ID do arquiteto (usuário logado)
      String architectId = _auth.currentUser!.uid;

      print("Iniciando a criação do usuário...");

      // Verifica se o email já existe e se a senha é forte o suficiente
      if (email.isEmpty || password.length < 6) {
        throw Exception(
            "O e-mail está vazio ou a senha é fraca (menos de 6 caracteres).");
      }

      try {
        // Criação do usuário no Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String newUserId = userCredential.user!.uid;

        print("Usuário criado com sucesso: $newUserId");

        // Dados principais do membro a serem salvos diretamente em /Users/${userID}
        Map<String, dynamic> memberData = {
          'name': name,
          'lastName': lastName,
          'email': email,
          'cep': cep,
          'address': address,
          'bairro': bairro,
          'logradouro': logradouro,
          'cidade': cidade,
          'numero': numero,
          'role': isClient ? 'Cliente' : 'Funcionário', // Define o papel
          'projects': projectIds ?? [], // Salvar lista de projetos, se existir
          'arquitetoID': architectId, // ID do arquiteto (usuário logado)
        };

        // Salvar o usuário diretamente na coleção /Users/${newUserId}
        await _firestore
            .collection('users')
            .doc(newUserId) // Salva diretamente em /Users/${newUserId}
            .set(memberData);

        print("Dados do usuário salvos no Firestore");

        // Se for um cliente, salva também na subcoleção 'clients' de cada projeto
        if (isClient && projectIds != null && projectIds.isNotEmpty) {
          await Future.wait(projectIds.map((projectId) async {
            return _firestore
                .collection('users')
                .doc(architectId) // Usa o ID do arquiteto
                .collection('projects')
                .doc(projectId)
                .collection('clients')
                .doc(newUserId)
                .set(memberData);
          }));
          print("Cliente salvo nos projetos selecionados.");
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw Exception('Este e-mail já está em uso.');
        } else if (e.code == 'weak-password') {
          throw Exception('A senha é muito fraca.');
        } else {
          throw Exception(
              'Erro ao criar usuário no Firebase Auth: ${e.message}');
        }
      }
    } catch (e) {
      // Tratar erros de forma adequada
      print('Erro ao criar usuário ou salvar dados: $e');
      throw Exception('Erro ao criar usuário ou salvar dados.');
    }
  }

  // Função para buscar nomes de projetos do Firestore em /Users/${userId}/projects
  Future<List<Map<String, dynamic>>> fetchUserProjects(String userId) async {
    // Verifica se o userId está correto e se os projetos estão presentes no Firestore
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .get();

    // Se a lista de projetos for vazia, exibe uma mensagem de aviso
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

  // Verificação do CEP usando a API ViaCEP
  Future<Map<String, String>> verifyCEP(String cep) async {
    final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('erro')) {
        throw Exception('CEP inválido');
      }

      return {
        'rua': data['logradouro'] ?? '', // Logradouro correto para rua
        'bairro': data['bairro'] ?? '',
        'logradouro': data['logradouro'] ?? '', // Corrigido para rua
        'cidade': data['localidade'] ?? '', // Localidade correta para cidade
        'uf': data['uf'] ?? '',
      };
    } else {
      throw Exception('Falha ao buscar o CEP');
    }
  }

  // Função para recarregar projetos após criação do cliente
  Future<void> reloadProjects(String userId) async {
    await fetchUserProjects(userId);
  }
}
