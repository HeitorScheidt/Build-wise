import 'dart:io';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/pages/cashflow_page.dart';
import 'package:build_wise/views/pages/folder_page.dart';
import 'package:build_wise/views/pages/gallery_page.dart';
import 'package:build_wise/views/pages/work_diary_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore para salvar as URLs
import 'package:build_wise/models/project_model.dart';
import 'package:build_wise/utils/wave_clipper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProjectDetails(
        project: ProjectModel(
            id: 'your_project_id',
            name: 'Project Name',
            clientName: 'Client',
            value: 1000,
            size: 200,
            notes: '',
            userId: 'your_user_id',
            image: ''), // Passe um ProjectModel aqui
        userId: 'your_user_id', // Passe o userId corretamente aqui
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/work_diary_page') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => WorkDiaryPage(projectId: args['projectId']),
          );
        } else if (settings.name == '/file_page') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => FolderPage(
              userId: args['userId'], // Recebe userId
              projectId: args['projectId'], // Recebe projectId
            ),
          );
        } else if (settings.name == '/gallery_page') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => GalleryPage(
              userId: args['userId'],
              projectId: args['projectId'],
            ),
          );
        } else if (settings.name == '/cashflow_page') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CashflowPage(
              userId: args['userId'],
              projectId: args['projectId'],
            ),
          );
        }

        return null;
      },
    );
  }
}

class ProjectDetails extends StatefulWidget {
  final ProjectModel project;
  final String userId;

  ProjectDetails({required this.project, required this.userId});

  @override
  _ProjectDetailsState createState() => _ProjectDetailsState();
}

