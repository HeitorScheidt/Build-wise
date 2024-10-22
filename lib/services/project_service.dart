import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Criar um novo projeto
  Future<void> createProject(ProjectModel project, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .add({
        ...project.toMap(),
        'userId': userId, // Armazena o ID do usuário
      });
    } catch (e) {
      throw Exception('Erro ao criar projeto: $e');
    }
  }

  // Obter todos os projetos por ID do usuário
  Future<List<ProjectModel>> getProjects(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .get();

      return snapshot.docs
          .map((doc) =>
              ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao obter projetos: $e');
    }
  }

  // Obter projetos com base nos projectIds (usado para clientes e funcionários)
  Future<List<ProjectModel>> getProjectsByIds(List<String> projectIds) async {
    try {
      if (projectIds.isEmpty) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('projects')
          .where(FieldPath.documentId, whereIn: projectIds)
          .get();

      return snapshot.docs
          .map((doc) =>
              ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao obter projetos por IDs: $e');
    }
  }

  // Método para lidar com clientes e funcionários
  Future<List<ProjectModel>> getProjectsForUser(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Verifica se o usuário tem o campo role e role é 'cliente'
        if (userData.containsKey('role') && userData['role'] == 'cliente') {
          // Verifica se o usuário tem o campo 'projects'
          if (userData.containsKey('projects')) {
            List<String> projectIds = List<String>.from(userData['projects']);
            return await getProjectsByIds(projectIds);
          }
        }

        // Verifica se o usuário é 'funcionario' e buscar projetos do arquiteto
        if (userData.containsKey('role') && userData['role'] == 'funcionario') {
          if (userData.containsKey('architectId')) {
            String architectId = userData['architectId'];
            return await getProjects(architectId);
          }
        }

        // Se for arquiteto, carrega os próprios projetos
        if (userData.containsKey('role') && userData['role'] == 'arquiteto') {
          return await getProjects(userId);
        }
      }

      return [];
    } catch (e) {
      throw Exception('Erro ao obter projetos para o usuário: $e');
    }
  }

  // Novo método para carregar projetos em tempo real com base no papel do usuário
  Stream<List<ProjectModel>> getProjectsStreamForUser(String userId) async* {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData.containsKey('role') && userData['role'] == 'cliente') {
        if (userData.containsKey('projects')) {
          List<String> projectIds = List<String>.from(userData['projects']);
          yield* _firestore
              .collection('projects')
              .where(FieldPath.documentId, whereIn: projectIds)
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => ProjectModel.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>))
                  .toList());
        }
      }

      if (userData.containsKey('role') && userData['role'] == 'funcionario') {
        if (userData.containsKey('architectId')) {
          String architectId = userData['architectId'];
          yield* _firestore
              .collection('users')
              .doc(architectId)
              .collection('projects')
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => ProjectModel.fromMap(
                      doc.id, doc.data() as Map<String, dynamic>))
                  .toList());
        }
      }

      if (userData.containsKey('role') && userData['role'] == 'arquiteto') {
        yield* _firestore
            .collection('users')
            .doc(userId)
            .collection('projects')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => ProjectModel.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>))
                .toList());
      }
    }
  }

  // Atualizar um projeto existente
  Future<void> updateProject(
      String userId, String projectId, ProjectModel project) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .update(project.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar projeto: $e');
    }
  }

  // Obter um projeto por ID
  Future<ProjectModel?> getProjectById(String userId, String projectId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .get();
      if (doc.exists) {
        return ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao obter projeto: $e');
    }
  }

  // Deletar um projeto
  Future<void> deleteProject(String userId, String projectId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar projeto: $e');
    }
  }

  // Obter todos os projetos em tempo real
  Stream<List<ProjectModel>> getAllProjects(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
