import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/main_layout.dart';
import '../widgets/page_transition.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/events/presentation/screens/events_catalog_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/user_inscriptions_screen.dart';
import '../../features/events/presentation/screens/inscription_detail_screen.dart';
import '../../features/events/presentation/screens/qr_scanner_screen.dart';
import '../../features/events/presentation/screens/qr_generator_screen.dart';
import '../../features/events/domain/entities/event_entity.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/certificates/presentation/screens/certificates_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_events_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      return authState.when(
        data: (user) {
          final isAuthenticated = user != null;
          final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

          if (!isAuthenticated && !isLoggingIn) {
            return '/login';
          }

          if (isAuthenticated && isLoggingIn) {
            return '/home';
          }

          return null;
        },
        loading: () => null,
        error: (error, stackTrace) {
          final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
          if (!isLoggingIn) {
            return '/login';
          }
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(
          child: child,
          currentPath: state.matchedLocation,
        ),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const EventsCatalogScreen(),
            routes: [
              GoRoute(
                path: ':eventId',
                name: 'event-detail',
                builder: (context, state) {
                  final eventId = state.pathParameters['eventId']!;
                  return EventDetailScreen(eventId: eventId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/my-events',
            name: 'my-events',
            builder: (context, state) => const UserInscriptionsScreen(),
            routes: [
              GoRoute(
                path: ':inscriptionId',
                name: 'inscription-detail',
                builder: (context, state) {
                  final inscriptionId = state.pathParameters['inscriptionId']!;
                  return InscriptionDetailScreen(inscriptionId: inscriptionId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/certificates',
            name: 'certificates',
            builder: (context, state) => const CertificatesScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/events',
            name: 'admin-events',
            builder: (context, state) => const AdminEventsScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            name: 'admin-reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/scanner/:eventId',
        name: 'qr-scanner',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return QrScannerScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/qr-generator/:eventId',
        name: 'qr-generator',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final eventData = state.extra as Map<String, dynamic>?;
          
          if (eventData != null) {
            final event = EventEntity.fromMap(eventData);
            return QrGeneratorScreen(event: event);
          }
          
          return const Scaffold(
            body: Center(
              child: Text('Error: Datos del evento no encontrados'),
            ),
          );
        },
      ),
    ],
  );
});