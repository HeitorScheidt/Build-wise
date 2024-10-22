import 'dart:io';
import 'package:build_wise/services/auth_service.dart';
import 'package:build_wise/services/profile_service.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/components/add_member_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/auth/auth_bloc.dart';
import 'package:build_wise/blocs/auth/auth_event.dart';
import 'package:build_wise/blocs/profile/profile_bloc.dart';
import 'package:build_wise/blocs/profile/profile_event.dart';
import 'package:build_wise/blocs/profile/profile_state.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final AuthService _authService = AuthService();
  User? user = FirebaseAuth.instance.currentUser;
  File? _imageFile;
  String? profileImageUrl;
  String userName = "Usuário Anônimo";
  String? role;
  List<Map<String, dynamic>> clients = [];
  List<String> availableProjects = [];

  // Controladores de nome, sobrenome, email, sexo, CPF/CNPJ e CEP
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  String? gender; // Masculino ou Feminino

  @override
  void initState() {
    super.initState();
    print("Iniciando UserProfilePage");
    _fetchProfileData();
    _loadClients();
    _loadAvailableProjects();
  }

  void _updateCurrentUser() {
    setState(() {
      user = FirebaseAuth.instance.currentUser;
      print("Usuário atualizado: ${user?.uid}");
    });
  }

  Future<void> _fetchProfileData() async {
    _updateCurrentUser();

    if (user == null) {
      print("Nenhum usuário autenticado");
      return;
    }

    print("Buscando dados de perfil para o usuário: ${user!.uid}");
    nameController.clear();
    lastNameController.clear();
    emailController.clear();
    cpfController.clear();
    cepController.clear();

    BlocProvider.of<ProfileBloc>(context)
        .add(FetchProfileData(user!.uid)); // Removido isMember
  }

  // Carrega os clientes do arquiteto, incluindo nome e sobrenome
  Future<void> _loadClients() async {
    if (user == null) {
      print("Nenhum usuário para carregar clientes");
      return;
    }

    print("Carregando clientes para o usuário: ${user!.uid}");
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (snapshot.exists && snapshot.data()!.containsKey('clientsID')) {
      List<String> clientIds = List<String>.from(snapshot['clientsID']);
      List<Map<String, dynamic>> loadedClients = [];

      for (var clientId in clientIds) {
        var clientSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(clientId)
            .get();
        if (clientSnapshot.exists) {
          loadedClients.add({
            'id': clientSnapshot.id,
            'name': clientSnapshot['name'],
            'lastName': clientSnapshot['lastName'],
            'email': clientSnapshot['email'],
            'projects': clientSnapshot['projects'] ?? [], // Lista de projetos
            'emailVerified': clientSnapshot.data()!.containsKey('emailVerified')
                ? clientSnapshot['emailVerified']
                : false,
          });
        }
      }

      print("Clientes carregados: $loadedClients");
      setState(() {
        clients = loadedClients;
      });
    } else {
      print("Nenhum cliente encontrado");
    }
  }

  // Carrega projetos disponíveis para seleção no dropdown
  Future<void> _loadAvailableProjects() async {
    if (user == null) {
      print("Nenhum usuário para carregar projetos");
      return;
    }

    print("Carregando projetos disponíveis para o usuário: ${user!.uid}");
    var projectsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('projects')
        .get();

    setState(() {
      availableProjects = projectsSnapshot.docs
          .map((doc) =>
              doc.data()['name']?.toString() ??
              'Projeto sem nome') // Lida com valores null
          .toList();
      print("Projetos carregados: $availableProjects");
    });
  }

  // Adiciona um projeto ao cliente
  Future<void> _addProjectToClient(String clientId, String projectName) async {
    print("Adicionando projeto '$projectName' ao cliente '$clientId'");
    await FirebaseFirestore.instance.collection('users').doc(clientId).update({
      'projects': FieldValue.arrayUnion([projectName])
    });
    _loadClients(); // Recarrega os clientes após adicionar o projeto
  }

  // Exclui um projeto de um cliente
  Future<void> _removeProjectFromClient(
      String clientId, String projectName) async {
    print("Removendo projeto '$projectName' do cliente '$clientId'");
    await FirebaseFirestore.instance.collection('users').doc(clientId).update({
      'projects': FieldValue.arrayRemove([projectName])
    });
    _loadClients(); // Recarrega os clientes após remover o projeto
  }

  // Deletar um cliente
  Future<void> _deleteClient(String clientId) async {
    print("Deletando cliente: $clientId");
    await FirebaseFirestore.instance.collection('users').doc(clientId).delete();
    setState(() {
      clients.removeWhere((client) => client['id'] == clientId);
    });
  }

  // Reenviar email de verificação para o cliente
  Future<void> _resendVerificationEmail(String clientId) async {
    print("Reenviando email de verificação para o cliente: $clientId");
    try {
      var clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get();
      if (clientDoc.exists) {
        String email = clientDoc['email'];
        bool emailVerified = clientDoc['emailVerified'] ?? false;

        if (emailVerified) {
          print("O e-mail já foi verificado.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('O e-mail já foi verificado.'),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          var userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: 'TEMP_PASSWORD',
          );

          User? clientUser = userCredential.user;
          if (clientUser != null && !clientUser.emailVerified) {
            await clientUser.sendEmailVerification();
            print("Email de verificação reenviado para $email");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email de verificação reenviado para $email'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao reenviar email de verificação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reenviar email de verificação.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Exibe o formulário para editar o perfil do usuário
  Future<void> _showProfileForm(Map<String, dynamic>? profileData) async {
    nameController.text = profileData?['name'] ?? '';
    lastNameController.text = profileData?['lastName'] ?? '';
    emailController.text = profileData?['email'] ?? '';
    gender = profileData?['gender'] ?? 'Masculino';
    cpfController.text = profileData?['cpf'] ?? '';
    cepController.text = profileData?['cep'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Perfil'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Sobrenome'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: ['Masculino', 'Feminino']
                      .map((label) => DropdownMenuItem(
                            child: Text(label),
                            value: label,
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      gender = value;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Sexo'),
                ),
                TextField(
                  controller: cpfController,
                  decoration: InputDecoration(labelText: 'CPF/CNPJ'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: cepController,
                  decoration: InputDecoration(labelText: 'CEP'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Map<String, dynamic> updatedData = {
                  'name': nameController.text,
                  'lastName': lastNameController.text,
                  'email': emailController.text,
                  'gender': gender,
                  'cpf': cpfController.text,
                  'cep': cepController.text,
                };
                BlocProvider.of<ProfileBloc>(context).add(SaveProfileData(
                    updatedData, user!.uid)); // Removido memberId
                Navigator.of(context).pop();
                _fetchProfileData(); // Recarrega o perfil após salvar
              },
              child: Text('Salvar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Lida com o logout do usuário
  Future<void> _handleLogout() async {
    print("Realizando logout do usuário");
    setState(() {
      userName = "Usuário Anônimo";
      profileImageUrl = null;
      role = null;
      nameController.clear();
      lastNameController.clear();
    });

    BlocProvider.of<AuthBloc>(context).add(AuthLogoutRequested());

    await Future.delayed(Duration(seconds: 2));

    await FirebaseAuth.instance.signOut().then((_) {
      setState(() {
        user = null;
      });
      print("Usuário deslogado com sucesso");
    });

    BlocProvider.of<ProfileBloc>(context).add(ClearProfileData());

    Navigator.of(context)
        .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      BlocProvider.of<ProfileBloc>(context)
          .add(UploadProfileImage(_imageFile!, user!.uid)); // Removido memberId
      _fetchProfileData(); // Recarrega o perfil após alterar a foto
    }
  }

  Future<void> _showClientDetails(Map<String, dynamic> client) async {
    String? selectedProject;
    List<String> projectNames = [];

    // Carrega os nomes dos projetos já associados ao cliente
    for (var projectId in client['projects']) {
      var projectSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('projects')
          .doc(projectId)
          .get();

      if (projectSnapshot.exists &&
          projectSnapshot.data()!.containsKey('name')) {
        projectNames.add(projectSnapshot['name']);
      } else {
        projectNames.add('Projeto sem nome');
      }
    }

    // Carrega os projetos disponíveis para seleção no dropdown
    List<DropdownMenuItem<String>> projectDropdownItems = availableProjects
        .map((project) => DropdownMenuItem<String>(
              value: project, // Use o nome do projeto como valor
              child: Text(project), // Exibe o nome do projeto
            ))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Detalhes do Cliente'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nome: ${client['name']} ${client['lastName']}'),
                    Text('Email: ${client['email']}'),
                    SizedBox(height: 16),
                    Text('Projetos:'),
                    ...client['projects'].map<Widget>((projectId) {
                      return Row(
                        children: [
                          Expanded(
                              child: Text(
                                  '- ${projectNames[client['projects'].indexOf(projectId)]}')),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () async {
                              // Atualiza a lista local removendo o projeto
                              setState(() {
                                client['projects'].remove(projectId);
                              });

                              // Remove o ID do projeto no Firebase
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(client['id'])
                                  .update({
                                'projects': FieldValue.arrayRemove([projectId])
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      hint: Text('Adicionar Projeto'),
                      items: projectDropdownItems,
                      onChanged: (value) {
                        selectedProject = value;
                      },
                      decoration:
                          InputDecoration(labelText: 'Selecione um Projeto'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Fechar'),
                ),
                ElevatedButton(
                  onPressed: selectedProject != null
                      ? () {
                          if (selectedProject != null) {
                            setState(() {
                              client['projects'].add(selectedProject!);
                            });
                            _addProjectToClient(client['id'], selectedProject!);
                            Navigator.of(context).pop();
                          }
                        }
                      : null,
                  child: Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecionar Foto'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                GestureDetector(
                  child: Text('Tirar Foto'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Escolher da Galeria'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientManagement() {
    return Column(
      children: clients.map((client) {
        return ListTile(
          title: Text('${client['name']} ${client['lastName']}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => _deleteClient(client['id']),
              ),
              IconButton(
                icon: Icon(Icons.email),
                onPressed: () => _resendVerificationEmail(client['id']),
              ),
            ],
          ),
          onTap: () =>
              _showClientDetails(client), // Exibe os detalhes do cliente
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          print("Carregando dados de perfil...");
          return Center(child: CircularProgressIndicator());
        }

        if (state is ProfileLoaded) {
          final profileData = state.profileData;
          role = profileData?['role'];
          userName = profileData?['name'] ?? 'Usuário Anônimo';
          profileImageUrl = profileData?['profileImageUrl'];

          print("Dados de perfil carregados: $profileData");

          nameController.text = profileData?['name'] ?? '';
          lastNameController.text = profileData?['lastName'] ?? '';
          emailController.text = profileData?['email'] ?? '';
          cpfController.text = profileData?['cpf'] ?? '';
          cepController.text = profileData?['cep'] ?? '';

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title:
                  Text('Profile', style: appWidget.headerLineTextFieldStyle()),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryColor,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Material(
                            elevation: 5,
                            shape: CircleBorder(),
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: profileImageUrl != null
                                    ? NetworkImage(profileImageUrl!)
                                    : AssetImage('assets/images/teste.jpg')
                                        as ImageProvider,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '$userName ${profileData?['lastName'] ?? ''}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('Profile Details'),
                    subtitle: Text('View your personal details'),
                    onTap: () => _showProfileForm(profileData),
                  ),
                  if (role == null)
                    ListTile(
                      leading: Icon(Icons.group_add_outlined),
                      title: Text('Add Member'),
                      subtitle: Text('Add a third person to your account'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              insetPadding: EdgeInsets.all(0),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: AddMemberForm(userId: user?.uid ?? ''),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  if (role == null)
                    ListTile(
                      leading: Icon(Icons.people_outline),
                      title: Text('Gerenciar Clientes'),
                      subtitle: Text('Ver e gerenciar seus clientes'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Gerenciar Clientes'),
                              content: SingleChildScrollView(
                                child: _buildClientManagement(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Fechar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    onTap: () async {
                      await _handleLogout();
                    },
                  ),
                ],
              ),
            ),
          );
        }

        print("Erro ao carregar perfil");
        return Scaffold(
          body: Center(child: Text("Erro ao carregar perfil")),
        );
      },
    );
  }
}
