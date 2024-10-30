import 'dart:io';
import 'dart:typed_data';
import 'package:build_wise/blocs/gallery/gallery_bloc.dart';
import 'package:build_wise/blocs/gallery/gallery_event.dart';
import 'package:build_wise/blocs/gallery/gallery_state.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:build_wise/providers/user_role_provider.dart';
import 'package:path_provider/path_provider.dart';

class GalleryPage extends StatefulWidget {
  final String userId;
  final String projectId;

  static GalleryPage fromRouteArguments(Map<String, dynamic> arguments) {
    final userId = arguments['userId'] as String?;
    final projectId = arguments['projectId'] as String?;
    if (userId == null ||
        userId.isEmpty ||
        projectId == null ||
        projectId.isEmpty) {
      throw ArgumentError(
          'userId e projectId são obrigatórios e não podem ser vazios.');
    }
    return GalleryPage(userId: userId, projectId: projectId);
  }

  GalleryPage({required this.userId, required this.projectId});

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool isSelecting = false;
  List<String> selectedPhotos = [];
  String? userRole;
  bool isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _initializeUserRole();
    context
        .read<GalleryBloc>()
        .add(LoadPhotos(widget.userId, widget.projectId));
  }

  void _initializeUserRole() async {
    final roleProvider = Provider.of<UserRoleProvider>(context, listen: false);
    await roleProvider.fetchUserRole();
    if (mounted) {
      setState(() {
        userRole = roleProvider.role;
        isLoadingRole = false;
      });
    }
  }

  // Função para comprimir a imagem com qualidade reduzida
  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      var result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 50, // Ajuste a qualidade para 50
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao comprimir a imagem: $e')),
        );
      }
      return null;
    }
  }

  // Função para realizar o upload como caminho temporário
  Future<void> uploadImageWithTempFile(File file, int maxRetries) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final imageBytes = await file.readAsBytes();

        // Verifica se o tamanho em bytes está dentro do limite de 10 MB
        if (imageBytes.length > 10485760) {
          throw Exception(
              'Arquivo muito grande. Reduza a qualidade e tente novamente.');
        }

        // Cria um arquivo temporário para armazenar os bytes
        final tempDir = await getTemporaryDirectory();
        final tempFile = await File(
                '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg')
            .create();
        await tempFile.writeAsBytes(imageBytes);

        // Envia o caminho do arquivo temporário como String
        context
            .read<GalleryBloc>()
            .add(AddPhoto(widget.userId, widget.projectId, tempFile.path));
        return; // Upload bem-sucedido, termina a função
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Erro ao enviar foto: $e. Todas as tentativas falharam.')),
            );
          }
          return; // Falha após o número máximo de tentativas
        }
        await Future.delayed(
            Duration(seconds: 5)); // Aumenta o tempo de espera entre tentativas
      }
    }
  }

  // Processa imagens uma a uma, dividindo em lotes
  Future<void> processImagesSequentially(List<XFile> pickedFiles) async {
    int batchSize = 2; // Número de imagens para enviar em cada lote

    for (int i = 0; i < pickedFiles.length; i += batchSize) {
      int end = (i + batchSize < pickedFiles.length)
          ? i + batchSize
          : pickedFiles.length;
      List<XFile> batchFiles = pickedFiles.sublist(i, end);

      for (var pickedFile in batchFiles) {
        final file = File(pickedFile.path);
        final compressedFile = await compressImage(file);

        if (compressedFile != null && await compressedFile.exists()) {
          await uploadImageWithTempFile(
              compressedFile, 5); // Tenta o upload até 5 vezes em caso de falha
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao comprimir ou encontrar o arquivo.')),
          );
        }
        await Future.delayed(
            Duration(seconds: 1)); // Pequeno atraso entre uploads
      }
    }
  }

  // Alterna o modo de seleção
  void toggleSelectionMode() {
    setState(() {
      isSelecting = !isSelecting;
      if (!isSelecting) {
        selectedPhotos.clear();
      }
    });
  }

  // Alterna a seleção de uma foto específica
  void togglePhotoSelection(String photoId) {
    setState(() {
      if (selectedPhotos.contains(photoId)) {
        selectedPhotos.remove(photoId);
      } else {
        selectedPhotos.add(photoId);
      }
    });
  }

  // Deleta as fotos selecionadas
  void deleteSelectedPhotos() {
    final photos = context.read<GalleryBloc>().state;

    if (photos is GalleryLoaded) {
      for (var photoId in selectedPhotos) {
        final photo = photos.photos.firstWhere(
          (p) => p.id == photoId,
          orElse: () => throw Exception("Photo not found for ID: $photoId"),
        );

        if (photo.url.isNotEmpty) {
          print("Tentando deletar a foto com URL: ${photo.url}");

          context.read<GalleryBloc>().add(DeletePhoto(
                photo.id,
                widget.userId,
                widget.projectId,
                photo.url,
              ));
        } else {
          print("Erro: URL da foto é nula ou vazia.");
        }
      }
    }

    toggleSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingRole) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Gallery", style: appWidget.headerLineTextFieldStyle()),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Gallery", style: appWidget.headerLineTextFieldStyle()),
        actions: [
          if (userRole != "Cliente" && !isSelecting)
            IconButton(
              icon: Icon(Icons.select_all),
              onPressed: toggleSelectionMode,
            ),
        ],
      ),
      body: BlocBuilder<GalleryBloc, GalleryState>(
        builder: (context, state) {
          if (state is GalleryLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is GalleryLoaded) {
            if (state.photos.isEmpty) {
              return Center(child: Text("No photos available"));
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: 1,
              ),
              itemCount: state.photos.length,
              itemBuilder: (context, index) {
                final photo = state.photos[index];
                final isSelected = selectedPhotos.contains(photo.id);

                return GestureDetector(
                  onTap: () {
                    if (isSelecting) {
                      togglePhotoSelection(photo.id);
                    }
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.network(
                          photo.url ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      if (isSelecting)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (bool? selected) {
                              togglePhotoSelection(photo.id);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          } else if (state is GalleryError) {
            return Center(child: Text(state.errorMessage));
          }
          return Container();
        },
      ),
      floatingActionButton: (userRole != "Cliente" && isSelecting)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: toggleSelectionMode,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.cancel),
                ),
                SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: deleteSelectedPhotos,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete),
                ),
              ],
            )
          : (userRole != "Cliente")
              ? FloatingActionButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFiles = await picker.pickMultiImage();

                    if (pickedFiles != null && pickedFiles.isNotEmpty) {
                      await processImagesSequentially(
                          pickedFiles); // Processa as imagens uma a uma
                    } else {
                      print("Nenhuma imagem selecionada.");
                    }
                  },
                  child: Icon(Icons.add, color: Colors.white),
                  backgroundColor: AppColors.primaryColor,
                  shape: CircleBorder(),
                )
              : null,
    );
  }
}
