import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// Evento para buscar os dados do perfil
class FetchProfileData extends ProfileEvent {
  final String userId; // Atualizamos para utilizar o userId diretamente

  FetchProfileData(this.userId);

  @override
  List<Object> get props => [userId];
}

// Evento para salvar os dados do perfil
class SaveProfileData extends ProfileEvent {
  final Map<String, dynamic> profileData;
  final String userId; // Atualizamos para utilizar o userId diretamente

  SaveProfileData(this.profileData, this.userId);

  @override
  List<Object> get props => [profileData, userId];
}

// Evento para fazer o upload da imagem de perfil
class UploadProfileImage extends ProfileEvent {
  final File imageFile;
  final String userId; // Atualizamos para utilizar o userId diretamente

  UploadProfileImage(this.imageFile, this.userId);

  @override
  List<Object> get props => [imageFile, userId];
}

// Evento para limpar os dados do perfil
class ClearProfileData extends ProfileEvent {}
