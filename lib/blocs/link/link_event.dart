import 'package:build_wise/models/link_model.dart';

abstract class LinkEvent {}

class LoadLinks extends LinkEvent {
  final String userId;
  final String projectId;

  LoadLinks(this.userId, this.projectId);
}

class AddLink extends LinkEvent {
  final String userId;
  final String projectId;
  final LinkModel link;

  AddLink(this.userId, this.projectId, this.link);
}

class UpdateLink extends LinkEvent {
  final String userId;
  final String projectId;
  final LinkModel link;

  UpdateLink(this.userId, this.projectId, this.link);
}

class DeleteLink extends LinkEvent {
  final String userId;
  final String projectId;
  final String linkId;

  DeleteLink(this.userId, this.projectId, this.linkId);
}
