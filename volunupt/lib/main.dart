import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/firebase_config.dart';
import 'core/router/app_router.dart';
import 'core/widgets/activity_detector.dart';
import 'core/widgets/session_listener.dart';
import 'core/theme/app_theme.dart';
// import 'core/widgets/offline_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: FirebaseConfig.currentPlatform,
  );

  // You can customize FlutterError.onError if you want to log errors,
  // but do not wrap the app in nested MaterialApps.
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return SessionListener(
      child: ActivityDetector(
        child: MaterialApp.router(
          title: 'Volun UPT',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
