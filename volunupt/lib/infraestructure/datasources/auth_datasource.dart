import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:volunupt/domain/entities/auth_credentials.dart';
import 'package:volunupt/domain/entities/register_credentials.dart';
import 'package:volunupt/domain/entities/user.dart';

class AuthDatasource {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  Future<User> login(AuthCredentials credentials) async {
    try {
      debugPrint('INICIO LOGIN');
      debugPrint('Email: ${credentials.email}');
      debugPrint('URL completa: ${dio.options.baseUrl}/login');

      final response = await dio.post(
        '/login',
        data: {'email': credentials.email, 'password': credentials.password},
      );

      debugPrint('Respuesta recibida');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      // Agregar logs para debugging de tipos
      debugPrint('Verificando tipos de datos recibidos');
      debugPrint('Tipo de id: ${response.data['id'].runtimeType}');
      debugPrint('Valor de id: ${response.data['id']}');
      debugPrint('Tipo de email: ${response.data['email'].runtimeType}');
      debugPrint('Valor de email: ${response.data['email']}');
      debugPrint('Tipo de token: ${response.data['token'].runtimeType}');
      debugPrint('Valor de token: ${response.data['token']}');

      // Manejo seguro de tipos
      debugPrint('Iniciando conversion a String');
      final id = response.data['id']?.toString() ?? '';
      debugPrint('ID convertido: $id');

      final email = response.data['email']?.toString() ?? '';
      debugPrint('Email convertido: $email');

      final token = response.data['token']?.toString() ?? '';
      debugPrint('Token convertido: $token');

      debugPrint('Creando objeto User');
      final user = User(id: id, email: email, token: token);
      debugPrint('User creado exitosamente');

      return user;
    } on DioException catch (e) {
      debugPrint('ERROR DIO LOGIN');
      debugPrint('Tipo de error: ${e.type}');
      debugPrint('Mensaje: ${e.message}');
      debugPrint('URL intentada: ${e.requestOptions.uri}');

      if (e.response != null) {
        debugPrint('Response Status: ${e.response?.statusCode}');
        debugPrint('Response Data: ${e.response?.data}');
      }

      throw Exception('Error de conexion en login');
    } catch (e) {
      debugPrint('ERROR GENERAL LOGIN');
      debugPrint('Error completo: $e');
      debugPrint('StackTrace: ${StackTrace.current}');
      throw Exception('Error inesperado en login');
    }
  }

  Future<User> register(RegisterCredentials credentials) async {
    try {
      debugPrint('INICIO REGISTRO');
      debugPrint('Email: ${credentials.email}');
      debugPrint('Nombre: ${credentials.fullName}');
      debugPrint('URL completa: ${dio.options.baseUrl}/register');

      final response = await dio.post(
        '/register',
        data: {
          'email': credentials.email,
          'password': credentials.password,
          'fullName': credentials.fullName,
        },
      );

      debugPrint('Respuesta recibida');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      throw Exception(
        'Backend no retorna datos de usuario. Respuesta: ${response.data}',
      );
    } on DioException catch (e) {
      debugPrint('ERROR DIO REGISTRO');
      debugPrint('Tipo de error: ${e.type}');
      debugPrint('Mensaje: ${e.message}');
      debugPrint('URL intentada: ${e.requestOptions.uri}');

      if (e.response != null) {
        debugPrint('Response Status: ${e.response?.statusCode}');
        debugPrint('Response Data: ${e.response?.data}');
      }

      throw Exception('Error de conexion en registro');
    } catch (e) {
      debugPrint('ERROR GENERAL REGISTRO');
      debugPrint('Error: $e');
      throw Exception('Error inesperado en registro');
    }
  }
}
