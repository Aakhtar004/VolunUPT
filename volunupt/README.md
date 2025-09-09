# 📱 VolunUPT - Aplicación Flutter con Clean Architecture

## 🎯 **Introducción**

Esta aplicación Flutter utiliza **Clean Architecture** combinada con el patrón **BLoC** para crear un sistema de autenticación robusto y escalable. Te explico paso a paso cómo funciona todo el flujo desde que se inicia la aplicación hasta que el usuario se autentica.

---

## 📁 **Estructura del Proyecto**

```
lib/
├── main.dart                          # 🚀 Punto de entrada de la aplicación
├── application/                       # 🎮 Lógica de negocio y estados
│   └── blocs/
│       └── auth_bloc.dart
├── domain/                           # 🏛️ Reglas de negocio puras
│   ├── entities/                     # 📦 Modelos de datos
│   │   ├── user.dart
│   │   └── auth_credentials.dart
│   ├── repositories/                 # 📋 Contratos/Interfaces
│   │   └── auth_repository.dart
│   └── usecases/                     # 🎯 Casos de uso específicos
│       └── login_usecase.dart
├── infraestructure/                  # 🔧 Implementaciones técnicas
│   ├── datasources/                  # 🌐 Fuentes de datos externas
│   │   └── auth_datasource.dart
│   └── repositories/                 # 📝 Implementaciones de contratos
│       └── auth_repository_impl.dart
└── presentation/                     # 🎨 Interfaz de usuario
    ├── screens/                      # 📱 Pantallas
    │   └── login_screen.dart
    └── widgets/                      # 🧩 Componentes reutilizables
```

---

## 🚀 **Flujo Completo del Sistema (Paso a Paso)**

### **1. Inicio de la Aplicación - [`lib/main.dart`](lib/main.dart )**

```dart
void main() {
  runApp(MyApp()); // 🎬 AQUÍ EMPIEZA TODO
}
```

**¿Qué pasa aquí?**
- Flutter ejecuta la función `main()` al iniciar la app
- Se llama a `runApp()` con `MyApp()` como widget raíz
- Es como encender el motor de tu carro

### **2. Configuración del Widget Principal - `MyApp`**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 🏭 FÁBRICA: Creamos todas las dependencias
    final authRepository = AuthRepositoryImpl(AuthDatasource());
    final loginUseCase = LoginUseCase(authRepository: authRepository);

    return BlocProvider(
      create: (context) => AuthBloc(loginUseCase), // 🎮 Controlador de estado
      child: MaterialApp(
        home: const LoginScreen(), // 📱 Primera pantalla
      ),
    );
  }
}
```

**¿Qué está pasando?**
1. **Inyección de Dependencias**: Se crean todas las piezas necesarias
2. **BlocProvider**: Proporciona el `AuthBloc` a toda la aplicación
3. **MaterialApp**: Configura la aplicación con Material Design
4. **home**: Define `LoginScreen` como pantalla inicial

---

## 🔄 **Flujo de Autenticación Detallado**

### **Paso 1: Usuario Ve la Pantalla de Login**

**Archivo**: [`lib/presentation/screens/login_screen.dart`](lib/presentation/screens/login_screen.dart )

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    return BlocConsumer<AuthBloc, AuthState>( // 🎧 Escucha cambios de estado
      listener: (context, state) {
        // 👂 REACCIONA a cambios de estado
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(/*...*/);
        }
      },
      builder: (context, state) {
        // 🎨 CONSTRUYE la interfaz según el estado
        return /* Formulario de login */;
      },
    );
  }
}
```

**¿Qué hace esta pantalla?**
- **Captura datos**: Email y contraseña del usuario
- **Escucha estados**: Reacciona cuando cambia el estado de autenticación
- **Navega**: Cambia de pantalla según el resultado

### **Paso 2: Usuario Presiona "Login"**

```dart
ElevatedButton(
  onPressed: () {
    BlocProvider.of<AuthBloc>(context).add( // 📨 ENVÍA EVENTO
      LoginEvent(
        email: emailController.text,
        password: passwordController.text,
      ),
    );
  },
  child: Text('Login'),
)
```

**¿Qué sucede?**
1. Se capturan los datos del formulario
2. Se crea un `LoginEvent` con email y password
3. Se envía el evento al `AuthBloc`

### **Paso 3: AuthBloc Procesa el Evento**

