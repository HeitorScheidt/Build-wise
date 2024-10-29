import 'package:build_wise/blocs/file/file_bloc.dart';
import 'package:build_wise/blocs/file/file_event.dart';
import 'package:build_wise/blocs/file/file_state.dart';
import 'package:build_wise/models/project_file.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:build_wise/services/file_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:build_wise/providers/user_role_provider.dart';

class FolderPage extends StatelessWidget {
  static FolderPage fromRouteArguments(Map<String, dynamic> arguments) {
    final userId = arguments['userId'] as String?;
    final projectId = arguments['projectId'] as String?;
    if (userId == null ||
        userId.isEmpty ||
        projectId == null ||
        projectId.isEmpty) {
      throw ArgumentError(
          'userId e projectId são obrigatórios e não podem ser vazios.');
    }
    return FolderPage(userId: userId, projectId: projectId);
  }

  final String userId;
  final String projectId;

  const FolderPage({required this.userId, required this.projectId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<UserRoleProvider>(context).role;

    return BlocProvider(
      create: (context) =>
          FileBloc(FileService())..add(FetchFiles(userId, projectId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Arquivos do Projeto',
              style: appWidget.headerLineTextFieldStyle()),
        ),
        body: BlocBuilder<FileBloc, FileState>(
          builder: (context, state) {
            if (state is FileLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is FileLoaded) {
              return ListView.builder(
                itemCount: state.files.length,
                itemBuilder: (context, index) {
                  ProjectFile file = state.files[index];
                  return ListTile(
                    title: Text(file.name),
                    subtitle: Text('Tamanho: ${_formatFileSize(file.size)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (userRole != 'Cliente')
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Código para editar o arquivo (implementação específica)
                            },
                          ),
                        if (userRole != 'Cliente')
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              context.read<FileBloc>().add(DeleteFile(
                                  userId, projectId, file.id, file.name));
                            },
                          ),
                      ],
                    ),
                    onTap: () async {
                      final url = file.downloadUrl;
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                  );
                },
              );
            } else if (state is FileError) {
              return Center(child: Text('Erro: ${state.message}'));
            } else {
              return Container();
            }
          },
        ),
        floatingActionButton: userRole != 'Cliente'
            ? FloatingActionButton(
                onPressed: () async {
                  final filePath = await pickFile();
                  if (filePath != null) {
                    final fileName = getFileNameFromPath(filePath);
                    context
                        .read<FileBloc>()
                        .add(UploadFile(userId, projectId, filePath, fileName));
                    context.read<FileBloc>().add(FetchFiles(userId, projectId));
                  }
                },
                child: Icon(Icons.add, color: Colors.white),
                backgroundColor: AppColors.primaryColor,
                shape: CircleBorder(),
              )
            : null,
      ),
    );
  }

  Future<String?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      return result.files.single.path;
    }
    return null;
  }

  String getFileNameFromPath(String filePath) {
    return filePath.split('/').last;
  }

  String _formatFileSize(int size) {
    if (size >= 1073741824) {
      return '${(size / 1073741824).toStringAsFixed(2)} GB';
    } else if (size >= 1048576) {
      return '${(size / 1048576).toStringAsFixed(2)} MB';
    } else if (size >= 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$size bytes';
    }
  }
}
