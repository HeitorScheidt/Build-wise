import 'package:build_wise/blocs/link/link_bloc.dart';
import 'package:build_wise/blocs/link/link_event.dart';
import 'package:build_wise/blocs/link/link_state.dart';
import 'package:build_wise/models/link_model.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:build_wise/providers/user_role_provider.dart';

class LinkPage extends StatelessWidget {
  final String userId;
  final String projectId;

  LinkPage({required this.userId, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<UserRoleProvider>(context).role;

    return Scaffold(
      appBar: AppBar(
        title: Text('Links dos Cômodos',
            style: appWidget.headerLineTextFieldStyle()),
      ),
      body: BlocBuilder<LinkBloc, LinkState>(
        builder: (context, state) {
          if (state is LinkLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is LinkLoaded) {
            return ListView.builder(
              itemCount: state.links.length,
              itemBuilder: (context, index) {
                final link = state.links[index];
                return ListTile(
                  leading: Icon(Icons.link, color: AppColors.primaryColor),
                  title: Text(link.roomName,
                      style: appWidget.boldLineTextFieldStyle()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (userRole != 'Cliente')
                        IconButton(
                          icon: Icon(Icons.edit, color: AppColors.primaryColor),
                          onPressed: () {
                            _showEditLinkDialog(
                                context, userId, projectId, link);
                          },
                        ),
                      if (userRole != 'Cliente')
                        IconButton(
                          icon:
                              Icon(Icons.delete, color: AppColors.primaryColor),
                          onPressed: () {
                            context
                                .read<LinkBloc>()
                                .add(DeleteLink(userId, projectId, link.id));
                          },
                        ),
                    ],
                  ),
                  onTap: () async {
                    final url = link.linkUrl;
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Não foi possível abrir o link.')),
                      );
                    }
                  },
                );
              },
            );
          } else if (state is LinkError) {
            return Center(child: Text(state.error));
          } else {
            return Center(child: Text('Nenhum link encontrado.'));
          }
        },
      ),
      floatingActionButton: userRole != 'Cliente'
          ? FloatingActionButton(
              onPressed: () {
                _showAddLinkDialog(context, userId, projectId);
              },
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: AppColors.primaryColor,
              shape: CircleBorder(),
            )
          : null,
    );
  }
}

void _showAddLinkDialog(BuildContext context, String userId, String projectId) {
  final TextEditingController roomNameController = TextEditingController();
  final TextEditingController linkUrlController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Adicionar Novo Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomNameController,
              decoration: InputDecoration(labelText: 'Nome do Cômodo'),
            ),
            TextField(
              controller: linkUrlController,
              decoration: InputDecoration(labelText: 'URL do Link'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final roomName = roomNameController.text.trim();
              final linkUrl = linkUrlController.text.trim();

              if (roomName.isNotEmpty && linkUrl.isNotEmpty) {
                context.read<LinkBloc>().add(AddLink(
                      userId,
                      projectId,
                      LinkModel(id: '', roomName: roomName, linkUrl: linkUrl),
                    ));
                Navigator.of(context).pop();
              }
            },
            child: Text('Adicionar'),
          ),
        ],
      );
    },
  );
}

void _showEditLinkDialog(
    BuildContext context, String userId, String projectId, LinkModel link) {
  final TextEditingController roomNameController =
      TextEditingController(text: link.roomName);
  final TextEditingController linkUrlController =
      TextEditingController(text: link.linkUrl);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Editar Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roomNameController,
              decoration: InputDecoration(labelText: 'Nome do Cômodo'),
            ),
            TextField(
              controller: linkUrlController,
              decoration: InputDecoration(labelText: 'URL do Link'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final updatedRoomName = roomNameController.text.trim();
              final updatedLinkUrl = linkUrlController.text.trim();

              if (updatedRoomName.isNotEmpty && updatedLinkUrl.isNotEmpty) {
                context.read<LinkBloc>().add(UpdateLink(
                      userId,
                      projectId,
                      LinkModel(
                        id: link.id,
                        roomName: updatedRoomName,
                        linkUrl: updatedLinkUrl,
                      ),
                    ));
                Navigator.of(context).pop();
              }
            },
            child: Text('Salvar'),
          ),
        ],
      );
    },
  );
}
