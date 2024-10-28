import 'package:build_wise/blocs/gallery/gallery_bloc.dart';
import 'package:build_wise/blocs/gallery/gallery_event.dart';
import 'package:build_wise/blocs/gallery/gallery_state.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:build_wise/providers/user_role_provider.dart';

class GalleryPage extends StatefulWidget {
  final String userId;
  final String projectId;

  // Método para extrair argumentos de forma segura
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

  // Função para inicializar o papel do usuário usando o UserRoleProvider
  void _initializeUserRole() {
    final roleProvider = Provider.of<UserRoleProvider>(context, listen: false);
    roleProvider.fetchUserRole().then((_) {
      setState(() {
        userRole = roleProvider.role;
        isLoadingRole = false;
      });
    });
  }

  void toggleSelectionMode() {
    setState(() {
      isSelecting = !isSelecting;
      if (!isSelecting) {
        selectedPhotos.clear();
      }
    });
  }

  void togglePhotoSelection(String photoId) {
    setState(() {
      if (selectedPhotos.contains(photoId)) {
        selectedPhotos.remove(photoId);
      } else {
        selectedPhotos.add(photoId);
      }
    });
  }

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
    // Exibe um indicador de carregamento enquanto o papel do usuário está sendo carregado
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
                      for (var pickedFile in pickedFiles) {
                        if (pickedFile.path.isNotEmpty) {
                          context.read<GalleryBloc>().add(
                                AddPhoto(
                                  widget.userId,
                                  widget.projectId,
                                  pickedFile.path,
                                ),
                              );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro: filePath é nulo.')),
                          );
                        }
                      }
                    } else {
                      print("Nenhuma imagem selecionada.");
                    }
                  },
                  child: Icon(Icons.add, color: Colors.white),
                  backgroundColor: AppColors.primaryColor,
                  shape: CircleBorder(),
                )
              : null, // Não exibe o FloatingActionButton se o usuário for Cliente
    );
  }
}
