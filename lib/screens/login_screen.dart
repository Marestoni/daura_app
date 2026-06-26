import 'package:flutter/material.dart';
import '../controllers/login_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = LoginController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.business_center,
            size: 44,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Gestão Daura',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faça login para continuar',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        CustomTextField(
          label: 'E-mail',
          hint: 'Digite seu e-mail',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Senha',
          hint: 'Digite sua senha',
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          validator: Validators.validatePassword,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Text(
              _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_controller.error != null) _buildError(),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Entrar',
          onPressed: _login,
          isLoading: _controller.isLoading,
        ),
        const SizedBox(height: 20),
        Text(
          'Desenvolvido com ❤️ para Gestão Daura',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _controller.error!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // ✅ VAI DIRETO PARA DASHBOARD SEM DIALOG
      _goToDashboard();
    }
  }

  // ✅ MÉTODO QUE REDIRECIONA DIRETO
  void _goToDashboard() {
    print('🟢 _goToDashboard() chamado!');
    print('🟢 _controller.user: ${_controller.user}');
    print('🟢 _controller.user?.name: ${_controller.user?.name}');

    final userName = _controller.user?.name ?? 'Usuário';
    print('🟢 Redirecionando com nome: $userName');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(userName: userName),
      ),
      (route) => false,
    );
  }
}
