import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunupt/domain/entities/user.dart';
import 'package:volunupt/domain/usecases/login_usecase.dart';
import 'package:volunupt/domain/usecases/register_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:volunupt/domain/entities/auth_credentials.dart';
import 'package:volunupt/domain/entities/register_credentials.dart';

//Eventos
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  // 🆕 Nuevo evento
  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;

  RegisterEvent({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, password, confirmPassword, fullName];
}

class LogoutEvent extends AuthEvent {}

//Estados
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegistered extends AuthState {
  // 🆕 Nuevo estado
  final User user;

  AuthRegistered(this.user);

  @override
  List<Object?> get props => [user];
}

//Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase; // Nueva dependencia

  AuthBloc(this.loginUseCase, this.registerUseCase) : super(AuthInitial()) {
    on<LoginEvent>(_onLoginEvent);
    on<RegisterEvent>(_onRegisterEvent); // Nuevo handler
    on<LogoutEvent>(_onLogoutEvent);
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    debugPrint('AuthBloc: Login iniciado para ${event.email}');
    emit(AuthLoading());
    try {
      final credentials = AuthCredentials(
        email: event.email,
        password: event.password,
      );
      debugPrint('AuthBloc: Llamando LoginUseCase');
      final user = await loginUseCase(credentials);
      debugPrint('AuthBloc: Login exitoso, usuario: ${user.email}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      debugPrint('AuthBloc: Error en login: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterEvent(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    // 🆕 Nuevo método
    emit(AuthLoading());
    try {
      final credentials = RegisterCredentials(
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
        fullName: event.fullName,
      );
      final user = await registerUseCase(credentials);
      emit(AuthRegistered(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutEvent(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('AuthBloc: Logout ejecutado');
    emit(AuthInitial());
  }
}
