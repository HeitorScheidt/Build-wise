import 'package:build_wise/models/link_model.dart';
import 'package:build_wise/services/link_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'link_event.dart';
import 'link_state.dart';

class LinkBloc extends Bloc<LinkEvent, LinkState> {
  final LinkService linkService;

  LinkBloc(this.linkService) : super(LinkLoading()) {
    on<LoadLinks>((event, emit) async {
      try {
        final linksStream = linkService.getLinks(event.userId, event.projectId);
        await emit.forEach<List<LinkModel>>(linksStream, onData: (links) {
          return LinkLoaded(links);
        });
      } catch (e) {
        emit(LinkError('Failed to load links'));
      }
    });

    on<AddLink>((event, emit) async {
      try {
        await linkService.addLink(
          event.userId,
          event.projectId,
          event.link.roomName, // Passando o nome do cômodo
          event.link.linkUrl, // Passando o URL do link
        );
        // Depois de adicionar o link, recarregar os links
        add(LoadLinks(event.userId, event.projectId));
      } catch (e) {
        emit(LinkError('Falha ao adicionar link'));
      }
    });

    on<UpdateLink>((event, emit) async {
      try {
        await linkService.updateLink(event.userId, event.projectId, event.link);
      } catch (e) {
        emit(LinkError('Failed to update link'));
      }
    });

    on<DeleteLink>((event, emit) async {
      try {
        await linkService.deleteLink(
            event.userId, event.projectId, event.linkId);
      } catch (e) {
        emit(LinkError('Failed to delete link'));
      }
    });
  }
}
