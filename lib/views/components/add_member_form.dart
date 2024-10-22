import 'package:build_wise/blocs/member/add_member_bloc.dart';
import 'package:build_wise/blocs/member/add_member_event.dart';
import 'package:build_wise/blocs/member/add_member_state.dart';
import 'package:build_wise/services/user_service.dart';
import 'package:build_wise/views/pages/user_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      final fetchedProjects =
          await UserService().fetchUserProjects(widget.userId);

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

  // Função para adicionar membro, salvar clientsID no documento do arquiteto e enviar e-mail de verificação
  Future<void> _addMember() async {
    final String email = emailController.text;
    final String password = passwordController.text;
    final String name = nameController.text;

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // Adiciona o novo usuário na coleção 'users'
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'architectId': widget.userId, // ID do arquiteto
          'createdAt': FieldValue.serverTimestamp(),
          'role': selectedRole,
          'projects': selectedProjectIds,
        });

        // Adiciona o clientsID no documento do arquiteto
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'clientsID': FieldValue.arrayUnion([user.uid]),
        });

        // Envia o e-mail de verificação
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Usuário criado com sucesso! Um e-mail de verificação foi enviado.'),
            backgroundColor: Colors.green,
          ),
        );

        _clearFields(); // Limpa os campos após a criação

        // Fecha o AlertDialog após o envio do e-mail
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Erro ao criar usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar usuário: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddMemberBloc(UserService()),
      child: BlocListener<AddMemberBloc, AddMemberState>(
        listener: (context, state) {
          if (state.isSuccess && !state.isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Usuário criado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            _clearFields();
            _loadUserProjects(); // Recarregar projetos
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
                                value: 'Cliente', child: Text('Cliente')),
                            DropdownMenuItem(
                                value: 'Funcionário',
                                child: Text('Funcionário')),
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
                            _addMember(); // Chama a função de adicionar membro com verificação de email
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
