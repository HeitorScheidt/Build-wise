import 'package:build_wise/blocs/project/project_bloc.dart';
import 'package:build_wise/blocs/project/project_event.dart';
import 'package:build_wise/models/project_model.dart';
import 'package:build_wise/providers/user_role_provider.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/pages/project_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  String? userRole;
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<String> projectIds = [];
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    final roleProvider = Provider.of<UserRoleProvider>(context, listen: false);
    await roleProvider.fetchUserRole();

    setState(() {
      userRole = roleProvider.role;
      projectIds = roleProvider.projectIds ?? [];
      isInitialized = true;
    });
  }

  Stream<List<ProjectModel>> _projectStream() {
    Query query = FirebaseFirestore.instance.collection('projects');

    if (userRole == 'arquiteto') {
      query = query.where('architectId', isEqualTo: currentUserId);
    } else if (userRole == 'Cliente') {
      query = query.where('clients', arrayContains: currentUserId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  String formatCurrency(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return 'R\$ 0,00';

    double parsedValue = double.tryParse(digitsOnly) ?? 0;
    parsedValue /= 100;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(parsedValue);
  }

  String formatSquareMeters(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return '0 m²';

    double parsedValue = double.tryParse(digitsOnly) ?? 0;
    return '${parsedValue.toStringAsFixed(0)} m²';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            Text("Meus Projetos", style: appWidget.headerLineTextFieldStyle()),
        elevation: 0,
      ),
      body: isInitialized
          ? StreamBuilder<List<ProjectModel>>(
              stream: _projectStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print("Erro ao carregar projetos: ${snapshot.error}");
                  return const Center(
                      child: Text('Erro ao carregar projetos.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nenhum projeto encontrado.'));
                } else {
                  final projects = snapshot.data!;
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProjectDetails(project: project),
                          ),
                        ),
                        child: _buildProjectCard(context, project),
                      );
                    },
                  );
                }
              },
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: userRole != 'cliente'
          ? FloatingActionButton(
              onPressed: () => _showAddProjectDialog(context, currentUserId),
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            )
          : null,
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    print(project.name);
    return FutureBuilder<String>(
      future: getImageUrl(project.headerImageUrl ?? ''),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.white,
            elevation: 5.0,
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          color: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              snapshot.data!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/project_default_header.jpg',
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _deleteProject(context, project),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          width: double
                              .infinity, // Garante que o container ocupa o máximo de largura disponível
                          alignment: Alignment
                              .center, // Centraliza o texto no container
                          color: Colors.white,
                          child: Text(
                            project.name ?? 'Sem nome',
                            style: appWidget.boldLineTextFieldStyle(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1, // Limita o texto a uma linha
                            textAlign: TextAlign.center, // Centraliza o texto
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> getImageUrl(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      print("Carregando imagem do projeto a partir de URL: $imageUrl");
      return imageUrl;
    } else {
      print("URL vazia, carregando imagem padrão.");
      return 'assets/images/project_default_header.jpg';
    }
  }

  void _showAddProjectDialog(BuildContext context, String architectId) {
    TextEditingController nameController = TextEditingController();
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
                  controller: valueController,
                  decoration:
                      const InputDecoration(hintText: "Valor do Projeto (R\$)"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    valueController.text = formatCurrency(value);
                    valueController.selection = TextSelection.fromPosition(
                      TextPosition(offset: valueController.text.length),
                    );
                  },
                ),
                TextField(
                  controller: sizeController,
                  decoration:
                      const InputDecoration(hintText: "Metragem Quadrada (m²)"),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    sizeController.text = formatSquareMeters(value);
                    sizeController.selection = TextSelection.fromPosition(
                      TextPosition(offset: sizeController.text.length),
                    );
                  },
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Adicionar"),
              onPressed: () {
                double? value = double.tryParse(
                    valueController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
                double? size = double.tryParse(
                    sizeController.text.replaceAll(RegExp(r'[^0-9.]'), ''));

                if (nameController.text.isNotEmpty &&
                    value != null &&
                    value > 0 &&
                    size != null &&
                    size > 0) {
                  ProjectModel newProject = ProjectModel(
                    id: '',
                    architectId: architectId,
                    name: nameController.text,
                    value: value,
                    size: size,
                    notes: notesController.text,
                    headerImageUrl: '',
                    employees: [],
                    clients: [],
                  );
                  context
                      .read<ProjectBloc>()
                      .add(CreateProjectEvent(projectData: newProject));
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Preencha todos os campos corretamente')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteProject(BuildContext context, ProjectModel project) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Excluir Projeto"),
          content:
              const Text("Tem certeza de que deseja excluir este projeto?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Excluir"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      FirebaseFirestore.instance
          .collection('projects')
          .doc(project.id)
          .delete();
      context
          .read<ProjectBloc>()
          .add(DeleteProjectEvent(projectId: project.id));
    }
  }
}
