import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'controllers/login_controller.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'utils/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Desktop (Windows/Linux/macOS): o sqflite padrão só roda em mobile;
  // no desktop o cache local usa o SQLite via FFI. Guardado para não afetar
  // o build Android/iOS.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ✅ Inicializar o SyncService ANTES de tudo
  final syncService = SyncService();
  syncService.startMonitoring();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        Provider<SyncService>.value(value: syncService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão Daura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(userName: 'Usuário'),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final userName = settings.arguments as String? ?? 'Usuário';
          return MaterialPageRoute(
            builder: (context) => DashboardScreen(userName: userName),
          );
        }
        return null;
      },
    );
  }
}
