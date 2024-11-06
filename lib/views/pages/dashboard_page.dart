import 'package:build_wise/models/schedule_model.dart';
import 'package:build_wise/providers/user_role_provider.dart';
import 'package:build_wise/views/pages/project_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:build_wise/services/auth_service.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/helpers.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/pages/details.dart';
import 'package:build_wise/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  User? currentUser;
  String? userRole;
  bool projeto = false, tarefas = false, cronograma = false, materiais = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<String?> getUserName() async {
    if (currentUser == null) return 'Usuário Anônimo';
    return await _authService.getUserName(currentUser!.uid);
  }

  Future<void> _getCurrentUser() async {
    currentUser = FirebaseAuth.instance.currentUser;
    final roleProvider = Provider.of<UserRoleProvider>(context, listen: false);
    await roleProvider.fetchUserRole();
    setState(() {
      userRole = roleProvider.role;
    });
  }

  Stream<List<ProjectModel>> _projectStream() {
    Query query = FirebaseFirestore.instance.collection('projects');

    if (userRole == 'arquiteto') {
      query = query.where('architectId', isEqualTo: currentUser?.uid);
    } else if (userRole == 'Cliente') {
      query = query.where('clients', arrayContains: currentUser?.uid);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<List<ScheduleEntry>> _tasksStream(String priority) {
    if (currentUser == null) return Stream.empty();

    Query<Map<String, dynamic>> taskCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('cronograma');

    if (userRole == 'arquiteto') {
      taskCollection = FirebaseFirestore.instance
          .collection('tasks')
          .where('architectId', isEqualTo: currentUser?.uid);
    } else if (userRole == 'Cliente') {
      taskCollection = FirebaseFirestore.instance
          .collection('tasks')
          .where('clients', arrayContains: currentUser?.uid);
    }

    return taskCollection
        .where('priority', isEqualTo: priority)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScheduleEntry.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<void>(
        future: _getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return FutureBuilder<String?>(
              future: getUserName(),
              builder: (context, userNameSnapshot) {
                if (userNameSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  String userName = userNameSnapshot.data ?? 'Usuário Anônimo';
                  String greetingMessage =
                      AppHelpers.getGreetingMessage(userName);

                  return Container(
                    margin: const EdgeInsets.only(top: 40.0, left: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              greetingMessage,
                              style: appWidget.boldLineTextFieldStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text("Dashboard,",
                            style: appWidget.headerLineTextFieldStyle()),
                        Text("Gerencie Seus Projetos Rapidamente,",
                            style: appWidget.lightTextFieldStyle()),
                        const SizedBox(height: 20.0),
                        Container(margin: const EdgeInsets.only(right: 16.0)),
                        const SizedBox(height: 24.0),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: StreamBuilder<List<ProjectModel>>(
                            stream: _projectStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                print(
                                    "Erro ao carregar projetos: ${snapshot.error}");
                                return const Center(
                                    child: Text('Erro ao carregar projetos.'));
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Crie seu Primeiro projeto.',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              } else {
                                final projects =
                                    snapshot.data!.take(3).toList();
                                return Row(
                                  children: projects.map((project) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProjectDetails(
                                                    project: project),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Image.network(
                                                project.headerImageUrl ??
                                                    "assets/images/project_default_header.jpg",
                                                height: 200,
                                                width: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/project_default_header.jpg',
                                                    height: 200,
                                                    width: 200,
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    project.name ?? 'Sem nome',
                                                    style: appWidget
                                                        .semiBooldTextFieldStyle(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPriorityTaskStream(),
                      ],
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildPriorityTaskStream() {
    return StreamBuilder<List<ScheduleEntry>>(
      stream: _tasksStream('Urgent'),
      builder: (context, urgentSnapshot) {
        if (urgentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (urgentSnapshot.hasData && urgentSnapshot.data!.isNotEmpty) {
          return _buildTaskList(urgentSnapshot.data!.take(3).toList());
        } else {
          return StreamBuilder<List<ScheduleEntry>>(
            stream: _tasksStream('High'),
            builder: (context, highSnapshot) {
              if (highSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (highSnapshot.hasData &&
                  highSnapshot.data!.isNotEmpty) {
                List<ScheduleEntry> combinedTasks = [
                  ...urgentSnapshot.data!,
                  ...highSnapshot.data!
                ].take(3).toList();
                return _buildTaskList(combinedTasks);
              } else {
                return StreamBuilder<List<ScheduleEntry>>(
                  stream: _tasksStream('Normal'),
                  builder: (context, normalSnapshot) {
                    if (normalSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (normalSnapshot.hasData &&
                        normalSnapshot.data!.isNotEmpty) {
                      List<ScheduleEntry> combinedTasks = [
                        ...urgentSnapshot.data!,
                        ...highSnapshot.data!,
                        ...normalSnapshot.data!
                      ].take(3).toList();
                      return _buildTaskList(combinedTasks);
                    } else {
                      return const Center(
                        child: Text('Nenhuma tarefa encontrada.'),
                      );
                    }
                  },
                );
              }
            },
          );
        }
      },
    );
  }

  Widget _buildTaskList(List<ScheduleEntry> tasks) {
    return Column(
      children: tasks.map((task) {
        return Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 10.0), // Espaço entre cada tarefa
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: Image.asset(
                    "assets/images/teste.jpg",
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: appWidget.semiBooldTextFieldStyle(),
                    ),
                    Text(
                      task.responsible,
                      style: appWidget.lightTextFieldStyle(),
                    ),
                    Text(
                      "${DateFormat('dd/MM/yy HH:mm').format(task.startDateTime)} - ${DateFormat('dd/MM/yy HH:mm').format(task.endDateTime)}",
                      style: appWidget.lightTextFieldStyle(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
