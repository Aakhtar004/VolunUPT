import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunupt/domain/entities/user.dart';
import 'package:volunupt/domain/usecases/login_usecase.dart';
import 'package:volunupt/domain/usecases/register_usecase.dart';
import 'package:volunupt/domain/usecases/logout_usecase.dart';
import 'package:volunupt/domain/usecases/check_auth_status_usecase.dart';
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
  final String role;

  RegisterEvent({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, confirmPassword, fullName, role];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

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

class AuthUnauthenticated extends AuthState {}

class AuthLoggedInWithRole extends AuthState {
  final String role;

  AuthLoggedInWithRole(this.role);

  @override
  List<Object?> get props => [role];
}

//Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthBloc(
    this.loginUseCase,
    this.registerUseCase,
    this.logoutUseCase,
    this.checkAuthStatusUseCase,
  ) : super(AuthInitial()) {
    on<LoginEvent>(_onLoginEvent);
    on<RegisterEvent>(_onRegisterEvent);
    on<LogoutEvent>(_onLogoutEvent);
    on<CheckAuthStatusEvent>(_onCheckAuthStatusEvent);
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
        role: event.role,
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
    try {
      await logoutUseCase();
      emit(AuthUnauthenticated());
    } catch (e) {
      debugPrint('AuthBloc: Error en logout: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuthStatusEvent(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('AuthBloc: Verificando estado de autenticación');
    try {
      final role = await checkAuthStatusUseCase();
      if (role != null) {
        debugPrint('AuthBloc: Usuario autenticado con rol: $role');
        emit(AuthLoggedInWithRole(role));
      } else {
        debugPrint('AuthBloc: Usuario no autenticado');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('AuthBloc: Error verificando estado: $e');
      emit(AuthUnauthenticated());
    }
  }
}
