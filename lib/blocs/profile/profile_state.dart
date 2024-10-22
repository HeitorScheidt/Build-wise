import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic>? profileData;

  ProfileLoaded(this.profileData);

  @override
  List<Object> get props =>
      [profileData ?? {}]; // Garante que o profileData nunca seja nulo
}

class ProfileSaving extends ProfileState {}

class ProfileSaved extends ProfileState {}

class ProfileImageUploading extends ProfileState {}

class ProfileImageUploaded extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);

  @override
  List<Object> get props => [message];
}
