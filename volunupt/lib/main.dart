import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunupt/application/blocs/auth_bloc.dart';
import 'package:volunupt/domain/usecases/login_usecase.dart';
import 'package:volunupt/domain/usecases/register_usecase.dart';
import 'package:volunupt/domain/usecases/logout_usecase.dart';
import 'package:volunupt/domain/usecases/check_auth_status_usecase.dart';
import 'package:volunupt/infraestructure/repositories/auth_repository_impl_local.dart';
import 'package:volunupt/infraestructure/datasources/auth_datasource_local.dart';

import 'package:volunupt/presentation/screens/shared/prelogin_screen.dart';
import 'package:volunupt/presentation/screens/shared/login_screen.dart';
import 'package:volunupt/presentation/screens/shared/register_screen.dart';
import 'package:volunupt/presentation/screens/shared/detalle_campaign_screen.dart';
import 'package:volunupt/presentation/screens/shared/home_screen.dart';

import 'package:volunupt/presentation/screens/estudiante/catalog_screen.dart';
import 'package:volunupt/presentation/screens/estudiante/inscripciones_screen.dart';
import 'package:volunupt/presentation/screens/estudiante/qr_attendance_screen.dart';
import 'package:volunupt/presentation/screens/coordinador/attendance_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyección de dependencias con datasource local
    final authRepository = AuthRepositoryImplLocal(AuthDatasourceLocal());
    final loginUseCase = LoginUseCase(authRepository: authRepository);
    final registerUseCase = RegisterUseCase(authRepository: authRepository);
    final logoutUseCase = LogoutUseCase(authRepository: authRepository);
    final checkAuthStatusUseCase = CheckAuthStatusUseCase(
      authRepository: authRepository,
    );

    return BlocProvider(
      create: (context) => AuthBloc(
        loginUseCase,
        registerUseCase,
        logoutUseCase,
        checkAuthStatusUseCase,
      ),
      child: MaterialApp(
        title: 'VolunUPT',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const PreLoginScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          //DIVIDIDO ENTRE ESTUDIANTES   Y COORDINADOR
          '/home': (context) => const HomeScreen(),
          '/catalog': (context) => const CatalogScreen(),
          '/inscripciones': (context) => const InscripcionesScreen(),
          '/detalle': (context) => const DetalleCampaignScreen(),
          '/qr_attendance': (context) => const QRAttendanceScreen(),
          '/attendance_list': (context) => const AttendanceListScreen(),
        },
      ),
    );
  }
}
