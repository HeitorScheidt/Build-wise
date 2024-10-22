import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/project/project_bloc.dart';
import 'package:build_wise/blocs/project/project_event.dart';
import 'package:build_wise/blocs/project/project_state.dart';
import 'package:build_wise/models/project_model.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/pages/project_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProjectPage extends StatelessWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    print("ID do usuário: $userId");

    // Função para verificar se a conta tem o campo 'role'
    Future<bool> isParentAccount(String userId) async {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Se o campo 'role' não existir, estamos lidando com uma conta pai (arquiteto)
      if (userDoc.exists && !userDoc.data()!.containsKey('role')) {
        print("Conta pai (arquiteto) detectada para o usuário: $userId");
        return true;
      }

      print(
          "Conta filha detectada (cliente ou funcionário) para o usuário: $userId");
      return false;
    }

    // Função para carregar os IDs dos projetos para uma conta filha
    Future<List<String>> loadClientProjectIds(String userId) async {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists && userDoc.data()!.containsKey('projects')) {
          List<String> projectIds = List<String>.from(userDoc['projects']);
          print("IDs dos projetos carregados para a conta filha: $projectIds");
          return projectIds;
        }

        print("Nenhum projeto encontrado para a conta filha.");
        return [];
      } catch (e) {
        print("Erro ao carregar os IDs dos projetos: $e");
        throw Exception("Erro ao carregar os IDs dos projetos: $e");
      }
    }

    // Função para carregar projetos para a conta pai (arquiteto)
    Future<List<ProjectModel>> loadParentProjects(String userId) async {
      try {
        print("Carregando projetos para a conta pai (arquiteto): $userId");
        List<ProjectModel> allProjects = [];

        final projectDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('projects')
            .get();

        for (var projectDoc in projectDocs.docs) {
          final project = ProjectModel.fromMap(
              projectDoc.id, projectDoc.data() as Map<String, dynamic>);
          allProjects.add(project);
        }

        print(
            "Total de projetos carregados para a conta pai: ${allProjects.length}");
        return allProjects;
      } catch (e) {
        print("Erro ao carregar projetos para a conta pai: $e");
        throw Exception('Erro ao carregar projetos para a conta pai: $e');
      }
    }

    // Função para carregar projetos filtrados para a conta filha
    Future<List<ProjectModel>> loadClientProjects(String userId) async {
      try {
        print(
            "Iniciando o carregamento dos projetos filtrados para a conta filha: $userId");
        List<String> clientProjectIds = await loadClientProjectIds(userId);
        List<ProjectModel> allProjects = [];

        // Carregar documentos de projetos com base nos IDs no campo 'projects'
        for (String projectId in clientProjectIds) {
          // Buscar na conta pai
          final parentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc('ID_DA_CONTA_PAI') // Substitua pelo ID correto da conta pai
              .collection('projects')
              .doc(projectId)
              .get();

          if (parentDoc.exists) {
            final project = ProjectModel.fromMap(
                parentDoc.id, parentDoc.data() as Map<String, dynamic>);
            allProjects.add(project);
          }
        }

        print(
            "Total de projetos carregados para a conta filha: ${allProjects.length}");
        return allProjects;
      } catch (e) {
        print("Erro ao carregar os projetos filtrados para a conta filha: $e");
        throw Exception('Erro ao carregar projetos para a conta filha: $e');
      }
    }

    // Função principal que decide qual lógica usar (conta pai ou conta filha)
    Future<List<ProjectModel>> loadProjects(String userId) async {
      bool isParent = await isParentAccount(userId);
      if (isParent) {
        // Se for uma conta pai, carregamos todos os projetos
        return await loadParentProjects(userId);
      } else {
        // Se for uma conta filha, carregamos os projetos filtrados
        return await loadClientProjects(userId);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            Text("Meus Projetos", style: appWidget.headerLineTextFieldStyle()),
        elevation: 0,
      ),
      body: FutureBuilder<List<ProjectModel>>(
        future: loadProjects(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("Erro ao carregar projetos: ${snapshot.error}");
            return const Center(child: Text('Erro ao carregar projetos.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print("Nenhum projeto encontrado.");
            return const Center(child: Text('Nenhum projeto encontrado.'));
          } else {
            final projects = snapshot.data!;
            print("Projetos carregados com sucesso: $projects");
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectDetails(
                        project: project, // Passando o ProjectModel
                        userId: userId,
                      ),
                    ),
                  ),
                  child: _buildProjectCard(context, project),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context, userId),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return FutureBuilder<String>(
      future: getImageUrl(project.image ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          margin: const EdgeInsets.all(10),
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    snapshot.data!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print("Erro ao carregar imagem: $error");
                      return Image.asset(
                        'assets/images/project_default_header.jpg',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(project.name ?? 'Sem nome',
                      style: appWidget.boldLineTextFieldStyle()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> getImageUrl(String imagePath) async {
    if (imagePath.isEmpty) {
      return 'assets/images/project_default_header.jpg';
    }
    try {
      print("Carregando URL da imagem: $imagePath");
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      print("Erro ao carregar URL da imagem: $e");
      return 'assets/images/project_default_header.jpg';
    }
  }

  void _showAddProjectDialog(BuildContext context, String userId) {
    TextEditingController nameController = TextEditingController();
    TextEditingController clientNameController = TextEditingController();
    TextEditingController valueController = TextEditingController();
    TextEditingController sizeController = TextEditingController();
    TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Adicionar Projeto"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(hintText: "Nome do Projeto"),
                ),
                TextField(
                  controller: clientNameController,
                  decoration:
                      const InputDecoration(hintText: "Nome do Cliente"),
                ),
                TextField(
                  controller: valueController,
                  decoration:
                      const InputDecoration(hintText: "Valor do Projeto"),
                ),
                TextField(
                  controller: sizeController,
                  decoration:
                      const InputDecoration(hintText: "Metragem Quadrada"),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(hintText: "Observações"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Adicionar"),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    clientNameController.text.isNotEmpty) {
                  print(
                      "Adicionando novo projeto com nome: ${nameController.text}");
                  ProjectModel newProject = ProjectModel(
                    id: '', // O ID será gerado automaticamente pelo Firebase
                    name: nameController.text,
                    clientName: clientNameController.text,
                    value: double.tryParse(valueController.text) ?? 0,
                    size: double.tryParse(sizeController.text) ?? 0,
                    notes: notesController.text,
                    userId: userId, // Usando o ID do usuário autenticado
                    image: '', // Imagem padrão ou lógica para adicionar imagem
                  );
                  context.read<ProjectBloc>().add(CreateProjectEvent(
                      projectData: newProject, userId: userId));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