class _ProjectDetailsState extends State<ProjectDetails> {
  String? _headerImageUrl;
  String? _clientImageUrl;
  String? _clientName;
  File? _pickedImageFile;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    try {
      final projectId = widget.project.id;
      final userId = widget.userId;

      // Buscar o documento do projeto a partir do Firestore
      final projectDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .get();

      if (projectDoc.exists) {
        setState(() {
          _headerImageUrl = projectDoc.data()?['headerImageUrl'];
        });
        print("Header image URL loaded: $_headerImageUrl");
      } else {
        print("No project document found for project ID: $projectId");
      }

      // Carregar imagens default se não existirem imagens personalizadas
      if (_headerImageUrl == null) {
        final defaultHeaderUrl = await FirebaseStorage.instance
            .ref('default/project_default_header.jpg')
            .getDownloadURL();
        setState(() => _headerImageUrl = defaultHeaderUrl);
        print("Default header image URL loaded: $defaultHeaderUrl");
      }

      // Buscar o primeiro cliente associado ao projeto e sua imagem de perfil
      await _loadFirstClientImage();
    } catch (e) {
      print("Failed to load images: $e");
    }
  }

  Future<void> _loadFirstClientImage() async {
    try {
      final projectId = widget.project.id;

      // Acessar o campo "projects" do cliente na coleção "users" para buscar o primeiro cliente
      final projectSnapshot = await _firestore
          .collection('users')
          .where('projects', arrayContains: projectId)
          .limit(1)
          .get();

      if (projectSnapshot.docs.isNotEmpty) {
        final clientData = projectSnapshot.docs.first.data();
        setState(() {
          _clientImageUrl =
              clientData['profileImageUrl'] ?? ''; // Valor padrão se nulo
          _clientName =
              "${clientData['name'] ?? 'Sem nome'} ${clientData['lastName'] ?? 'Sem sobrenome'}"; // Valores padrão
        });

        print("Client image URL: $_clientImageUrl");
        print("Client name: $_clientName");
      } else {
        print("No client found associated with project ID: $projectId");
      }

      // Se não houver cliente ou imagem, carregar uma imagem padrão
      if (_clientImageUrl == null) {
        final defaultClientUrl = await FirebaseStorage.instance
            .ref('default/client.jpg')
            .getDownloadURL();
        setState(() => _clientImageUrl = defaultClientUrl);
        print("Default client image URL loaded: $defaultClientUrl");
      }
    } catch (e) {
      print("Failed to load client image: $e");
    }
  }

  Future<void> _uploadImage(File imageFile, String type) async {
    try {
      final projectId = widget.project.id;
      final userId = widget.userId;

      // Agora salvamos as imagens dentro do diretório do usuário no Firebase Storage
      final ref = FirebaseStorage.instance
          .ref('users/$userId/projects/$projectId/$type.jpg');

      // Deletar a imagem existente
      final existingFiles = await ref.listAll();
      for (var file in existingFiles.items) {
        await file.delete();
      }

      // Upload da nova imagem
      await ref.putFile(imageFile);
      String url = await ref.getDownloadURL();

      // Salvar a URL da imagem no Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .set({'$type' + 'ImageUrl': url}, SetOptions(merge: true));

      // Atualizar a URL da imagem no estado
      setState(() {
        if (type == 'header') {
          _headerImageUrl = url;
        } else if (type == 'client') {
          _clientImageUrl = url;
        }
      });
      print("Uploaded $type image and URL saved: $url");
    } catch (e) {
      print("Failed to upload image: $e");
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        setState(() {
          _pickedImageFile = imageFile;
        });
        _uploadImage(imageFile, type);
        print("Picked image for $type");
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Failed to pick image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(250.0),
        child: AppBar(
          flexibleSpace: Stack(
            children: [
              ClipPath(
                clipper: WaveClipper(),
                child: GestureDetector(
                  onTap: () => _pickImage('header'),
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _headerImageUrl != null
                            ? NetworkImage(_headerImageUrl!)
                            : const AssetImage('assets/default_image.jpg')
                                as ImageProvider, // Placeholder if null
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10, // Ajuste conforme necessário para alinhamento
                left: 12, // Ajuste conforme necessário para alinhamento
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 50, // Ajuste o tamanho conforme necessário
                      backgroundImage: _clientImageUrl != null
                          ? NetworkImage(_clientImageUrl!)
                          : const AssetImage('assets/images/default_client.jpg')
                              as ImageProvider, // Placeholder if null
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[500]), // Ícone
                        Text(
                            _clientName ??
                                'Sem nome do cliente', // Fallback para o nome do cliente
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[500])),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(context),
            SizedBox(height: 16.0),
            _buildActionButtons(context),
            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.project.name ?? 'No Project Name',
                    style: appWidget.headerLineTextFieldStyle()),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Colors.grey[500]),
                    Text(
                      'Lagos, Nigeria',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.grey[500]),
                    Text(
                      widget.project.value?.toStringAsFixed(2) ?? '0.00',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    List<Widget> buttons = [
      _buildActionButton('360', Icons.threed_rotation, Colors.orange, context,
          () {
        Navigator.pushNamed(
          context,
          '/link_page',
          arguments: {
            'userId': widget.userId,
            'projectId': widget.project.id,
          },
        );
      }),
      _buildActionButton(
          'Fornecedores', Icons.people, Colors.green, context, () {}),
      _buildActionButton('Cash Flow', Icons.attach_money, Colors.blue, context,
          () {
        Navigator.pushNamed(
          context,
          '/cashflow_page',
          arguments: {
            'userId': widget.userId ?? 'default_user_id',
            'projectId': widget.project.id ?? 'default_project_id',
          },
        );
      }),
      _buildActionButton('Projetos', Icons.drive_file_rename_outline_sharp,
          Colors.grey, context, () {
        Navigator.pushNamed(
          context,
          '/folder_page',
          arguments: {'userId': widget.userId, 'projectId': widget.project.id},
        );
      }),
      _buildActionButton(
          'Diário de Obra', Icons.note_alt, Colors.purple, context, () {
        Navigator.pushNamed(
          context,
          '/work_diary_page',
          arguments: {'projectId': widget.project.id},
        );
      }),
      _buildActionButton('Galeria', Icons.photo, Colors.brown, context, () {
        Navigator.pushNamed(
          context,
          '/gallery_page',
          arguments: {
            'userId': widget.userId,
            'projectId': widget.project.id,
          },
        );
      }),
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.start,
      children: buttons.map((button) {
        return Container(
          width: MediaQuery.of(context).size.width / 3 - 16,
          child: button,
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color,
      BuildContext context, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 30,
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8.0),
          Text(label, style: TextStyle(fontSize: 12.0)),
        ],
      ),
    );
  }
}
