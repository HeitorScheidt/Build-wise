import 'package:build_wise/models/link_model.dart';

abstract class LinkState {}

class LinkLoading extends LinkState {}

class LinkLoaded extends LinkState {
  final List<LinkModel> links;

  LinkLoaded(this.links);
}

class LinkError extends LinkState {
  final String error;

  LinkError(this.error);
}
