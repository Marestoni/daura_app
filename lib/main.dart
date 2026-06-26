import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/app_colors.dart';

void main() => runApp(const MyApp());

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
      initialRoute: '/', // Rota inicial
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(userName: 'Usuário'),
      },
      // Para receber argumentos na Dashboard
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
