import 'package:build_wise/blocs/auth/auth_bloc.dart';
import 'package:build_wise/blocs/auth/auth_event.dart';
import 'package:build_wise/blocs/member/add_member_bloc.dart';
import 'package:build_wise/blocs/member/add_member_event.dart';
import 'package:build_wise/blocs/member/add_member_state.dart';
import 'package:build_wise/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddMemberForm extends StatefulWidget {
  final String userId;

  AddMemberForm({required this.userId});

  @override
  _AddMemberFormState createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<AddMemberForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController numeroController = TextEditingController();

  List<String> selectedProjectIds = [];
  bool isClient = false;
  String? selectedRole;
  List<Map<String, dynamic>> projects = [];
  String? selectedProject;

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
  }

  Future<void> _loadUserProjects() async {
    try {
      print("Buscando projetos para o userId: ${widget.userId}");
      // Obtém apenas os projetos onde o architectId corresponde ao userId do usuário logado
      final fetchedProjects =
          await UserService().fetchUserProjectsByArchitectId(widget.userId);

      if (mounted) {
        setState(() {
          projects = fetchedProjects;
        });
        print("Projetos carregados: $fetchedProjects");
      }
    } catch (e) {
      print("Erro ao carregar projetos: $e");
    }
  }

  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    lastNameController.clear();
    cepController.clear();
    numeroController.clear();
    selectedProjectIds.clear();
    selectedRole = null;
    isClient = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddMemberBloc(UserService()),
      child: BlocListener<AddMemberBloc, AddMemberState>(
        listener: (context, state) async {
          if (state.isSuccess && !state.isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Usuário criado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            _clearFields();
            _loadUserProjects(); // Recarregar projetos

            // Realiza o logout após criar o novo membro
            BlocProvider.of<AuthBloc>(context).add(AuthLogoutRequested());

            // Redireciona para a página de login
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', (Route<dynamic> route) => false);
          } else if (state.errorMessage != null && !state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao criar usuário: ${state.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<AddMemberBloc, AddMemberState>(
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                child: AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  content: Container(
                    width: 350,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(labelText: 'Email'),
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(labelText: 'Senha'),
                          obscureText: true,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: 'Nome'),
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: lastNameController,
                          decoration: InputDecoration(labelText: 'Sobrenome'),
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: cepController,
                          decoration: InputDecoration(labelText: 'CEP'),
                          onChanged: (value) {
                            if (value.length == 8) {
                              context
                                  .read<AddMemberBloc>()
                                  .add(CheckCEP(value));
                            }
                          },
                          style: TextStyle(fontSize: 16),
                        ),
                        if (state.cepValid)
                          Column(
                            children: [
                              SizedBox(height: 16),
                              TextField(
                                decoration: InputDecoration(labelText: 'Rua'),
                                controller: TextEditingController(
                                    text: state.address ?? ''),
                                enabled: false,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 16),
                              TextField(
                                decoration:
                                    InputDecoration(labelText: 'Bairro'),
                                controller: TextEditingController(
                                    text: state.bairro ?? ''),
                                enabled: false,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 16),
                              TextField(
                                decoration:
                                    InputDecoration(labelText: 'Logradouro'),
                                controller: TextEditingController(
                                    text: state.logradouro ?? ''),
                                enabled: false,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 16),
                              TextField(
                                controller: numeroController,
                                decoration:
                                    InputDecoration(labelText: 'Número'),
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 16),
                              TextField(
                                decoration:
                                    InputDecoration(labelText: 'Cidade'),
                                controller: TextEditingController(
                                    text: state.cidade ?? ''),
                                enabled: false,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        SizedBox(height: 16),
                        DropdownButton<String>(
                          hint: Text('Selecione o tipo de membro'),
                          value: selectedRole,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                                value: 'Cliente',
                                child: Container(
                                  child: Text('Cliente'),
                                  color: Colors.white,
                                )),
                            /*DropdownMenuItem(
                                value: 'Funcionário',
                                child: Text('Funcionário')),*/
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                              isClient = (value == 'Cliente');
                            });
                          },
                        ),
                        if (isClient && projects.isNotEmpty)
                          Column(
                            children: [
                              SizedBox(height: 16),
                              DropdownButton<String>(
                                hint: Text('Selecione um projeto'),
                                dropdownColor: Colors.white,
                                value: selectedProject,
                                isExpanded: true,
                                items: projects.map((project) {
                                  return DropdownMenuItem<String>(
                                    value: project['id'],
                                    child: Text(project['name']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedProject = value;
                                    if (value != null &&
                                        !selectedProjectIds.contains(value)) {
                                      selectedProjectIds.add(value);
                                    }
                                  });
                                  print(
                                      "Projetos Selecionados: $selectedProjectIds");
                                },
                              ),
                              SizedBox(height: 16),
                              if (selectedProjectIds.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Projetos Selecionados:'),
                                    for (String projectId in selectedProjectIds)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                projects.firstWhere((project) =>
                                                    project['id'] ==
                                                    projectId)['name'],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.close),
                                              onPressed: () {
                                                setState(() {
                                                  selectedProjectIds
                                                      .remove(projectId);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        if (isClient && projects.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('Nenhum projeto encontrado.'),
                          ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<AddMemberBloc>().add(AddMemberSubmit(
                                  email: emailController.text,
                                  password: passwordController.text,
                                  name: nameController.text,
                                  lastName: lastNameController.text,
                                  cep: cepController.text,
                                  isClient: isClient,
                                  projectIds: selectedProjectIds,
                                  userId: widget.userId,
                                  address: state.address,
                                  bairro: state.bairro,
                                  logradouro: state.logradouro,
                                  cidade: state.cidade,
                                  numero: numeroController.text,
                                  architectId: widget.userId,
                                  role: selectedRole ?? 'Cliente',
                                ));
                          },
                          child: Text('Criar conta',
                              style: TextStyle(fontSize: 16)),
                        ),
                        if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(state.errorMessage!,
                                style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
