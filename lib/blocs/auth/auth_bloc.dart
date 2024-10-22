import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signInWithEmailAndPassword(
          event.email, event.password);
      if (user != null) {
        // Verifica se o e-mail foi verificado
        bool isVerified = await _authService.isEmailVerified(user);
        if (!isVerified) {
          await _authService
              .signOut(); // Desloga o usuário se o e-mail não foi verificado
          emit(AuthFailure(
              "Por favor, verifique seu e-mail antes de fazer login."));
        } else {
          emit(AuthSuccess(user));
        }
      } else {
        emit(AuthFailure("Email ou senha incorretos"));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _authService.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure("Erro ao fazer logout"));
    }
  }

  Future<void> _onSignUpRequested(
      AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signUpWithEmailAndPassword(
          event.email, event.password, event.name);
      if (user != null) {
        emit(AuthSignUpSuccess(user));
      } else {
        emit(AuthFailure("Erro ao criar conta"));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
