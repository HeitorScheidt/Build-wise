import 'dart:io';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/pages/cashflow_page.dart';
import 'package:build_wise/views/pages/folder_page.dart';
import 'package:build_wise/views/pages/gallery_page.dart';
import 'package:build_wise/views/pages/work_diary_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:build_wise/models/project_model.dart';
import 'package:build_wise/utils/wave_clipper.dart';
import 'package:intl/intl.dart';

class ProjectDetails extends StatefulWidget {
  final ProjectModel project;

  ProjectDetails({required this.project});

  @override
  _ProjectDetailsState createState() => _ProjectDetailsState();
}

class _ProjectDetailsState extends State<ProjectDetails> {
  String? _headerImageUrl;
  String? _clientImageUrl;
  String? _clientName;
  File? _pickedImageFile;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
    _loadFirstClientName();
  }

  Future<void> _loadSavedImages() async {
    try {
      if (widget.project.headerImageUrl?.isNotEmpty ?? false) {
        setState(() {
          _headerImageUrl = widget.project.headerImageUrl;
        });
      } else {
        final defaultHeaderUrl = await FirebaseStorage.instance
            .ref('default/project_default_header.jpg')
            .getDownloadURL();
        setState(() => _headerImageUrl = defaultHeaderUrl);
      }
      print("Header image URL loaded: $_headerImageUrl");
    } catch (e) {
      print("Failed to load header image: $e");
    }
  }

  Future<void> _loadFirstClientName() async {
    try {
      if (widget.project.clients != null &&
          widget.project.clients!.isNotEmpty) {
        final clientId = widget.project.clients!.first;
        final clientDoc =
            await _firestore.collection('users').doc(clientId).get();

        if (clientDoc.exists) {
          setState(() {
            _clientName =
                "${clientDoc.data()?['name'] ?? 'Sem nome'} ${clientDoc.data()?['lastName'] ?? ''}";
            _clientImageUrl = clientDoc.data()?['profileImageUrl'];
          });
        }
      } else {
        setState(() {
          _clientName = 'client name';
        });
      }
      print("Client name loaded: $_clientName");
    } catch (e) {
      print("Failed to load client name: $e");
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

  Future<void> _uploadImage(File imageFile, String type) async {
    try {
      final projectId = widget.project.id;

      final ref = FirebaseStorage.instance.ref('projects/$projectId/$type.jpg');
      await ref.putFile(imageFile);
      String url = await ref.getDownloadURL();

      await _firestore
          .collection('projects')
          .doc(projectId)
          .set({'${type}ImageUrl': url}, SetOptions(merge: true));

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

  String formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  String formatSquareMeters(double size) {
    return '${size.toString()} m²';
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
                        image: (_headerImageUrl != null &&
                                _headerImageUrl!.isNotEmpty)
                            ? NetworkImage(_headerImageUrl!)
                            : AssetImage(
                                    'assets/images/project_default_header.jpg')
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _clientImageUrl != null && _clientImageUrl!.isNotEmpty
                              ? NetworkImage(_clientImageUrl!)
                              : AssetImage('assets/images/default_client.png')
                                  as ImageProvider,
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[500]),
                        Text(
                          _clientName ?? 'Sem nome do cliente',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[500]),
                        ),
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
                /*Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Colors.grey[500]),
                    Text(
                      'Lagos, Nigeria',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),*/
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.grey[500]),
                    Text(
                      formatCurrency(widget.project.value ?? 0),
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
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildActionButton('360', Icons.threed_rotation, Colors.orange, context,
            () {
          Navigator.pushNamed(context, '/link_page',
              arguments: {'projectId': widget.project.id});
        }),
        _buildActionButton(
            'Fornecedores', Icons.people, Colors.green, context, () {}),
        _buildActionButton(
          'Cash Flow',
          Icons.attach_money,
          Colors.blue,
          context,
          () {
            // Verifique que os valores não são nulos antes de navegar
            if (widget.project.id != null && widget.project.userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CashflowPage(
                    userId: widget.project.userId!,
                    projectId: widget.project.id!,
                  ),
                ),
              );
            } else {
              print('Erro: userId ou projectId é nulo.');
              // Opcional: exibir uma mensagem de erro para o usuário
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: userId ou projectId é nulo.')),
              );
            }
          },
        ),
        _buildActionButton('Projetos', Icons.drive_file_rename_outline_sharp,
            Colors.grey, context, () {
          Navigator.pushNamed(context, '/cashflow_page', arguments: {
            'projectId': widget.project.id ?? 'unknown_project_id'
          });
        }),
        _buildActionButton(
            'Diário de Obra', Icons.note_alt, Colors.purple, context, () {
          Navigator.pushNamed(context, '/work_diary_page',
              arguments: {'projectId': widget.project.id});
        }),
        _buildActionButton('Galeria', Icons.photo, Colors.brown, context, () {
          Navigator.pushNamed(context, '/gallery_page',
              arguments: {'projectId': widget.project.id});
        }),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color,
      BuildContext context, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
