import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Convierte errores técnicos de Firebase/Plataforma en mensajes claros en español.
class FriendlyError {
  static String message(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return 'Problemas de conexión. Verifica tu internet e inténtalo de nuevo.';
        case 'user-disabled':
          return 'Tu cuenta está deshabilitada. Contacta al administrador.';
        case 'user-not-found':
        case 'invalid-credential':
          return 'No pudimos validar tus credenciales. Vuelve a iniciar sesión.';
        case 'operation-not-allowed':
          return 'Inicio de sesión no disponible por el momento. Intenta más tarde.';
        case 'popup-closed-by-user':
          return 'El inicio de sesión se canceló. Vuelve a intentarlo.';
        default:
          return 'Ocurrió un error al autenticar. Intenta nuevamente.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permisos para acceder a esta información.';
        case 'not-found':
          return 'No encontramos la información solicitada.';
        case 'failed-precondition':
          return 'La base de datos requiere un índice o condición previa. Intenta más tarde.';
        case 'aborted':
        case 'cancelled':
          return 'La operación fue cancelada. Inténtalo otra vez.';
        case 'unavailable':
          return 'El servicio está temporalmente no disponible. Reintenta en unos minutos.';
        case 'deadline-exceeded':
          return 'La solicitud tardó demasiado. Verifica tu conexión e intenta nuevamente.';
        default:
          return 'No pudimos cargar los datos. Intenta de nuevo.';
      }
    }

    if (error is PlatformException) {
      switch (error.code) {
        case 'ERROR_NETWORK_REQUEST_FAILED':
          return 'Problemas de conexión. Verifica tu internet e inténtalo de nuevo.';
        default:
          return 'Ocurrió un error inesperado. Intenta nuevamente.';
      }
    }

    return 'Algo no salió como esperábamos. Inténtalo otra vez.';
  }
}