**Archivo**: `application/blocs/auth_bloc.dart`

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc(this.loginUseCase) : super(AuthInitial()) {
    on<LoginEvent>(_onLoginEvent); // 🎯 Maneja eventos de login
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading()); // 🔄 Estado: "Cargando..."
    
    try {
      final credentials = AuthCredentials(
        email: event.email,
        password: event.password,
      );
      
      final user = await loginUseCase(credentials); // 🎯 Ejecuta caso de uso
      emit(AuthAuthenticated(user)); // ✅ Estado: "Autenticado"
    } catch (e) {
      emit(AuthError(e.toString())); // ❌ Estado: "Error"
    }
  }
}
```

**¿Qué hace el BLoC?**
1. **Recibe el evento**: `LoginEvent`
2. **Cambia estado**: A "cargando"
3. **Ejecuta lógica**: Llama al caso de uso
4. **Emite resultado**: Éxito o error

### **Paso 4: Caso de Uso Ejecuta la Lógica**

**Archivo**: [`lib/domain/usecases/login_usecase.dart`](lib/domain/usecases/login_usecase.dart )

```dart
class LoginUseCase {
  final AuthRepository authRepository;

  LoginUseCase({required this.authRepository});

  Future<User> call(AuthCredentials credentials) async {
    return await authRepository.login(credentials); // 🎯 Delega al repositorio
  }
}
```

**¿Por qué existe este archivo?**
- **Encapsula lógica**: Define exactamente qué hacer para hacer login
- **Reutilizable**: Puede ser usado desde cualquier parte
- **Testeable**: Fácil de probar unitariamente

### **Paso 5: Repositorio Coordina las Operaciones**

**Archivo**: `infraestructure/repositories/auth_repository_impl.dart`

```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource datasource;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<User> login(AuthCredentials credentials) async {
    final user = await datasource.login(credentials); // 🌐 Obtiene datos
    await storage.write(key: 'token', value: user.token); // 💾 Guarda token
    return user;
  }
}
```

**¿Qué hace el repositorio?**
1. **Obtiene datos**: Del API a través del datasource
2. **Procesa**: Guarda el token de forma segura
3. **Retorna**: El usuario autenticado

### **Paso 6: Datasource Se Conecta al API**

**Archivo**: [`lib/infraestructure/datasources/auth_datasource.dart`](lib/infraestructure/datasources/auth_datasource.dart )

```dart
class AuthDatasource {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://tu-api.com'));

  Future<User> login(AuthCredentials credentials) async {
    final response = await dio.post('/login', data: {
      'email': credentials.email,
      'password': credentials.password
    });

    return User(
      id: response.data['id'],
      email: response.data['email'],
      token: response.data['token'],
    );
  }
}
```

**¿Qué hace el datasource?**
- **Conecta con API**: Hace la petición HTTP
- **Transforma datos**: Convierte JSON en objetos Dart
- **Maneja errores**: Lanza excepciones si algo falla

---

## 📊 **Flujo de Datos Completo**

```
👤 Usuario presiona Login
    ↓
📱 LoginScreen
    ↓
📨 Envía LoginEvent
    ↓
🎮 AuthBloc recibe evento
    ↓
🎯 LoginUseCase ejecuta
    ↓
📝 AuthRepository coordina
    ↓
🌐 AuthDatasource conecta API
    ↓
📥 API responde
    ↓
👤 User creado
    ↓
💾 Token guardado
    ↓
✅ AuthAuthenticated emitido
    ↓
📱 LoginScreen navega a Home
```

---

## 🏗️ **¿Por Qué Esta Arquitectura es Sostenible?**

### **1. 🎯 Separación de Responsabilidades**

Cada capa tiene una función específica:

- **Domain** 🏛️: Reglas de negocio puras (no depende de Flutter)
- **Application** 🎮: Manejo de estado y coordinación
- **Infrastructure** 🔧: Implementaciones técnicas (API, Base de datos)
- **Presentation** 🎨: Interfaz de usuario

### **2. 🔄 Inversión de Dependencias**

```dart
// ✅ CORRECTO: Domain NO depende de Infrastructure
class LoginUseCase {
  final AuthRepository authRepository; // 📋 Interfaz, no implementación
}

