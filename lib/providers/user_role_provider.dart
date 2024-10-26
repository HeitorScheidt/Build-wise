// /lib/providers/user_role_provider.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UserRoleProvider extends ChangeNotifier {
  String? _role;
  String? _architectId;
  List<String>?
      _projectIds; // Lista para armazenar os IDs dos projetos do cliente
  final UserService _userService = UserService();

  String? get role => _role;
  String? get architectId => _architectId;
  List<String>? get projectIds => _projectIds; // Getter para projectIds

  Future<void> fetchUserRole() async {
    _role = await _userService.getUserRole();
    if (_role == 'cliente') {
      _architectId = await _userService.getArchitectIdForClient();
      _projectIds = await _userService
          .getProjectIdsForClient(); // Carrega os projectIds do cliente
    }
    notifyListeners();
  }
}
