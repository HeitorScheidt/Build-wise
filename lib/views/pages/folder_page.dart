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
import 'package:url_launcher/url_launcher.dart'; // Para abrir a URL de download

class FolderPage extends StatelessWidget {
  final String userId;
  final String projectId;

  const FolderPage({required this.userId, required this.projectId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Creating a new FileBloc instance for each project to avoid state sharing across projects
    return BlocProvider(
      create: (context) => FileBloc(FileService())
        ..add(FetchFiles(
            userId, projectId)), // Fetch files for the specific project
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
                    subtitle: Text('Tamanho: ${file.size} bytes'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        context.read<FileBloc>().add(
                            DeleteFile(userId, projectId, file.id, file.name));
                      },
                    ),
                    onTap: () async {
                      // Baixar arquivo quando clicado usando url_launcher
                      final url = file.downloadUrl;
                      if (await canLaunch(url)) {
                        await launch(
                            url); // Abre o arquivo no navegador ou app padrão
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Código para selecionar arquivo e fazer upload
            final filePath = await pickFile(); // Função para escolher o arquivo

            if (filePath != null) {
              // Verifica se o caminho do arquivo não é nulo
              final fileName =
                  getFileNameFromPath(filePath); // Extrair nome do arquivo

              // Upload do arquivo
              context
                  .read<FileBloc>()
                  .add(UploadFile(userId, projectId, filePath, fileName));

              // Atualizar a lista de arquivos após o upload
              context.read<FileBloc>().add(FetchFiles(userId, projectId));
            }
          },
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: AppColors.primaryColor,
          shape: CircleBorder(), // Tornando o botão 100% arredondado
        ),
      ),
    );
  }

  // Função para escolher o arquivo
  Future<String?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      return result.files.single.path; // Caminho do arquivo selecionado
    }
    return null; // Retorna null se o usuário cancelar a seleção
  }

  // Função para obter o nome do arquivo a partir do caminho
  String getFileNameFromPath(String filePath) {
    return filePath.split('/').last; // Retorna o nome do arquivo
  }
}