// ❌ INCORRECTO sería:
// final AuthDatasource datasource; // 🔧 Implementación específica
```

### **3. 🧪 Fácil Testing**

```dart
// Puedes hacer mock de cualquier dependencia
test('should authenticate user successfully', () {
  final mockRepository = MockAuthRepository();
  final useCase = LoginUseCase(authRepository: mockRepository);
  // ... resto del test
});
```

### **4. 🔧 Fácil Mantenimiento**

**¿Quieres cambiar de API a Firebase?**
```dart
// Solo cambias el datasource
final authRepository = AuthRepositoryImpl(FirebaseAuthDatasource());
// ¡El resto del código NO cambia!
```

**¿Quieres agregar caché?**
```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource datasource;
  final CacheService cache; // ➕ Nueva dependencia
  
  Future<User> login(AuthCredentials credentials) async {
    // Verifica caché primero
    final cachedUser = await cache.getUser();
    if (cachedUser != null) return cachedUser;
    
    // Si no hay caché, usa datasource
    final user = await datasource.login(credentials);
    await cache.saveUser(user);
    return user;
  }
}
```

---

## 📚 **Explicación de Cada Carpeta (Para Novatos)**

### **🏛️ `domain/` - El Cerebro del Sistema**

**¿Qué es?**
Es donde viven las reglas de negocio de tu aplicación. Es como las leyes de un país - no cambian frecuentemente y son independientes de la tecnología.

**¿Qué contiene?**

- **`entities/`**: Los "objetos" principales de tu app
  ```dart
  class User {
    final String id;
    final String email;
    // Representa QUÉ es un usuario
  }
  ```

- **`repositories/`**: "Contratos" que dicen qué operaciones necesitas
  ```dart
  abstract class AuthRepository {
    Future<User> login(AuthCredentials credentials);
    // Define QUÉ operaciones necesitas, no CÓMO las haces
  }
  ```

- **`usecases/`**: Acciones específicas que puede hacer el usuario
  ```dart
  class LoginUseCase {
    // Define EXACTAMENTE qué pasos seguir para hacer login
  }
  ```

### **🎮 `application/` - El Director de Orquesta**

**¿Qué es?**
Coordina todo lo que pasa en tu app. Es como el director de una orquesta - no toca instrumentos, pero coordina a todos.

**¿Qué contiene?**
- **`blocs/`**: Manejan el estado de la aplicación
  ```dart
  // AuthBloc escucha eventos (como "hacer login")
  // y emite estados (como "cargando", "autenticado", "error")
  ```

### **🔧 `infrastructure/` - Los Trabajadores**

**¿Qué es?**
Son las implementaciones técnicas reales. Es como los empleados que hacen el trabajo sucio.

**¿Qué contiene?**

- **`datasources/`**: Se conectan a servicios externos
  ```dart
  class AuthDatasource {
    // Se conecta al API REST, Firebase, etc.
  }
  ```

- **`repositories/`**: Implementan los contratos del domain
  ```dart
  class AuthRepositoryImpl implements AuthRepository {
    // CÓMO hacer login realmente
  }
  ```

### **🎨 `presentation/` - La Cara Bonita**

**¿Qué es?**
Todo lo que ve el usuario. Es como la fachada de un edificio.

**¿Qué contiene?**
- **`screens/`**: Pantallas completas
- **`widgets/`**: Componentes reutilizables

---

## 🚀 **Ventajas a Largo Plazo**

### **🔄 Escalabilidad**
```dart
// Agregar nueva funcionalidad es fácil:
// 1. Nueva entidad en domain/entities/
// 2. Nuevo caso de uso en domain/usecases/
// 3. Nuevo bloc en application/blocs/
// 4. Nueva pantalla en presentation/screens/
```

### **🧪 Testabilidad**
```dart
// Cada parte se puede testear independientemente
test('LoginUseCase should return user when credentials are valid', () {
  // Arrange
  final mockRepo = MockAuthRepository();
  final useCase = LoginUseCase(authRepository: mockRepo);
  
  // Act & Assert
  // ...
});
```

### **🔧 Mantenibilidad**
- **Cambios localizados**: Un cambio en el API solo afecta al datasource
- **Código reutilizable**: Los casos de uso se pueden usar en múltiples pantallas
- **Fácil debugging**: Cada capa tiene responsabilidades claras

### **👥 Trabajo en Equipo**
- **Frontend dev**: Trabaja en `presentation/`
- **Backend dev**: Define contratos en `domain/repositories/`
- **Mobile dev**: Implementa `infrastructure/`

---

## 🎓 **Consejos para Aprender**

1. **Empieza por `domain/`**: Define tus entidades y casos de uso
2. **Luego `application/`**: Crea los blocs para manejar estado
3. **Después `infrastructure/`**: Implementa las conexiones reales
4. **Finalmente `presentation/`**: Crea las pantallas bonitas

**¡Recuerda!** 🧠
- **Domain** = ¿QUÉ hace tu app?
- **Application** = ¿CUÁNDO sucede cada cosa?
- **Infrastructure** = ¿CÓMO se hace técnicamente?
- **Presentation** = ¿CÓMO lo ve el usuario?

---

Esta arquitectura te permite construir aplicaciones que pueden crecer desde 10 usuarios hasta 10 millones sin reescribir todo el código. ¡Es como construir con bloques LEGO - cada pieza tiene su lugar y propósito! 🧩
