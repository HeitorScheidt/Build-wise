import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/profile/profile_event.dart';
import 'package:build_wise/blocs/profile/profile_state.dart';
import 'package:build_wise/services/profile_service.dart';
import 'dart:io';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService profileService;

  ProfileBloc(this.profileService) : super(ProfileInitial()) {
    on<FetchProfileData>(_onFetchProfileData);
    on<SaveProfileData>(_onSaveProfileData);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<ClearProfileData>(_onClearProfileData); // Evento para limpar o perfil
  }

  // Método para buscar os dados do perfil
  Future<void> _onFetchProfileData(
      FetchProfileData event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      print(
          "Iniciando busca de dados de perfil para o ID do usuário: ${event.userId}");

      // Removido: Limpeza de cache de `role`, agora mantemos apenas o carregamento de dados de perfil
      final data = await profileService.fetchProfileData();

      if (data != null) {
        print("Dados de perfil carregados com sucesso: $data");
        emit(ProfileLoaded(data));
      } else {
        print("Erro: Nenhum dado de perfil encontrado.");
        emit(ProfileError("Erro ao carregar os dados do perfil."));
      }
    } catch (e) {
      print("Erro ao carregar os dados do perfil: $e");
      emit(ProfileError("Erro ao carregar os dados do perfil: $e"));
    }
  }

  // Método para salvar os dados do perfil
// ProfileBloc
  Future<void> _onSaveProfileData(
      SaveProfileData event, Emitter<ProfileState> emit) async {
    emit(ProfileSaving());
    try {
      print("Salvando dados de perfil para o ID do usuário: ${event.userId}");
      await profileService.saveProfileData(event.profileData);
      print("Dados de perfil salvos com sucesso.");
      emit(ProfileSaved());

      // Recarrega os dados para refletir as mudanças
      add(FetchProfileData(event.userId));
    } catch (e) {
      print("Erro ao salvar os dados do perfil: $e");
      emit(ProfileError("Erro ao salvar os dados do perfil: $e"));
    }
  }

  // Método para fazer o upload da imagem de perfil
  Future<void> _onUploadProfileImage(
      UploadProfileImage event, Emitter<ProfileState> emit) async {
    emit(ProfileImageUploading());
    try {
      print(
          "Fazendo upload da imagem de perfil para o ID do usuário: ${event.userId}");
      await profileService.uploadProfileImage(event.imageFile);
      print("Upload da imagem de perfil realizado com sucesso.");
      emit(ProfileImageUploaded());
    } catch (e) {
      print("Erro ao fazer upload da imagem de perfil: $e");
      emit(ProfileError("Erro ao fazer upload da imagem: $e"));
    }
  }

  // Método para limpar os dados do perfil quando o usuário fizer logout
// ProfileBloc.dart
  Future<void> _onClearProfileData(
      ClearProfileData event, Emitter<ProfileState> emit) async {
    try {
      print("Limpando cache de dados do perfil.");
      await profileService.clearProfileCache();
      emit(ProfileInitial());
      await Future.delayed(
          Duration(milliseconds: 100)); // Pausa para atualização
      print("Cache de perfil limpo com sucesso.");
    } catch (e) {
      print("Erro ao limpar o cache de perfil: $e");
      emit(ProfileError("Erro ao limpar o cache de perfil: $e"));
    }
  }
}
