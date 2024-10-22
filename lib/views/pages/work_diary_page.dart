import 'dart:io';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/diary/work_diary_bloc.dart';
import 'package:build_wise/blocs/diary/work_diary_event.dart';
import 'package:build_wise/blocs/diary/work_diary_state.dart';
import 'package:build_wise/models/work_diary_entry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage para upload de imagens
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for database access

class WorkDiaryPage extends StatefulWidget {
  final String projectId;

  const WorkDiaryPage({Key? key, required this.projectId}) : super(key: key);

  @override
  _WorkDiaryPageState createState() => _WorkDiaryPageState();
}

class _WorkDiaryPageState extends State<WorkDiaryPage> {
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDate;
  bool wasPractical = false;
  String? selectedPeriod;
  List<XFile> selectedImages = [];
  bool isSaving = false; // To handle state when saving

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    context
        .read<WorkDiaryBloc>()
        .add(LoadWorkDiaryEntriesEvent(userId, widget.projectId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Diário de Obra', style: appWidget.headerLineTextFieldStyle()),
      ),
      body: BlocBuilder<WorkDiaryBloc, WorkDiaryState>(
        builder: (context, state) {
          if (state is WorkDiaryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WorkDiaryLoaded && state.entries.isNotEmpty) {
            return ListView.builder(
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                return _buildWorkEntryCard(entry, index);
              },
            );
          } else if (state is WorkDiaryError) {
            return Center(child: Text(state.message)); // Show error message
          } else {
            return const Center(child: Text('Nenhuma entrada no diário.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isSaving ? null : () => _showAddEntryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWorkEntryCard(WorkDiaryEntry entry, int index) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Relatório de obra - ${index + 1}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Data: ${entry.date.toString().substring(0, 10)}',
                style: TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(entry.description, style: TextStyle(fontSize: 16)),
          ),
          SizedBox(height: 10),
          if (entry.photos.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: entry.photos.length,
                itemBuilder: (context, photoIndex) {
                  return Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Image.network(entry.photos[photoIndex]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nova entrada no diário de obra'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      children: ['Manhã', 'Tarde', 'Noite']
                          .map((period) => _periodSelector(
                              period, getIconData(period), setDialogState))
                          .toList(),
                    ),
                    SwitchListTile(
                      title: Text(
                          wasPractical ? 'Foi prático' : 'Foi impraticável'),
                      value: wasPractical,
                      onChanged: (bool value) {
                        setDialogState(() {
                          wasPractical = value;
                        });
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.calendar_today),
                        labelText: selectedDate == null
                            ? 'Insira a data do relatório'
                            : 'Data: ${selectedDate!.toIso8601String().substring(0, 10)}',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.date_range),
                          onPressed: () => _selectDate(context, setDialogState),
                        ),
                      ),
                      readOnly: true,
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Descreva o que foi feito'),
                      maxLines: 3,
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add_photo_alternate),
                      label: const Text('Adicione Fotos da Obra'),
                      onPressed: _pickImages,
                    ),
                    if (selectedImages.isNotEmpty)
                      Container(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.file(File(selectedImages[index].path)),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Adicionar'),
              onPressed: () async {
                if (selectedPeriod != null &&
                    descriptionController.text.isNotEmpty &&
                    selectedDate != null) {
                  setState(() {
                    isSaving = true;
                  });

                  // Upload de imagens para Firebase Storage e obtenção das URLs
                  List<String> uploadedImageUrls = await _uploadImages();

                  // Pegar o nome do usuário atual
                  String? username =
                      FirebaseAuth.instance.currentUser?.displayName ??
                          'Usuário';

                  // Criação da entrada no Firestore com as URLs das imagens e data selecionada
                  final entry = WorkDiaryEntry(
                    period: selectedPeriod!,
                    wasPractical: wasPractical,
                    userName: username, // Guardar ${username} corretamente
                    description: descriptionController.text,
                    date: selectedDate!,
                    photos: uploadedImageUrls,
                  );

                  context.read<WorkDiaryBloc>().add(AddWorkDiaryEntryEvent(
                      FirebaseAuth.instance.currentUser?.uid ?? '',
                      widget.projectId,
                      entry));

                  setState(() {
                    isSaving = false;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _uploadImages() async {
    List<String> downloadUrls = [];
    for (XFile image in selectedImages) {
      final file = File(image.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('work_diary/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(file);

      // Aguarda o upload e recupera a URL de download
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }
    return downloadUrls;
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        selectedImages = images;
      });
    }
  }

  IconData getIconData(String period) {
    switch (period) {
      case 'Manhã':
        return Icons.wb_sunny;
      case 'Tarde':
        return Icons.light_mode;
      case 'Noite':
        return Icons.nightlight_round;
      default:
        return Icons.error;
    }
  }

  Widget _periodSelector(
      String period, IconData iconData, StateSetter setDialogState) {
    bool isSelected = selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          selectedPeriod = period;
        });
      },
      child: Container(
        margin: EdgeInsets.all(4),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData),
            SizedBox(width: 8),
            Text(period,
                style:
                    TextStyle(color: isSelected ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, StateSetter setDialogState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setDialogState(() {
        selectedDate = picked;
      });
    }
  }
}
