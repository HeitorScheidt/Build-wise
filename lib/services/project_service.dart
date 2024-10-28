import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ajuste do método createProject para apenas um argumento
  Future<void> createProject(ProjectModel project) async {
    try {
      await _firestore.collection('projects').add(project.toMap());
    } catch (e) {
      throw Exception('Erro ao criar projeto: $e');
    }
  }

  Future<List<ProjectModel>> getProjectsByArchitectId(
      String architectId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('architectId', isEqualTo: architectId)
        .get();

    return snapshot.docs
        .map((doc) =>
            ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProjectModel>> getProjectsByClientOrArchitect(
      String userId, String role) async {
    Query query = _firestore.collection('projects');

    if (role == 'arquiteto') {
      query = query.where('architectId', isEqualTo: userId);
    } else if (role == 'cliente') {
      query = query.where('clients', arrayContains: userId);
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs
        .map((doc) =>
            ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Obter todos os projetos por ID do usuário
  Future<List<ProjectModel>> getProjects() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('projects').get();

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

  // Novo método para carregar projetos em tempo real com base no papel do usuário
  Stream<List<ProjectModel>> getProjectsStreamForUser(
      List<String> projectIds) async* {
    yield* _firestore
        .collection('projects')
        .where(FieldPath.documentId, whereIn: projectIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Atualizar um projeto existente
  Future<void> updateProject(String projectId, ProjectModel project) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .update(project.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar projeto: $e');
    }
  }

  // Obter um projeto por ID
  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('projects').doc(projectId).get();
      if (doc.exists) {
        return ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao obter projeto: $e');
    }
  }

  // Deletar um projeto
  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar projeto: $e');
    }
  }

  // Obter todos os projetos em tempo real
  Stream<List<ProjectModel>> getAllProjects() {
    return _firestore.collection('projects').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Função para listar projetos de um cliente
  Future<List<QueryDocumentSnapshot>> getClientProjects(String clientId) async {
    QuerySnapshot projectsSnapshot = await _firestore
        .collection('projects')
        .where('clients', arrayContains: clientId)
        .get();
    return projectsSnapshot.docs;
  }

  // Função para listar projetos de um funcionário
  Future<List<QueryDocumentSnapshot>> getEmployeeProjects(
      String employeeId) async {
    QuerySnapshot projectsSnapshot = await _firestore
        .collection('projects')
        .where('employees', arrayContains: employeeId)
        .get();
    return projectsSnapshot.docs;
  }

  // Função para buscar subcoleção 'gallery' do projeto
  Stream<QuerySnapshot> getProjectGallery(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('gallery')
        .snapshots();
  }

  // Função para buscar subcoleção 'links' do projeto
  Stream<QuerySnapshot> getProjectLinks(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('links')
        .snapshots();
  }

  // Função para buscar subcoleção 'workDiary' do projeto
  Stream<QuerySnapshot> getProjectWorkDiary(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('workDiary')
        .snapshots();
  }

  // Função para buscar subcoleção 'files' do projeto
  Stream<QuerySnapshot> getProjectFiles(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('files')
        .snapshots();
  }
}
