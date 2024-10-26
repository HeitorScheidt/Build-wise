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
  late Future<List<ProjectModel>> _projectsFuture;
  String? userRole;
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<String> projectIds = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final roleProvider = Provider.of<UserRoleProvider>(context, listen: false);
    await roleProvider.fetchUserRole();

    setState(() {
      userRole = roleProvider.role;
      projectIds = roleProvider.projectIds ?? [];
      _projectsFuture = loadProjects();
    });
  }

  Future<List<ProjectModel>> loadProjects() async {
    Query query = FirebaseFirestore.instance.collection('projects');

    if (userRole == 'arquiteto') {
      query = query.where('architectId', isEqualTo: currentUserId);
    } else if (userRole == 'cliente' && projectIds.isNotEmpty) {
      query = query.where(FieldPath.documentId, whereIn: projectIds);
    } else if (userRole == 'cliente' && projectIds.isEmpty) {
      // Caso cliente não tenha projetos associados
      return [];
    }

    QuerySnapshot projectSnapshot = await query.get();
    print("Projetos carregados: ${projectSnapshot.docs.length}");

    return projectSnapshot.docs
        .map((doc) =>
            ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  String formatCurrency(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return 'R\$ 0,00';

    double parsedValue = double.tryParse(digitsOnly) ?? 0;
    parsedValue /= 100; // Para ajustar os dois últimos dígitos como centavos
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
      body: FutureBuilder<List<ProjectModel>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("Erro ao carregar projetos: ${snapshot.error}");
            return const Center(child: Text('Erro ao carregar projetos.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum projeto encontrado.'));
          } else {
            final projects = snapshot.data!;
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
                      builder: (_) => ProjectDetails(project: project),
                    ),
                  ),
                  child: _buildProjectCard(context, project),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: userRole != 'cliente'
          ? FloatingActionButton(
              onPressed: () => _showAddProjectDialog(context, currentUserId),
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return FutureBuilder<String>(
      future: getImageUrl(project.headerImageUrl ?? ''),
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
                  child: Text(
                    project.name ?? 'Sem nome',
                    style: appWidget.boldLineTextFieldStyle(),
                  ),
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
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      print("Erro ao carregar URL da imagem: $e");
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
}
