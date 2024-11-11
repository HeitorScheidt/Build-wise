import 'dart:io';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/diary/work_diary_bloc.dart';
import 'package:build_wise/blocs/diary/work_diary_event.dart';
import 'package:build_wise/blocs/diary/work_diary_state.dart';
import 'package:build_wise/models/work_diary_entry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
  List<String> existingImages =
      []; // Lista para armazenar URLs das imagens já existentes
  bool isSaving = false;
  WorkDiaryEntry? editingEntry;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
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
            return Center(child: Text(state.message));
          } else {
            return const Center(child: Text('Nenhuma entrada no diário.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isSaving ? null : () => _showAddEntryDialog(context),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWorkEntryCard(WorkDiaryEntry entry, int index) {
    return Card(
      elevation: 5.0,
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Relatório de obra - ${index + 1}',
                  style: appWidget
                      .headerLineTextFieldStyle()
                      .copyWith(fontSize: 20),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      color: AppColors.primaryColor,
                      onPressed: () {
                        _showEditEntryDialog(entry);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      color: AppColors.primaryColor,
                      onPressed: () {
                        final userId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        context.read<WorkDiaryBloc>().add(
                            DeleteWorkDiaryEntryEvent(
                                userId, widget.projectId, entry.entryId));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Data: ${entry.date.day}/${entry.date.month}/${entry.date.year}',
              style: appWidget.normalTextFieldStyle().copyWith(fontSize: 18),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              entry.description,
              style: appWidget.normalTextFieldStyle().copyWith(fontSize: 18),
            ),
          ),
          SizedBox(height: 10),
          if (entry.photos.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: entry.photos.length,
                itemBuilder: (context, photoIndex) {
                  return Padding(
                    padding: EdgeInsets.all(4),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          entry.photos[
                              photoIndex], // Passa a URL correta de cada imagem
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image, size: 60);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context, {bool isEditing = false}) {
    final workDiaryBloc = context
        .read<WorkDiaryBloc>(); // Captura o Bloc antes de abrir o diálogo

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              isEditing ? 'Editar entrada' : 'Nova entrada no diário de obra'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                              : 'Data: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.date_range),
                            onPressed: () =>
                                _selectDate(context, setDialogState),
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
                        icon: Icon(Icons.add_photo_alternate,
                            color: Colors.white),
                        label: const Text('Adicione Fotos da Obra',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryColor, // Cor de fundo
                        ),
                        onPressed: () async {
                          await _pickImages(setDialogState);
                        },
                      ),
                      // Exibir imagens existentes e novas na lista
                      if (existingImages.isNotEmpty ||
                          selectedImages.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: [
                            ...existingImages.map((imageUrl) {
                              final imageName = imageUrl.split('/').last;
                              return Chip(
                                label: Text(imageName),
                                deleteIcon:
                                    Icon(Icons.close, color: Colors.red),
                                onDeleted: () {
                                  setDialogState(() {
                                    existingImages.remove(imageUrl);
                                  });
                                },
                              );
                            }).toList(),
                            ...selectedImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final imageName = entry.value.name;
                              return Chip(
                                label: Text(imageName),
                                deleteIcon:
                                    Icon(Icons.close, color: Colors.red),
                                onDeleted: () {
                                  setDialogState(() {
                                    selectedImages.removeAt(index);
                                  });
                                },
                              );
                            }).toList(),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                _clearDialogFields();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: isSaving
                  ? const CircularProgressIndicator()
                  : Text(isEditing ? 'Atualizar' : 'Adicionar'),
              onPressed: () async {
                if (selectedPeriod != null &&
                    descriptionController.text.isNotEmpty &&
                    selectedDate != null) {
                  setState(() {
                    isSaving = true;
                  });

                  Navigator.of(context).pop(); // Fecha o diálogo imediatamente

                  // Realiza o upload das imagens e adiciona o diário de forma assíncrona
                  List<String> uploadedImageUrls = await _uploadImages();
                  final allImages = [...existingImages, ...uploadedImageUrls];

                  final entry = WorkDiaryEntry(
                    entryId: isEditing ? editingEntry!.entryId : "",
                    period: selectedPeriod!,
                    wasPractical: wasPractical,
                    userName: FirebaseAuth.instance.currentUser?.displayName ??
                        'Usuário',
                    description: descriptionController.text,
                    date: selectedDate!,
                    photos: allImages,
                  );

                  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  if (isEditing) {
                    workDiaryBloc.add(UpdateWorkDiaryEntryEvent(
                        userId, widget.projectId, entry));
                  } else {
                    workDiaryBloc.add(AddWorkDiaryEntryEvent(
                        userId, widget.projectId, entry));
                  }

                  setState(() {
                    isSaving = false;
                  });

                  _loadEntries();
                  _clearDialogFields();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditEntryDialog(WorkDiaryEntry entry) {
    setState(() {
      editingEntry = entry;
      selectedPeriod = entry.period;
      descriptionController.text = entry.description;
      selectedDate = entry.date;
      wasPractical = entry.wasPractical;
      existingImages = List.from(entry.photos); // Carrega as imagens existentes
      selectedImages.clear();
    });

    _showAddEntryDialog(context, isEditing: true);
  }

  void _clearDialogFields() {
    descriptionController.clear();
    selectedDate = null;
    selectedPeriod = null;
    selectedImages.clear();
    existingImages.clear();
    editingEntry = null;
  }

  Future<File> _compressImage(File file) async {
    final imageBytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image != null) {
      img.Image resized = img.copyResize(image, width: 800); // Ajusta o tamanho
      final compressedBytes =
          img.encodeJpg(resized, quality: 80); // Ajusta a qualidade

      // Cria um arquivo temporário único para cada imagem comprimida
      final tempDir = await getTemporaryDirectory();
      final uuid = Uuid().v4();
      final compressedFile = File('${tempDir.path}/compressed_$uuid.jpg');

      return compressedFile.writeAsBytes(compressedBytes);
    } else {
      throw Exception("Falha ao decodificar a imagem");
    }
  }

  Future<List<String>> _uploadImages() async {
    List<Future<String>> uploadTasks = [];

    // Para cada imagem, crie uma Future separada
    for (XFile image in selectedImages) {
      // Adiciona uma Future para o upload de cada imagem
      uploadTasks.add(_uploadSingleImage(image));
    }

    // Aguarda a conclusão de todas as Futures
    return await Future.wait(uploadTasks);
  }

  Future<String> _uploadSingleImage(XFile image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final uuid = Uuid().v4();
      final tempImagePath = '${tempDir.path}/$uuid.jpg';

      // Salva o arquivo temporário e comprime a imagem
      final tempFile =
          await File(tempImagePath).writeAsBytes(await image.readAsBytes());
      final compressedFile = await _compressImage(tempFile);

      // Define um nome único para cada imagem antes do upload
      final storageRef = FirebaseStorage.instance.ref().child(
          'work_diary/${DateTime.now().millisecondsSinceEpoch}_$uuid.jpg');

      // Executa o upload
      final uploadTask = storageRef.putFile(compressedFile);
      final snapshot = await uploadTask.whenComplete(() {});

      // Retorna a URL da imagem no Firebase
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return '';
    }
  }

  Future<void> _pickImages(StateSetter setDialogState) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setDialogState(() {
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
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData),
            SizedBox(width: 4),
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
